#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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
require 'chef/provider'
require 'etc'
require 'fileutils'
require 'chef/scan_access_control'
require 'chef/mixin/checksum'
require 'chef/mixin/shell_out'
require 'chef/util/backup'
require 'chef/util/diff'
require 'chef/deprecation/provider/file'
require 'chef/deprecation/warnings'
require 'chef/file_content_management/deploy'

# The Tao of File Providers:
#  - the content provider must always return a tempfile that we can delete/mv
#  - do_create_file shall always create the file first and obey umask when perms are not specified
#  - do_contents_changes may assume the destination file exists (simplifies exception checking,
#    and always gives us something to diff against)
#  - do_contents_changes must restore the perms to the dest file and not obliterate them with
#    random tempfile permissions
#  - do_acl_changes may assume perms were not modified between lcr and when it runs (although the
#    file may have been created)

class Chef
  class Provider
    class File < Chef::Provider
      include Chef::Mixin::EnforceOwnershipAndPermissions
      include Chef::Mixin::Checksum
      include Chef::Mixin::ShellOut
      include Chef::Util::Selinux

      extend Chef::Deprecation::Warnings
      include Chef::Deprecation::Provider::File
      add_deprecation_warnings_for(Chef::Deprecation::Provider::File.instance_methods)

      attr_reader :deployment_strategy

      def initialize(new_resource, run_context)
        @content_class ||= Chef::Provider::File::Content
        if new_resource.respond_to?(:atomic_update)
          @deployment_strategy = Chef::FileContentManagement::Deploy.strategy(new_resource.atomic_update)
        end
        super
      end

      def whyrun_supported?
        true
      end

      def load_current_resource
        # Let children resources override constructing the @current_resource
        @current_resource ||= Chef::Resource::File.new(@new_resource.name)
        @current_resource.path(@new_resource.path)
        if real_file?(@current_resource.path) && ::File.exists?(@current_resource.path)
          if @action != :create_if_missing && @current_resource.respond_to?(:checksum) && ::File.file?(@current_resource.path)
            @current_resource.checksum(checksum(@current_resource.path))
          end
          load_resource_attributes_from_file(@current_resource)
        end
        @current_resource
      end

      def define_resource_requirements
        # deep inside FAC we have to assert requirements, so call FACs hook to set that up
        access_controls.define_resource_requirements
        # Make sure the parent directory exists, otherwise fail.  For why-run assume it would have been created.
        requirements.assert(:create, :create_if_missing, :touch) do |a|
          parent_directory = ::File.dirname(@new_resource.path)
          a.assertion { ::File.directory?(parent_directory) }
          a.failure_message(Chef::Exceptions::EnclosingDirectoryDoesNotExist, "Parent directory #{parent_directory} does not exist.")
          a.whyrun("Assuming directory #{parent_directory} would have been created")
        end

        # Make sure the file is deletable if it exists, otherwise fail.
        if ::File.exists?(@new_resource.path)
          requirements.assert(:delete) do |a|
            a.assertion { ::File.writable?(@new_resource.path) }
            a.failure_message(Chef::Exceptions::InsufficientPermissions,"File #{@new_resource.path} exists but is not writable so it cannot be deleted")
          end
        end

        # Make sure if the destination already exists that it is a normal file
        #   for :create_if_missing, we're assuming the user wanted to avoid blowing away the non-file here
        #   for :touch, we can modify perms of whatever is at this path, regardless of its type
        #   for :delete, we can blow away whatever is here, regardless of its type
        #   for :create, we have a problem with devining the users intent, so we raise an exception
        unless @new_resource.force_unlink
          requirements.assert(:create) do |a|
            a.assertion { !::File.symlink?(@new_resource.path) }
            a.failure_message(Chef::Exceptions::FileTypeMismatch, "File #{@new_resource.path} exists, but is a #{file_type_string(@new_resource.path)}, set force_unlink to true to remove")
            a.whyrun("Assuming #{file_type_string(@new_resource.path)} at #{@new_resource.path} would have been removed by a previous resource")
          end
        end
      end

      def action_create
        do_unlink
        do_create_file
        do_contents_changes
        do_acl_changes
        do_selinux
        load_resource_attributes_from_file(@new_resource)
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
            do_backup unless ::File.symlink?(@new_resource.path)
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

      private

      def content
        @content ||= begin
           load_current_resource if @current_resource.nil?
           @content_class.new(@new_resource, @current_resource, @run_context)
        end
      end

      def file_type_string(path)
        case
        when ::File.blockdev?(path)
          "block device"
        when ::File.chardev?(path)
          "char device"
        when ::File.directory?(path)
          "directory"
        when ::File.pipe?(path)
          "pipe"
        when ::File.socket?(path)
          "socket"
        when ::File.symlink?(path)
          "symlink"
        else
          "unknown filetype"
        end
      end

      def real_file?(path)
        # TODO: For now only testing the logic with symlinks
        ! ::File.symlink?(path)
      end

      def do_unlink
        @file_unlinked = false
        if @new_resource.force_unlink
          if !real_file?(@new_resource.path)
            # unlink things that aren't normal files
            description = "unlink #{file_type_string(@new_resource.path)} at #{@new_resource.path}"
            converge_by(description) do
              ::File.unlink(@new_resource.path)
            end
            @file_unlinked = true
          end
        end
      end

      def file_unlinked?
        @file_unlinked == true
      end

      def do_create_file
        @file_created = false
        if !::File.exists?(@new_resource.path) || file_unlinked?
          converge_by("create new file #{@new_resource.path}") do
            deployment_strategy.create(@new_resource.path)
            Chef::Log.info("#{@new_resource} created file #{@new_resource.path}")
          end
          @file_created = true
        end
      end

      # do_contents_changes needs to know if do_create_file created a file or not
      def file_created?
        @file_created == true
      end

      def do_backup(file = nil)
        Chef::Util::Backup.new(@new_resource, file).backup!
      end

      def diff
        @diff ||= Chef::Util::Diff.new
      end

      def update_file_contents
        do_backup unless file_created?
        deployment_strategy.deploy(tempfile.path, @new_resource.path)
        Chef::Log.info("#{@new_resource} updated file contents #{@new_resource.path}")
        @new_resource.checksum(checksum(@new_resource.path)) # for reporting
      end

      def do_contents_changes
        # a nil tempfile is okay, means the resource has no content or no new content
        return if tempfile.nil?
        # but a tempfile that has no path or doesn't exist should not happen
        if tempfile.path.nil? || !::File.exists?(tempfile.path)
          raise "chef-client is confused, trying to deploy a file that has no path or does not exist..."
        end
        # the file? on the next line suppresses the case in why-run when we have a not-file here that would have otherwise been removed
        if ::File.file?(@new_resource.path) && contents_changed?
          diff.diff(@current_resource.path, tempfile.path)
          @new_resource.diff( diff.for_reporting ) unless file_created?
          description = [ "update content in file #{@new_resource.path} from #{short_cksum(@current_resource.checksum)} to #{short_cksum(checksum(tempfile.path))}" ]
          description << diff.for_output
          converge_by(description) do
            update_file_contents
          end
        end
        # unlink necessary to clean up in why-run mode
        tempfile.unlink
      end

      # This logic ideally will be  made into some kind of generic
      # platform-dependent post-converge hook for file-like
      # resources, but for now we only have the single selinux use
      # case.
      def do_selinux(recursive = false)
        if resource_updated? && Chef::Config[:enable_selinux_file_permission_fixup]
          if selinux_enabled?
            converge_by("restore selinux security context") do
              restore_security_context(@new_resource_path, recursive)
            end
          else
            Chef::Log.debug "selinux utilities can not be found. Skipping selinux permission fixup."
          end
        end
      end

      def do_acl_changes
        if access_controls.requires_changes?
          converge_by(access_controls.describe_changes) do
            access_controls.set_all
          end
        end
      end

      def contents_changed?
        checksum(tempfile.path) != @current_resource.checksum
      end

      def tempfile
        content.tempfile
      end

      def short_cksum(checksum)
        return "none" if checksum.nil?
        checksum.slice(0,6)
      end

      def load_resource_attributes_from_file(resource)

        if Chef::Platform.windows?
          # This is a work around for CHEF-3554.
          # OC-6534: is tracking the real fix for this workaround.
          # Add support for Windows equivalent, or implicit resource
          # reporting won't work for Windows.
          return
        end
        acl_scanner = ScanAccessControl.new(@new_resource, resource)
        acl_scanner.set_all!
      end

      # File.exists? always follows symlinks, i want true if there's a symlink there
      # def exists_or_symlink?(path)
      #  ::File.symlink?(path) || ::File.exists?(path)
      # end

    end
  end
end

