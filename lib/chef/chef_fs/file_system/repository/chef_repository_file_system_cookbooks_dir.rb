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

require "chef/chef_fs/file_system/repository/chef_repository_file_system_entry"
require "chef/chef_fs/file_system/repository/chef_repository_file_system_cookbook_dir"
require "chef/cookbook/chefignore"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class ChefRepositoryFileSystemCookbooksDir

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :chefignore
          attr_reader :file_path

          def initialize(name, parent, file_path)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
            @file_path = file_path || "#{parent.file_path}/#{name}"
            #@data_handler = nil
            begin
              @chefignore = Chef::Cookbook::Chefignore.new(self.file_path)
            rescue Errno::EISDIR
            rescue Errno::EACCES
              # Work around a bug in Chefignore when chefignore is a directory
            end
          end

          def children
            begin
              cookbooks = Dir.entries(file_path).sort.
                          map { |child_name| make_child_entry(child_name) }.
                          select { |child| child && can_have_child?(child.name, child.dir?) }
              # empty cookbooks and cookbook directories are ignored
              cookbooks.select do |entry|
                if !entry.can_upload?
                  Chef::Log.warn("Cookbook '#{entry.name}' is empty or entirely chefignored at #{entry.path_for_printing}")
                  false
                else
                  true
                end
              end
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def can_have_child?(name, is_dir)
            is_dir && !name.start_with?(".")
          end

          def write_cookbook(cookbook_path, cookbook_version_json, from_fs)
            cookbook_name = File.basename(cookbook_path)
            child = make_child_entry(cookbook_name)

            # Use the copy/diff algorithm to copy it down so we don't destroy
            # chefignored data.  This is terribly un-thread-safe.
            Chef::ChefFS::FileSystem.copy_to(Chef::ChefFS::FilePattern.new("/#{cookbook_path}"), from_fs, child, nil, { :purge => true })

            # Write out .uploaded-cookbook-version.json
            cookbook_file_path = File.join(file_path, cookbook_name)
            if !File.exists?(cookbook_file_path)
              FileUtils.mkdir_p(cookbook_file_path)
            end
            uploaded_cookbook_version_path = File.join(cookbook_file_path, Chef::Cookbook::CookbookVersionLoader::UPLOADED_COOKBOOK_VERSION_FILE)
            File.open(uploaded_cookbook_version_path, "w") do |file|
              file.write(cookbook_version_json)
            end
          end

          # no data handler used here.
          ## def data_handler
          ##   @data_handler || parent.data_handler
          ## end

          def path_for_printing
            file_path
          end

          def create_child(child_name, file_contents = nil)
            child = make_child_entry(child_name)
            if child.exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            begin
              Dir.mkdir(child.file_path)
            rescue Errno::EEXIST
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            child
          end

          def delete(recurse)
            if exists?
              if !recurse
                raise MustDeleteRecursivelyError.new(self, $!)
              end
              FileUtils.rm_r(file_path)
            else
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def exists?
            File.exists?(file_path) # && (parent.nil? || parent.can_have_child?(name, dir?))
          end

          # An empty children array is an empty dir
          def empty?
            children.empty?
          end

          def child(name)
            if can_have_child?(name, true) || can_have_child?(name, false)
              result = make_child_entry(name)
            end
            result || NonexistentFSObject.new(name, self)
          end

          def root
            parent.root
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemCookbookDir.new(child_name, self)
          end

        end
      end
    end
  end
end
