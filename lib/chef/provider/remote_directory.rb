#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008-2015 Chef Software, Inc.
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

require 'chef/provider/directory'
require 'chef/resource/file'
require 'chef/resource/directory'
require 'chef/resource/cookbook_file'
require 'chef/mixin/file_class'
require 'chef/platform/query_helpers'
require 'chef/util/path_helper'
require 'chef/deprecation/warnings'
require 'chef/deprecation/provider/remote_directory'

require 'forwardable'

class Chef
  class Provider
    class RemoteDirectory < Chef::Provider::Directory
      extend Forwardable
      include Chef::Mixin::FileClass

      provides :remote_directory

      def_delegators :@new_resource, :purge, :path, :source, :cookbook, :cookbook_name
      def_delegators :@new_resource, :files_rights, :files_mode, :files_group, :files_owner, :files_backup
      def_delegators :@new_resource, :rights, :mode, :group, :owner

      attr_accessor :overwrite

      # The overwrite property on the resource.  Delegates to new_resource but can be mutated.
      #
      # @return [Boolean] if we are overwriting
      #
      def overwrite
        @overwrite = new_resource.overwrite if @overwrite.nil?
        @overwrite
      end

      attr_accessor :managed_files

      # Hash containing keys of the paths for all the files that we sync, plus all their
      # parent directories.
      #
      # @return [Hash{String => TrueClass}] Hash of files we've managed.
      #
      def managed_files
        @managed_files ||= {}
      end

      # Handle action :create.
      #
      def action_create
        super

        # Transfer files
        files_to_transfer.each do |cookbook_file_relative_path|
          create_cookbook_file(cookbook_file_relative_path)
          # parent directories and file being transferred need to not be removed in the purge
          add_managed_file(cookbook_file_relative_path)
        end

        purge_unmanaged_files
      end

      # Handle action :create_if_missing.
      #
      def action_create_if_missing
        # if this action is called, ignore the existing overwrite flag
        @overwrite = false
        action_create
      end

      private

      # Add a file and its parent directories to the managed_files Hash.
      #
      # @param [String] cookbook_file_relative_path relative path to the file
      # @api private
      #
      def add_managed_file(cookbook_file_relative_path)
        if purge
          Pathname.new(Chef::Util::PathHelper.cleanpath(::File.join(path, cookbook_file_relative_path))).descend do |d|
            managed_files[d.to_s] = true
          end
        end
      end

      # Remove all files not in the managed_files Hash.
      #
      # @api private
      #
      def purge_unmanaged_files
        if purge
          Dir.glob(::File.join(Chef::Util::PathHelper.escape_glob(path), '**', '*'), ::File::FNM_DOTMATCH).sort!.reverse!.each do |file|
            # skip '.' and '..'
            next if ['.','..'].include?(Pathname.new(file).basename().to_s)

            # Clean the path.  This is required because of the ::File.join
            file = Chef::Util::PathHelper.cleanpath(file)

            # Skip files that we've sync'd and their parent dirs
            next if managed_files.include?(file)

            if ::File.directory?(file)
              if !Chef::Platform.windows? && file_class.symlink?(file.dup)
                # Unix treats dir symlinks as files
                purge_file(file)
              else
                # Unix dirs are dirs, Windows dirs and dir symlinks are dirs
                purge_directory(file)
              end
            else
              purge_file(file)
            end
          end
        end
      end

      # Use a Chef directory sub-resource to remove a directory.
      #
      # @param [String] dir The path of the directory to remove
      # @api private
      #
      def purge_directory(dir)
        res = Chef::Resource::Directory.new(dir, run_context)
        res.run_action(:delete)
        new_resource.updated_by_last_action(true) if res.updated?
      end

      # Use a Chef file sub-resource to remove a file.
      #
      # @param [String] file The path of the file to remove
      # @api private
      #
      def purge_file(file)
        res = Chef::Resource::File.new(file, run_context)
        res.run_action(:delete)
        new_resource.updated_by_last_action(true) if res.updated?
      end

      # Get the files to tranfer.  This returns files in lexicographical sort order.
      #
      # FIXME: it should do breadth-first, see CHEF-5080 (please use a performant sort)
      #
      # @return Array<String> The list of files to transfer
      # @api private
      #
      def files_to_transfer
        cookbook = run_context.cookbook_collection[resource_cookbook]
        files = cookbook.relative_filenames_in_preferred_directory(node, :files, source)
        files.sort!.reverse!
      end

      # Either the explicit cookbook that the user sets on the resource, or the implicit
      # cookbook_name that the resource was declared in.
      #
      # @return [String] Cookbook to get file from.
      # @api private
      #
      def resource_cookbook
        cookbook || cookbook_name
      end

      # If we are overwriting, then cookbook_file sub-resources should all be action :create,
      # otherwise they should be :create_if_missing
      #
      # @return [Symbol] Action to take on cookbook_file sub-resources
      # @api private
      #
      def action_for_cookbook_file
        overwrite ? :create : :create_if_missing
      end

      # This creates and uses a cookbook_file resource to sync a single file from the cookbook.
      #
      # @param [String] cookbook_file_relative_path The relative path to the cookbook file
      # @api private
      #
      def create_cookbook_file(cookbook_file_relative_path)
        full_path = ::File.join(path, cookbook_file_relative_path)

        ensure_directory_exists(::File.dirname(full_path))

        res = cookbook_file_resource(full_path, cookbook_file_relative_path)
        res.run_action(action_for_cookbook_file)
        new_resource.updated_by_last_action(true) if res.updated?
      end

      # This creates the cookbook_file resource for use by create_cookbook_file.
      #
      # @param [String] target_path Path on the system to create
      # @param [String] relative_source_path Relative path in the cookbook to the base source
      # @return [Chef::Resource::CookbookFile] The built cookbook_file resource
      # @api private
      #
      def cookbook_file_resource(target_path, relative_source_path)
        res = Chef::Resource::CookbookFile.new(target_path, run_context)
        res.cookbook_name = resource_cookbook
        res.source(::File.join(source, relative_source_path))
        if Chef::Platform.windows? && files_rights
          files_rights.each_pair do |permission, *args|
            res.rights(permission, *args)
          end
        end
        res.mode(files_mode)       if files_mode
        res.group(files_group)     if files_group
        res.owner(files_owner)     if files_owner
        res.backup(files_backup)   if files_backup

        res
      end

      # This creates and uses a directory resource to create a directory if it is needed.
      #
      # @param [String] dir The path to the directory to create.
      # @api private
      #
      def ensure_directory_exists(dir)
        # doing the check here and skipping the resource should be more performant
        unless ::File.directory?(dir)
          res = directory_resource(dir)
          res.run_action(:create)
          new_resource.updated_by_last_action(true) if res.updated?
        end
      end

      # This creates the directory resource for ensure_directory_exists.
      #
      # @param [String] dir Directory path on the system
      # @return [Chef::Resource::Directory] The built directory resource
      # @api private
      #
      def directory_resource(dir)
        res = Chef::Resource::Directory.new(dir, run_context)
        res.cookbook_name = resource_cookbook
        if Chef::Platform.windows? && rights
          # rights are only meant to be applied to the toppest-level directory;
          # Windows will handle inheritance.
          if dir == path
            rights.each do |r|
              r = r.dup  # do not update the new_resource
              permissions = r.delete(:permissions)
              principals = r.delete(:principals)
              res.rights(permissions, principals, r)
            end
          end
        end
        res.mode(mode) if mode
        res.group(group) if group
        res.owner(owner) if owner
        res.recursive(true)

        res
      end

      #
      # Add back deprecated methods and aliases that are internally unused and should be removed in Chef-13
      #
      extend Chef::Deprecation::Warnings
      include Chef::Deprecation::Provider::RemoteDirectory
      add_deprecation_warnings_for(Chef::Deprecation::Provider::RemoteDirectory.instance_methods)

      alias_method :resource_for_directory, :directory_resource
      add_deprecation_warnings_for([:resource_for_directory])

    end
  end
end
