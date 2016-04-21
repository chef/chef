#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/base_fs_dir"
require "chef/chef_fs/file_system/chef_server/rest_list_dir"
require "chef/chef_fs/file_system/exceptions"
require "chef/chef_fs/path_utils"
require "fileutils"

class Chef
  module ChefFS
    module FileSystem
      module Repository
        class FileSystemEntry < BaseFSDir
          def initialize(name, parent, file_path = nil, data_handler = nil)
            super(name, parent)
            @file_path = file_path || "#{parent.file_path}/#{name}"
            @data_handler = data_handler
          end

          attr_reader :file_path

          def write_pretty_json=(value)
            @write_pretty_json = value
          end

          def write_pretty_json
            @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          end

          def data_handler
            @data_handler || parent.data_handler
          end

          def path_for_printing
            file_path
          end

          def chef_object
            data_handler.chef_object(Chef::JSONCompat.parse(read))
          rescue
            Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
            nil
          end

          def can_have_child?(name, is_dir)
            !is_dir && File.extname(name) == ".json"
          end

          def name_valid?
            !name.start_with?(".")
          end

          # basic implementation to support Repository::Directory API
          def fs_entry_valid?
            name_valid? && File.exist?(file_path)
          end

          def minimize(file_contents, entry)
            object = Chef::JSONCompat.parse(file_contents)
            object = data_handler.normalize(object, entry)
            object = data_handler.minimize(object, entry)
            Chef::JSONCompat.to_json_pretty(object)
          end

          def children
            # Except cookbooks and data bag dirs, all things must be json files
            Dir.entries(file_path).sort.
              map { |child_name| make_child_entry(child_name) }.
              select { |new_child| new_child.fs_entry_valid? && can_have_child?(new_child.name, new_child.dir?) }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def create_child(child_name, file_contents = nil)
            child = make_child_entry(child_name)
            if child.exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            if file_contents
              child.write(file_contents)
            else
              Dir.mkdir(child.file_path)
            end
            child
          rescue Errno::EEXIST
            raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
          end

          def dir?
            File.directory?(file_path)
          end

          def delete(recurse)
            if dir?
              if !recurse
                raise MustDeleteRecursivelyError.new(self, $!)
              end
              FileUtils.rm_r(file_path)
            else
              File.delete(file_path)
            end
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def exists?
            File.exists?(file_path) && (parent.nil? || parent.can_have_child?(name, dir?))
          end

          def read
            File.open(file_path, "rb") { |f| f.read }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def write(file_contents)
            if file_contents && write_pretty_json && File.extname(name) == ".json"
              file_contents = minimize(file_contents, self)
            end
            File.open(file_path, "wb") do |file|
              file.write(file_contents)
            end
          end
          alias :create :write

          protected

          def make_child_entry(child_name)
            FileSystemEntry.new(child_name, self)
          end
        end
      end
    end
  end
end
