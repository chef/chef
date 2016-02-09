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

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class Directory

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :file_path

          def initialize(name, parent, file_path = nil)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
            @file_path = file_path || "#{parent.file_path}/#{name}"
          end

          def name_valid?
            !name.start_with?(".")
          end

          # Whether or not the file system entry this object represents is
          # valid. Mainly used to trim dotfiles/dotdirs and non directories
          # from the list of children when enumerating items on the filesystem
          def fs_entry_valid?
            name_valid? && File.directory?(file_path)
          end

          # ChefFS API:

          # Public API called by multiplexed_dir
          def can_have_child?(name, is_dir)
            possible_child = make_child_entry(name)
            possible_child.dir? == is_dir && possible_child.name_valid?
          end

          # Public API callied by chef_fs/file_system
          def dir?
            true
          end

          def path_for_printing
            file_path
          end

          def children
            dir_ls.sort.
              map { |child_name| make_child_entry(child_name) }.
              select { |maybe_child| maybe_child.fs_entry_valid? }
          rescue Errno::ENOENT => e
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
          end

          def create_child(child_name, file_contents = nil)
            make_child_entry(child_name).tap { |c| c.create(file_contents) }
          end

          # An empty children array is an empty dir
          def empty?
            children.empty?
          end

          # Public API callied by chef_fs/file_system
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
            raise "Not Implemented"
          end

        end
      end
    end
  end
end
