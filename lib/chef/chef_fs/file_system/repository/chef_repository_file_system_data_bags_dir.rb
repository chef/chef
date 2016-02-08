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
require "chef/chef_fs/data_handler/data_bag_item_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class ChefRepositoryFileSystemDataBagsDir

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :file_path

          def initialize(name, parent, file_path)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
            @file_path = file_path
          end

          # ChefFS API:

          # Public api called by multiplexed_dir
          def can_have_child?(name, is_dir)
            is_dir && make_child_entry(name).name_valid?
          end

          def path_for_printing
            file_path
          end

          def children
            dir_ls.sort.
                map { |child_name| make_child_entry(child_name) }
          rescue Errno::ENOENT => e
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
          end

          def create_child(child_name, file_contents=nil)
            make_child_entry(child_name).tap { |c| c.create }
          end

          # An empty children array is an empty dir
          def empty?
            children.empty?
          end

          def child(name)
            possible_child = make_child_entry(name)
            if possible_child.name_valid?
              possible_child
            else
              NonexistentFSObject.new(name, self)
            end
          end

          def root
            parent.root
          end

          # File system wrappers

          def dir_ls
            Dir.entries(file_path).select { |p| !p.start_with?(".") }
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
            File.exists?(file_path)
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemDataBagEntry.new(child_name, self)
          end

        end

        class ChefRepositoryFileSystemDataBagEntry

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :data_handler
          attr_reader :file_path

          def initialize(name, parent)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
            @file_path = "#{parent.file_path}/#{name}"
          end

          def create
            if exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            begin
              Dir.mkdir(file_path)
            rescue Errno::EEXIST
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
          end

          def name_valid?
            !name.start_with?(".")
          end

          def can_have_child?(name, is_dir)
            !name.start_with?(".")
          end

          def path_for_printing
            file_path
          end

          def children
            begin
              dir_ls.sort.
                  map { |child_name| make_child_entry(child_name) }
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def create_child(child_name, file_contents=nil)
            make_child_entry(child_name).tap { |c| c.create(file_contents) }
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

          # File system wrappers

          def dir_ls
            Dir.entries(file_path).select { |p| !p.start_with?(".") }
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
            File.exists?(file_path)
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemDataBagItemEntry.new(child_name, self)
          end

        end

        class ChefRepositoryFileSystemDataBagItemEntry

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :ruby_only
          attr_reader :recursive
          attr_reader :file_path

          def initialize(name, parent)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
            @data_handler = Chef::ChefFS::DataHandler::DataBagItemDataHandler.new
            @file_path = "#{parent.file_path}/#{name}"
          end

          def create(file_contents)
            if exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, self)
            else
              write(file_contents)
            end
          end

          def can_have_child?(name, is_dir)
            false
          end

          def write_pretty_json=(value)
            @write_pretty_json = value
          end

          def write_pretty_json
            @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          end

          def path_for_printing
            file_path
          end

          def delete(recurse)
            File.delete(file_path)
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def exists?
            File.exists?(file_path)
          end

          def read
            begin
              File.open(file_path, "rb") {|f| f.read}
            rescue Errno::ENOENT
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            end
          end

          def write(content)
            File.open(file_path, "wb") do |file|
              file.write(content)
            end
          end

          def root
            parent.root
          end

        end

      end
    end
  end
end
