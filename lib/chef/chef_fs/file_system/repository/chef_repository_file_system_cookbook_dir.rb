#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/repository/chef_repository_file_system_cookbook_entry"
require "chef/chef_fs/file_system/chef_server/cookbook_dir"
require "chef/chef_fs/file_system/chef_server/versioned_cookbook_dir"
require "chef/chef_fs/file_system/exceptions"
require "chef/cookbook/cookbook_version_loader"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        # Represents ROOT/cookbooks/:cookbook
        class ChefRepositoryFileSystemCookbookDir < ChefRepositoryFileSystemCookbookEntry

          # API Required by Respository::Directory

          def fs_entry_valid?
            return false unless File.directory?(file_path) && name_valid?
            if can_upload?
              true
            else
              Chef::Log.warn("Cookbook '#{name}' is empty or entirely chefignored at #{path_for_printing}")
              false
            end
          end

          def name_valid?
            !name.start_with?(".")
          end

          def dir?
            true
          end

          def create(file_contents = nil)
            if exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, self)
            end
            begin
              Dir.mkdir(file_path)
            rescue Errno::EEXIST
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, self)
            end
          end

          def write(cookbook_path, cookbook_version_json, from_fs)
            # Use the copy/diff algorithm to copy it down so we don't destroy
            # chefignored data.  This is terribly un-thread-safe.
            Chef::ChefFS::FileSystem.copy_to(Chef::ChefFS::FilePattern.new("/#{cookbook_path}"), from_fs, self, nil, { :purge => true })

            # Write out .uploaded-cookbook-version.json
            # cookbook_file_path = File.join(file_path, cookbook_name) <- this should be the same as self.file_path
            if !File.exists?(file_path)
              FileUtils.mkdir_p(file_path)
            end
            uploaded_cookbook_version_path = File.join(file_path, Chef::Cookbook::CookbookVersionLoader::UPLOADED_COOKBOOK_VERSION_FILE)
            File.open(uploaded_cookbook_version_path, "w") do |file|
              file.write(cookbook_version_json)
            end
          end

          # Customizations of base class

          def chef_object
            cb = cookbook_version
            if !cb
              Chef::Log.error("Cookbook #{file_path} empty.")
              raise "Cookbook #{file_path} empty."
            end
            cb
          rescue => e
            Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{e}")
            Chef::Log.error(e.backtrace.join("\n"))
            raise
          end

          def children
            super.select { |entry| !(entry.dir? && entry.children.size == 0 ) }
          end

          def can_have_child?(name, is_dir)
            if is_dir && !%w{ root_files .. . }.include?(name)
              # Only the given directories will be uploaded.
              return true
            elsif name == Chef::Cookbook::CookbookVersionLoader::UPLOADED_COOKBOOK_VERSION_FILE
              return false
            end
            super(name, is_dir)
          end

          # Exposed as a class method so that it can be used elsewhere
          def self.canonical_cookbook_name(entry_name)
            name_match = Chef::ChefFS::FileSystem::ChefServer::VersionedCookbookDir::VALID_VERSIONED_COOKBOOK_NAME.match(entry_name)
            return nil if name_match.nil?
            name_match[1]
          end

          def canonical_cookbook_name(entry_name)
            self.class.canonical_cookbook_name(entry_name)
          end

          def uploaded_cookbook_version_path
            File.join(file_path, Chef::Cookbook::CookbookVersionLoader::UPLOADED_COOKBOOK_VERSION_FILE)
          end

          def can_upload?
            File.exists?(uploaded_cookbook_version_path) || children.size > 0
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemCookbookEntry.new(child_name, self, nil, false, true)
          end

          def cookbook_version
            loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
            loader.load_cookbooks
            loader.cookbook_version
          end
        end
      end
    end
  end
end
