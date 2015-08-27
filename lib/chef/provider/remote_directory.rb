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

require 'chef/provider/file'
require 'chef/provider/directory'
require 'chef/resource/directory'
require 'chef/resource/remote_file'
require 'chef/mixin/file_class'
require 'chef/platform'
require 'uri'
require 'tempfile'
require 'net/https'
require 'set'
require 'chef/util/path_helper'

class Chef
  class Provider
    class RemoteDirectory < Chef::Provider::Directory

      provides :remote_directory

      include Chef::Mixin::FileClass

      def action_create
        super
        # Mark all files as needing to be purged
        files_to_purge = Set.new(ls(@new_resource.path)) # Make sure each path is clean

        # Transfer files
        files_to_transfer.each do |cookbook_file_relative_path|
          create_cookbook_file(cookbook_file_relative_path)
          # parent directories and file being transferred are removed from the purge list
          Pathname.new(Chef::Util::PathHelper.cleanpath(::File.join(@new_resource.path, cookbook_file_relative_path))).descend do |d|
            files_to_purge.delete(d.to_s)
          end
        end

        purge_unmanaged_files(files_to_purge)
      end

      def action_create_if_missing
        # if this action is called, ignore the existing overwrite flag
        @new_resource.overwrite(false)
        action_create
      end

      protected

      # List all excluding . and ..
      def ls(path)
        files = Dir.glob(::File.join(Chef::Util::PathHelper.escape_glob(path), '**', '*'),
                 ::File::FNM_DOTMATCH)

        # Remove current directory and previous directory
        files = files.reject do |name|
          basename = Pathname.new(name).basename().to_s
          ['.', '..'].include?(basename)
        end

        # Clean all the paths... this is required because of the join
        files.map {|f| Chef::Util::PathHelper.cleanpath(f)}
      end

      def purge_unmanaged_files(unmanaged_files)
        if @new_resource.purge
          unmanaged_files.sort.reverse.each do |f|
            # file_class comes from Chef::Mixin::FileClass
            if ::File.directory?(f) && !Chef::Platform.windows? && !file_class.symlink?(f.dup)
              # Linux treats directory symlinks as files
              # Remove a directory as a directory when not on windows if it is not a symlink
              purge_directory(f)
            elsif ::File.directory?(f) && Chef::Platform.windows?
              # Windows treats directory symlinks as directories so we delete them here
              purge_directory(f)
            else
              converge_by("delete unmanaged file #{f}") do
                ::File.delete(f)
                Chef::Log.debug("#{@new_resource} deleted file #{f}")
              end
            end
          end
        end
      end

      def purge_directory(dir)
        converge_by("delete unmanaged directory #{dir}") do
          Dir::rmdir(dir)
          Chef::Log.debug("#{@new_resource} removed directory #{dir}")
        end
      end

      def files_to_transfer
        cookbook = run_context.cookbook_collection[resource_cookbook]
        files = cookbook.relative_filenames_in_preferred_directory(node, :files, @new_resource.source)
        files.sort.reverse
      end

      def directory_root_in_cookbook_cache
        @directory_root_in_cookbook_cache ||= begin
          cookbook = run_context.cookbook_collection[resource_cookbook]
          cookbook.preferred_filename_on_disk_location(node, :files, @new_resource.source, @new_resource.path)
        end
      end

      # Determine the cookbook to get the file from. If new resource sets an
      # explicit cookbook, use it, otherwise fall back to the implicit cookbook
      # i.e., the cookbook the resource was declared in.
      def resource_cookbook
        @new_resource.cookbook || @new_resource.cookbook_name
      end

      def create_cookbook_file(cookbook_file_relative_path)
        full_path = ::File.join(@new_resource.path, cookbook_file_relative_path)

        ensure_directory_exists(::File.dirname(full_path))

        file_to_fetch = cookbook_file_resource(full_path, cookbook_file_relative_path)
        if @new_resource.overwrite
          file_to_fetch.run_action(:create)
        else
          file_to_fetch.run_action(:create_if_missing)
        end
        @new_resource.updated_by_last_action(true) if file_to_fetch.updated?
      end

      def cookbook_file_resource(target_path, relative_source_path)
        cookbook_file = Chef::Resource::CookbookFile.new(target_path, run_context)
        cookbook_file.cookbook_name = @new_resource.cookbook || @new_resource.cookbook_name
        cookbook_file.source(::File.join(@new_resource.source, relative_source_path))
        if Chef::Platform.windows? && @new_resource.files_rights
          @new_resource.files_rights.each_pair do |permission, *args|
            cookbook_file.rights(permission, *args)
          end
        end
        cookbook_file.mode(@new_resource.files_mode)       if @new_resource.files_mode
        cookbook_file.group(@new_resource.files_group)     if @new_resource.files_group
        cookbook_file.owner(@new_resource.files_owner)     if @new_resource.files_owner
        cookbook_file.backup(@new_resource.files_backup)   if @new_resource.files_backup

        cookbook_file
      end

      def ensure_directory_exists(path)
        unless ::File.directory?(path)
          directory_to_create = resource_for_directory(path)
          directory_to_create.run_action(:create)
          @new_resource.updated_by_last_action(true) if directory_to_create.updated?
        end
      end

      def resource_for_directory(path)
        dir = Chef::Resource::Directory.new(path, run_context)
        dir.cookbook_name = @new_resource.cookbook || @new_resource.cookbook_name
        if Chef::Platform.windows? && @new_resource.rights
          # rights are only meant to be applied to the toppest-level directory;
          # Windows will handle inheritance.
          if path == @new_resource.path
            @new_resource.rights.each do |rights| #rights is a hash
              permissions = rights.delete(:permissions) #delete will return the value or nil if not found
              principals = rights.delete(:principals)
              dir.rights(permissions, principals, rights)
            end
          end
        end
        dir.mode(@new_resource.mode) if @new_resource.mode
        dir.group(@new_resource.group)
        dir.owner(@new_resource.owner)
        dir.recursive(true)
        dir
      end

      def whyrun_supported?
        true
      end

    end
  end
end
