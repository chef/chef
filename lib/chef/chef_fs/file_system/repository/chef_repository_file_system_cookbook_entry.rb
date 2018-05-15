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

require "chef/chef_fs/file_system/repository/file_system_entry"
require "chef/chef_fs/file_system/repository/cookbooks_dir"
require "chef/chef_fs/file_system/exceptions"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        # NB: unlike most other things in chef_fs/file_system/repository, this
        # class represents both files and directories, so it needs to have the
        # methods/if branches for each.
        class ChefRepositoryFileSystemCookbookEntry

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :ruby_only
          attr_reader :recursive
          attr_reader :file_path

          alias_method :display_path, :path
          alias_method :display_name, :name
          alias_method :bare_name, :name

          def initialize(name, parent, file_path = nil, ruby_only = false, recursive = false)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils.join(parent.path, name)
            @ruby_only = ruby_only
            @recursive = recursive
            @data_handler = nil
            @file_path = file_path || "#{parent.file_path}/#{name}"
          end

          def children
            entries = Dir.entries(file_path).sort.
                      map { |child_name| make_child_entry(child_name) }.
                      select { |child| child && can_have_child?(child.name, child.dir?) }
            entries.select { |entry| !(entry.dir? && entry.children.size == 0 ) }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def can_have_child?(name, is_dir)
            if is_dir
              return recursive && name != "." && name != ".."
            elsif ruby_only
              return false if name[-3..-1] != ".rb"
            end

            # Check chefignore
            ignorer = parent
            loop do
              if ignorer.is_a?(CookbooksDir)
                # Grab the path from entry to child
                path_to_child = name
                child = self
                while child.parent != ignorer
                  path_to_child = PathUtils.join(child.name, path_to_child)
                  child = child.parent
                end
                # Check whether that relative path is ignored
                return !ignorer.chefignore || !ignorer.chefignore.ignored?(path_to_child)
              end
              ignorer = ignorer.parent
              break unless ignorer
            end

            true
          end

          def write_pretty_json
            false
          end

          def path_for_printing
            file_path
          end

          def create_child(child_name, file_contents = nil)
            child = make_child_entry(child_name)
            if child.exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
            end
            if file_contents
              child.write(file_contents)
            else
              begin
                Dir.mkdir(child.file_path)
              rescue Errno::EEXIST
                raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, child)
              end
            end
            child
          end

          def dir?
            File.directory?(file_path)
          end

          def delete(recurse)
            FileSystemCache.instance.delete!(file_path)
            begin
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
          end

          def exists?
            File.exists?(file_path) && (parent.nil? || parent.can_have_child?(name, dir?))
          end

          def read
            File.open(file_path, "rb") { |f| f.read }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def write(content)
            File.open(file_path, "wb") do |file|
              file.write(content)
            end
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

          def compare_to(other)
            nil
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemCookbookEntry.new(child_name, self, nil, ruby_only, recursive)
          end

        end
      end
    end
  end
end
