#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/config'
require 'chef/log'
require 'chef/resource/file'
require 'chef/mixin/checksum'
require 'chef/provider'
require 'etc'
require 'fileutils'
require 'chef/scan_access_control'
require 'chef/mixin/shell_out'

class Chef

  class Provider
    class File < Chef::Provider
      include Chef::Mixin::EnforceOwnershipAndPermissions
      include Chef::Mixin::Checksum
      include Chef::Mixin::ShellOut

      def negative_complement(big)
        if big > 1073741823 # Fixnum max
          big -= (2**32) # diminished radix wrap to negative
        end
        big
      end

      def octal_mode(mode)
        ((mode.respond_to?(:oct) ? mode.oct : mode.to_i) & 007777)
      end

      private :negative_complement, :octal_mode

      def diff_current_from_content(new_content)
        result = nil
        Tempfile.open("chef-diff") do |file| 
          file.write new_content
          file.close 
          result = diff_current file.path
        end
        result
      end

      def is_binary?(path)
        ::File.open(path) do |file|

          buff = file.read(Chef::Config[:diff_filesize_threshold])
          buff = "" if buff.nil?
          return buff !~ /^[\r[:print:]]*$/
        end
      end


      def diff_current(temp_path)
        suppress_resource_reporting = false

        return [ "(diff output suppressed by config)" ] if Chef::Config[:diff_disabled]
        return [ "(no temp file with new content, diff output suppressed)" ] unless ::File.exists?(temp_path)  # should never happen?

        # solaris does not support diff -N, so create tempfile to diff against if we are creating a new file
        target_path = if ::File.exists?(@current_resource.path)
                        @current_resource.path
                      else
                        suppress_resource_reporting = true  # suppress big diffs going to resource reporting service
                        tempfile = Tempfile.new('chef-tempfile')
                        tempfile.path
                      end

        diff_filesize_threshold = Chef::Config[:diff_filesize_threshold]
        diff_output_threshold = Chef::Config[:diff_output_threshold]

        if ::File.size(target_path) > diff_filesize_threshold || ::File.size(temp_path) > diff_filesize_threshold
          return [ "(file sizes exceed #{diff_filesize_threshold} bytes, diff output suppressed)" ]
        end

        # MacOSX(BSD?) diff will *sometimes* happily spit out nasty binary diffs
        return [ "(current file is binary, diff output suppressed)"] if is_binary?(target_path)
        return [ "(new content is binary, diff output suppressed)"] if is_binary?(temp_path)

        begin
          # -u: Unified diff format
          result = shell_out("diff -u #{target_path} #{temp_path}" )
        rescue Exception => e
          # Should *not* receive this, but in some circumstances it seems that 
          # an exception can be thrown even using shell_out instead of shell_out!
          return [ "Could not determine diff. Error: #{e.message}" ]
        end

        # diff will set a non-zero return code even when there's 
        # valid stdout results, if it encounters something unexpected
        # So as long as we have output, we'll show it.
        if not result.stdout.empty?
          if result.stdout.length > diff_output_threshold
            [ "(long diff of over #{diff_output_threshold} characters, diff output suppressed)" ]
          else
            val = result.stdout.split("\n")
            val.delete("\\ No newline at end of file")
            @new_resource.diff(val.join("\\n")) unless suppress_resource_reporting
            val
          end
        elsif not result.stderr.empty?
          [ "Could not determine diff. Error: #{result.stderr}" ]
        else
          [ "(no diff)" ]
        end
      end 

      def whyrun_supported?
        true
      end

      def load_current_resource
        # Every child should be specifying their own constructor, so this
        # should only be run in the file case.
        @current_resource ||= Chef::Resource::File.new(@new_resource.name)
        @new_resource.path.gsub!(/\\/, "/") # for Windows
        @current_resource.path(@new_resource.path)
        if !::File.directory?(@new_resource.path)
          if ::File.exist?(@new_resource.path)
            if @action != :create_if_missing  
              @current_resource.checksum(checksum(@new_resource.path))
            end
          end
        end
        load_current_resource_attrs
        setup_acl
        
        @current_resource
      end

      def load_current_resource_attrs
        if Chef::Platform.windows?
          # TODO: To work around CHEF-3554, add support for Windows
          # equivalent, or implicit resource reporting won't work for
          # Windows.
          return
        end

        if ::File.exist?(@new_resource.path)
          stat = ::File.stat(@new_resource.path)
          @current_resource.owner(stat.uid)
          @current_resource.mode(stat.mode & 07777)
          @current_resource.group(stat.gid)

          if @new_resource.group.nil?
            @new_resource.group(@current_resource.group)
          end 
          if @new_resource.owner.nil?
            @new_resource.owner(@current_resource.owner)
          end
          if @new_resource.mode.nil?
            @new_resource.mode(@current_resource.mode)
          end
        end
      end
      
      def setup_acl
        @acl_scanner = ScanAccessControl.new(@new_resource, @current_resource)
        @acl_scanner.set_all!
      end

      def define_resource_requirements
        # this must be evaluated before whyrun messages are printed
        access_controls.requires_changes?

        requirements.assert(:create, :create_if_missing, :touch) do |a|
          # Make sure the parent dir exists, or else fail.
          # for why run, print a message explaining the potential error.
          parent_directory = ::File.dirname(@new_resource.path)

          a.assertion { ::File.directory?(parent_directory) }
          a.failure_message(Chef::Exceptions::EnclosingDirectoryDoesNotExist, "Parent directory #{parent_directory} does not exist.")
          a.whyrun("Assuming directory #{parent_directory} would have been created")
        end

        # Make sure the file is deletable if it exists. Otherwise, fail.
        requirements.assert(:delete) do |a|
          a.assertion do
            if ::File.exists?(@new_resource.path) 
              ::File.writable?(@new_resource.path)
            else
              true
            end
          end
          a.failure_message(Chef::Exceptions::InsufficientPermissions,"File #{@new_resource.path} exists but is not writable so it cannot be deleted")
        end
      end

      # Compare the content of a file.  Returns true if they are the same, false if they are not.
      def compare_content
        checksum(@current_resource.path) == new_resource_content_checksum
      end

      # Set the content of the file, assuming it is not set correctly already.
      def set_content
        unless compare_content
          description = []
          description << "update content in file #{@new_resource.path} from #{short_cksum(@current_resource.checksum)} to #{short_cksum(new_resource_content_checksum)}"
          description << diff_current_from_content(@new_resource.content) 
          converge_by(description) do
            backup @new_resource.path if ::File.exists?(@new_resource.path)
            ::File.open(@new_resource.path, "w") {|f| f.write @new_resource.content }
            Chef::Log.info("#{@new_resource} contents updated")
          end
        end
      end

      # if you are using a tempfile before creating, you must
      # override the default with the tempfile, since the 
      # file at @new_resource.path will not be updated on converge
      def update_new_file_state(path=@new_resource.path)
        if !::File.directory?(path) 
          @new_resource.checksum(checksum(path))
        end

        if Chef::Platform.windows?
          # TODO: To work around CHEF-3554, add support for Windows
          # equivalent, or implicit resource reporting won't work for
          # Windows.
          return
        end

        stat = ::File.stat(path)
        @new_resource.owner(stat.uid)
        @new_resource.mode(stat.mode & 07777)
        @new_resource.group(stat.gid)
      end

      def action_create
        if !::File.exists?(@new_resource.path)
          description = []
          desc = "create new file #{@new_resource.path}"
          desc << " with content checksum #{short_cksum(new_resource_content_checksum)}" if new_resource.content
          description << desc
          description << diff_current_from_content(@new_resource.content) 
          
          converge_by(description) do
            Chef::Log.info("entered create")
            ::File.open(@new_resource.path, "w+") {|f| f.write @new_resource.content }
            access_controls.set_all
            Chef::Log.info("#{@new_resource} created file #{@new_resource.path}")
            update_new_file_state
          end
        else
          set_content unless @new_resource.content.nil?
          set_all_access_controls
        end
      end

      def set_all_access_controls
        if access_controls.requires_changes?
          converge_by(access_controls.describe_changes) do 
            access_controls.set_all
            #Update file state with new access values
            update_new_file_state
          end
        end
      end

      def action_create_if_missing
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug("#{@new_resource} exists at #{@new_resource.path} taking no action.")
        else
          action_create
        end
      end

      def action_delete
        if ::File.exists?(@new_resource.path)
          converge_by("delete file #{@new_resource.path}") do 
            backup unless ::File.symlink?(@new_resource.path)
            ::File.delete(@new_resource.path)
            Chef::Log.info("#{@new_resource} deleted file at #{@new_resource.path}")
          end
        end
      end

      def action_touch
        action_create
        converge_by("update utime on file #{@new_resource.path}") do
          time = Time.now
          ::File.utime(time, time, @new_resource.path)
          Chef::Log.info("#{@new_resource} updated atime and mtime to #{time}")
        end
      end

      def backup(file=nil)
        file ||= @new_resource.path
        if @new_resource.backup != false && @new_resource.backup > 0 && ::File.exist?(file)
          time = Time.now
          savetime = time.strftime("%Y%m%d%H%M%S")
          backup_filename = "#{@new_resource.path}.chef-#{savetime}"
          backup_filename = backup_filename.sub(/^([A-Za-z]:)/, "") #strip drive letter on Windows
          # if :file_backup_path is nil, we fallback to the old behavior of
          # keeping the backup in the same directory. We also need to to_s it
          # so we don't get a type error around implicit to_str conversions.
          prefix = Chef::Config[:file_backup_path].to_s
          backup_path = ::File.join(prefix, backup_filename)
          FileUtils.mkdir_p(::File.dirname(backup_path)) if Chef::Config[:file_backup_path]
          FileUtils.cp(file, backup_path, :preserve => true)
          Chef::Log.info("#{@new_resource} backed up to #{backup_path}")

          # Clean up after the number of backups
          slice_number = @new_resource.backup
          backup_files = Dir[::File.join(prefix, ".#{@new_resource.path}.chef-*")].sort { |a,b| b <=> a }
          if backup_files.length >= @new_resource.backup
            remainder = backup_files.slice(slice_number..-1)
            remainder.each do |backup_to_delete|
              FileUtils.rm(backup_to_delete)
              Chef::Log.info("#{@new_resource} removed backup at #{backup_to_delete}")
            end
          end
        end
      end

      def deploy_tempfile
        Tempfile.open(::File.basename(@new_resource.name)) do |tempfile|
          yield tempfile

          temp_res = Chef::Resource::CookbookFile.new(@new_resource.name)
          temp_res.path(tempfile.path)
          ac = Chef::FileAccessControl.new(temp_res, @new_resource, self)
          ac.set_all!
          FileUtils.mv(tempfile.path, @new_resource.path)
        end
      end

      private

      def short_cksum(checksum)
        return "none" if checksum.nil?
        checksum.slice(0,6)
      end

      def new_resource_content_checksum
        @new_resource.content && Digest::SHA2.hexdigest(@new_resource.content)
      end
    end
  end
end
