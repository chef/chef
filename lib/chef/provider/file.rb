#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../config"
require_relative "../log"
require_relative "../resource/file"
require_relative "../provider"
require "etc" unless defined?(Etc)
require "fileutils" unless defined?(FileUtils)
require_relative "../scan_access_control"
require_relative "../mixin/checksum"
require_relative "../mixin/file_class"
require_relative "../mixin/enforce_ownership_and_permissions"
require_relative "../util/backup"
require_relative "../util/diff"
require_relative "../util/selinux"
require_relative "../file_content_management/deploy"
require "chef-utils" unless defined?(ChefUtils::CANARY)

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
      include Chef::Util::Selinux
      include Chef::Mixin::FileClass

      provides :file

      attr_reader :deployment_strategy

      attr_accessor :needs_creating
      attr_accessor :needs_unlinking
      attr_accessor :managing_symlink

      def initialize(new_resource, run_context)
        @content_class ||= Chef::Provider::File::Content
        if new_resource.respond_to?(:atomic_update)
          @deployment_strategy = Chef::FileContentManagement::Deploy.strategy(new_resource.atomic_update)
        end
        super
      end

      def load_current_resource
        # true if there is a symlink and we need to manage what it points at
        @managing_symlink = file_class.symlink?(new_resource.path) && ( new_resource.manage_symlink_source || new_resource.manage_symlink_source.nil? )

        # true if there is a non-file thing in the way that we need to unlink first
        @needs_unlinking =
          if ::File.exist?(new_resource.path)
            if managing_symlink?
              !symlink_to_real_file?(new_resource.path)
            else
              !real_file?(new_resource.path)
            end
          else
            false
          end

        # true if we are going to be creating a new file
        @needs_creating = !::File.exist?(new_resource.path) || needs_unlinking?

        # Let children resources override constructing the current_resource
        @current_resource ||= Chef::Resource::File.new(new_resource.name)
        current_resource.path(new_resource.path)

        unless needs_creating?
          # we are updating an existing file
          if managing_content?
            logger.trace("#{new_resource} checksumming file at #{new_resource.path}.")
            current_resource.checksum(checksum(current_resource.path))
          else
            # if the file does not exist or is not a file, then the checksum is invalid/pointless
            current_resource.checksum(nil)
          end
          load_resource_attributes_from_file(current_resource)
        end

        current_resource
      end

      def define_resource_requirements
        # deep inside FAC we have to assert requirements, so call FACs hook to set that up
        access_controls.define_resource_requirements

        # Make sure the parent directory exists, otherwise fail.  For why-run assume it would have been created.
        requirements.assert(:create, :create_if_missing, :touch) do |a|
          parent_directory = ::File.dirname(new_resource.path)
          a.assertion { ::File.directory?(parent_directory) }
          a.failure_message(Chef::Exceptions::EnclosingDirectoryDoesNotExist, "Parent directory #{parent_directory} does not exist.")
          a.whyrun("Assuming directory #{parent_directory} would have been created")
        end

        # Make sure the file is deletable if it exists, otherwise fail.
        if ::File.exist?(new_resource.path)
          requirements.assert(:delete) do |a|
            a.assertion { ::File.writable?(new_resource.path) }
            a.failure_message(Chef::Exceptions::InsufficientPermissions, "File #{new_resource.path} exists but is not writable so it cannot be deleted")
          end
        end

        error, reason, whyrun_message = inspect_existing_fs_entry
        requirements.assert(:create) do |a|
          a.assertion { error.nil? }
          a.failure_message(error, reason)
          a.whyrun(whyrun_message)
          # Subsequent attempts to read the fs entry at the path (e.g., for
          # calculating checksums) could blow up, so give up trying to continue
          # why-running.
          a.block_action!
        end
      end

      action :create do
        do_generate_content
        do_validate_content
        do_unlink
        do_create_file
        do_contents_changes
        do_acl_changes
        do_selinux
        load_resource_attributes_from_file(new_resource) unless Chef::Config[:why_run]
      end

      action :create_if_missing do
        unless ::File.exist?(new_resource.path)
          action_create
        else
          logger.debug("#{new_resource} exists at #{new_resource.path} taking no action.")
        end
      end

      action :delete do
        if ::File.exists?(new_resource.path)
          converge_by("delete file #{new_resource.path}") do
            do_backup unless file_class.symlink?(new_resource.path)
            ::File.delete(new_resource.path)
            logger.info("#{new_resource} deleted file at #{new_resource.path}")
          end
        end
      end

      action :touch do
        action_create
        converge_by("update utime on file #{new_resource.path}") do
          time = Time.now
          ::File.utime(time, time, new_resource.path)
          logger.info("#{new_resource} updated atime and mtime to #{time}")
        end
      end

      # Implementation components *should* follow symlinks when managing access
      # control (e.g., use chmod instead of lchmod even if the path we're
      # managing is a symlink).
      def manage_symlink_access?
        false
      end

      private

      # What to check in this resource to see if we're going to be actively managing
      # content (for things like doing checksums in load_current_resource).  Expected to
      # be overridden in subclasses.
      def managing_content?
        return true if new_resource.checksum
        return true if !new_resource.content.nil? && @action != :create_if_missing

        false
      end

      # Handles resource requirements for action :create when some fs entry
      # already exists at the destination path. For actions other than create,
      # we don't care what kind of thing is at the destination path because:
      # * for :create_if_missing, we're assuming the user wanted to avoid blowing away the non-file here
      # * for :touch, we can modify perms of whatever is at this path, regardless of its type
      # * for :delete, we can blow away whatever is here, regardless of its type
      #
      # For the action :create case, we need to deal with user-selectable
      # behavior to see if we're in an error condition.
      # * If there's no file at the destination path currently, we're cool to
      #   create it.
      # * If the fs entry that currently exists at the destination is a regular
      #   file, we're cool to update it with new content.
      # * If the fs entry is a symlink AND the resource has
      #   `manage_symlink_source` enabled, we need to verify that the symlink is
      #   a valid pointer to a real file. If it is, we can manage content and
      #   permissions on the symlink source, otherwise, error.
      # * If `manage_symlink_source` is not enabled, fall through.
      # * If force_unlink is true, action :create will unlink whatever is in the way.
      # * If force_unlink is false, we're in an exceptional situation, so we
      #   want to error.
      #
      # Note that this method returns values to be used with requirement
      # assertions, which then decide whether or not to raise or issue a
      # warning for whyrun mode.
      def inspect_existing_fs_entry
        path = new_resource.path

        if !l_exist?(path)
          [nil, nil, nil]
        elsif real_file?(path)
          [nil, nil, nil]
        elsif file_class.symlink?(path) && new_resource.manage_symlink_source
          verify_symlink_sanity(path)
        elsif file_class.symlink?(new_resource.path) && new_resource.manage_symlink_source.nil?
          logger.warn("File #{path} managed by #{new_resource} is really a symlink (to #{file_class.realpath(new_resource.path)}). Managing the source file instead.")
          logger.warn("Disable this warning by setting `manage_symlink_source true` on the resource")
          logger.warn("In a future release, 'manage_symlink_source' will not be enabled by default")
          verify_symlink_sanity(path)
        elsif new_resource.force_unlink
          [nil, nil, nil]
        else
          [ Chef::Exceptions::FileTypeMismatch,
            "File #{path} exists, but is a #{file_type_string(new_resource.path)}, set force_unlink to true to remove",
            "Assuming #{file_type_string(new_resource.path)} at #{new_resource.path} would have been removed by a previous resource",
          ]
        end
      end

      # Returns values suitable for use in a requirements assertion statement
      # when managing symlink source. If we're managing symlink source we can
      # hit 3 error cases:
      # 1. Symlink to nowhere: File.realpath(symlink) -> raise Errno::ENOENT
      # 2. Symlink loop: File.realpath(symlink) -> raise Errno::ELOOP
      # 3. Symlink to not-a-real-file: File.realpath(symlink) -> (directory|blockdev|etc.)
      # If any of the above apply, returns a 3-tuple of Exception class,
      # exception message, whyrun message; otherwise returns a 3-tuple of nil.
      def verify_symlink_sanity(path)
        real_path = ::File.realpath(path)
        if real_file?(real_path)
          [nil, nil, nil]
        else
          [ Chef::Exceptions::FileTypeMismatch,
            "File #{path} exists, but is a symlink to #{real_path} which is a #{file_type_string(real_path)}. " +
              "Disable manage_symlink_source and set force_unlink to remove it.",
            "Assuming symlink #{path} or source file #{real_path} would have been fixed by a previous resource",
          ]
        end
      rescue Errno::ELOOP
        [ Chef::Exceptions::InvalidSymlink,
          "Symlink at #{path} (pointing to #{::File.readlink(path)}) exists but attempting to resolve it creates a loop",
          "Assuming symlink loop would be fixed by a previous resource" ]
      rescue Errno::ENOENT
        [ Chef::Exceptions::InvalidSymlink,
          "Symlink at #{path} (pointing to #{::File.readlink(path)}) exists but attempting to resolve it leads to a nonexistent file",
          "Assuming symlink source would be created by a previous resource" ]
      end

      def content
        @content ||= begin
          load_current_resource if current_resource.nil?
          @content_class.new(new_resource, current_resource, @run_context, logger)
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
        when file_class.symlink?(path)
          "symlink"
        else
          "unknown filetype"
        end
      end

      def real_file?(path)
        !file_class.symlink?(path) && ::File.file?(path)
      end

      # like real_file? that follows (sane) symlinks
      def symlink_to_real_file?(path)
        real_file?(::File.realpath(path))
      rescue Errno::ELOOP, Errno::ENOENT
        false
      end

      # Similar to File.exist?, but also returns true in the case that the
      # named file is a broken symlink.
      def l_exist?(path)
        ::File.exist?(path) || file_class.symlink?(path)
      end

      def unlink(path)
        # Directories can not be unlinked. Remove them using FileUtils.
        if ::File.directory?(path)
          FileUtils.rm_rf(path)
        else
          ::File.unlink(path)
        end
      end

      def do_generate_content
        # referencing the tempfile magically causes content to be generated
        tempfile
      end

      def tempfile_checksum
        @tempfile_checksum ||= checksum(tempfile.path)
      end

      def do_validate_content
        if new_resource.checksum && tempfile && ( new_resource.checksum != tempfile_checksum )
          raise Chef::Exceptions::ChecksumMismatch.new(short_cksum(new_resource.checksum), short_cksum(tempfile_checksum))
        end

        if tempfile && contents_changed?
          new_resource.verify.each do |v|
            unless v.verify(tempfile.path)
              backupfile = "#{Chef::Config[:file_cache_path]}/failed_validations/#{::File.basename(tempfile.path)}"
              FileUtils.mkdir_p ::File.dirname(backupfile)
              FileUtils.cp tempfile.path, backupfile
              raise Chef::Exceptions::ValidationFailed.new "Proposed content for #{new_resource.path} failed verification #{new_resource.sensitive ? "[sensitive]" : "#{v}\n#{v.output}"}\nTemporary file moved to #{backupfile}"
            end
          end
        end
      end

      def do_unlink
        if new_resource.force_unlink
          if needs_unlinking?
            # unlink things that aren't normal files
            description = "unlink #{file_type_string(new_resource.path)} at #{new_resource.path}"
            converge_by(description) do
              unlink(new_resource.path)
            end
          end
        end
      end

      def do_create_file
        if needs_creating?
          converge_by("create new file #{new_resource.path}") do
            deployment_strategy.create(new_resource.path)
            logger.info("#{new_resource} created file #{new_resource.path}")
          end
        end
      end

      def do_backup(file = nil)
        Chef::Util::Backup.new(new_resource, file).backup!
      end

      def diff
        @diff ||= Chef::Util::Diff.new
      end

      def update_file_contents
        do_backup unless needs_creating?
        deployment_strategy.deploy(tempfile.path, ::File.realpath(new_resource.path).force_encoding(Chef::Config[:ruby_encoding]))
        logger.info("#{new_resource} updated file contents #{new_resource.path}")
        if managing_content?
          # save final checksum for reporting.
          new_resource.final_checksum = checksum(new_resource.path)
        end
      end

      def do_contents_changes
        # a nil tempfile is okay, means the resource has no content or no new content
        return if tempfile.nil?
        # but a tempfile that has no path or doesn't exist should not happen
        if tempfile.path.nil? || !::File.exists?(tempfile.path)
          raise "#{ChefUtils::Dist::Infra::CLIENT} is confused, trying to deploy a file that has no path or does not exist..."
        end

        # the file? on the next line suppresses the case in why-run when we have a not-file here that would have otherwise been removed
        if ::File.file?(new_resource.path) && contents_changed?
          description = [ "update content in file #{new_resource.path} from \
#{short_cksum(current_resource.checksum)} to #{short_cksum(tempfile_checksum)}" ]

          # Hide the diff output if the resource is marked as a sensitive resource
          if new_resource.sensitive
            new_resource.diff("suppressed sensitive resource")
            description << "suppressed sensitive resource"
          else
            diff.diff(current_resource.path, tempfile.path)
            new_resource.diff( diff.for_reporting ) unless needs_creating?
            description << diff.for_output
          end

          converge_by(description) do
            update_file_contents
          end
        end

        # unlink necessary to clean up in why-run mode
        tempfile.close
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
              restore_security_context(::File.realpath(new_resource.path), recursive)
            end
          else
            logger.trace "selinux utilities can not be found. Skipping selinux permission fixup."
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
        logger.trace "calculating checksum of #{tempfile.path} to compare with #{current_resource.checksum}"
        tempfile_checksum != current_resource.checksum
      end

      def tempfile
        @tempfile ||= content.tempfile
      end

      def load_resource_attributes_from_file(resource)
        if ChefUtils.windows?
          # This is a work around for CHEF-3554.
          # OC-6534: is tracking the real fix for this workaround.
          # Add support for Windows equivalent, or implicit resource
          # reporting won't work for Windows.
          return
        end

        acl_scanner = ScanAccessControl.new(new_resource, resource)
        acl_scanner.set_all!
      end

      def managing_symlink?
        !!@managing_symlink
      end

      def needs_creating?
        !!@needs_creating
      end

      def needs_unlinking?
        !!@needs_unlinking
      end
    end
  end
end
