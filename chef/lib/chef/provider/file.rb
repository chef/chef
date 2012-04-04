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

class Chef

################################################################################
# WHY RUN STUFF
################################################################################

  class Resource
    class File < Chef::Resource
      def run_action(action)
        if self.provider
          provider = self.provider.new(self, self.run_context)
        else # fall back to old provider resolution
          provider = Chef::Platform.provider_for_resource(self)
        end
        provider.load_current_resource
        provider.send("action_#{action}")
        provider.converge_actions.converge!
      end
    end
  end

################################################################################
# END WHY RUN STUFF
################################################################################

  class Provider
    class File < Chef::Provider
      include Chef::Mixin::Checksum

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

################################################################################
# WHY RUN STUFF
################################################################################

      class ConvergeActions
        def initialize
          @actions = []
        end

        def add_action(description, &block)
          @actions << [description, block]
        end

        def converge!
          @actions.each do |description, block|
            puts "* " * 40
            puts "converging"

            # TODO: probably should get this out of the run context instead of making it really global?
            if Chef::Config[:why_run]
              puts description
            else
              block.call
            end
            puts "* " * 40
            puts ""
          end
        end
      end

      def converge_actions
        @converge_actions ||= ConvergeActions.new
      end

      def converge_by(description, &block)
        converge_actions.add_action(description, &block)
      end


################################################################################
# END WHY RUN STUFF
################################################################################

      def load_current_resource
        # TODO: assert parent directory exists.
        @current_resource = Chef::Resource::File.new(@new_resource.name)
        @new_resource.path.gsub!(/\\/, "/") # for Windows
        @current_resource.path(@new_resource.path)
        @current_resource
      end

      # Compare the content of a file.  Returns true if they are the same, false if they are not.
      def compare_content
        checksum(@current_resource.path) == new_resource_content_checksum
      end

      # Set the content of the file, assuming it is not set correctly already.
      def set_content
        unless compare_content
          converge_by("Would update content in file #{@new_resource.path}") do
            backup @new_resource.path if ::File.exists?(@new_resource.path)
            ::File.open(@new_resource.path, "w") {|f| f.write @new_resource.content }
            Chef::Log.info("#{@new_resource} contents updated")
            @new_resource.updated_by_last_action(true)
          end
        end
      end

      def action_create
        if !::File.exists?(@new_resource.path)
          converge_by("Would create new file #{@new_resource.path}") do
            ::File.open(@new_resource.path, "w+") {|f| f.write @new_resource.content }
            @new_resource.updated_by_last_action(true)
            Chef::Log.info("#{@new_resource} created file #{@new_resource.path}")
          end
        elsif @new_resource.content.nil?
          # nothing to do
        else
          set_content
        end
        enforce_ownership_and_permissions
      end

      def action_create_if_missing
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug("File #{@new_resource.path} exists, taking no action.")
        else
          action_create
        end
      end

      def action_delete
        if ::File.exists?(@new_resource.path)
          if ::File.writable?(@new_resource.path)
            backup unless ::File.symlink?(@new_resource.path)
            ::File.delete(@new_resource.path)
            Chef::Log.info("#{@new_resource} deleted file at #{@new_resource.path}")
            @new_resource.updated_by_last_action(true)
          else
            raise "Cannot delete #{@new_resource} at #{@new_resource_path}!"
          end
        end
      end

      def action_touch
        action_create
        time = Time.now
        ::File.utime(time, time, @new_resource.path)
        Chef::Log.info("#{@new_resource} updated atime and mtime to #{time}")
        @new_resource.updated_by_last_action(true)
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

      private

      def assert_enclosing_directory_exists!
        enclosing_dir = ::File.dirname(@new_resource.path)
        unless ::File.directory?(enclosing_dir)
          msg = "Cannot create a file at #{@new_resource.path} because the enclosing directory (#{enclosing_dir}) does not exist"
          raise Chef::Exceptions::EnclosingDirectoryDoesNotExist, msg
        end
      end

      def new_resource_content_checksum
        @new_resource.content && Digest::SHA2.hexdigest(@new_resource.content)
      end
    end
  end
end
