#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Author:: Ho-Sheng Hsiao (<hosh@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system/file_system_entry'
require 'chef/cookbook/cookbook_version_loader'

class Chef
  module ChefFS
    module FileSystem
      # ChefRepositoryFileSystemEntry works just like FileSystemEntry,
      # except can inflate Chef objects
      class ChefRepositoryFileSystemEntry < FileSystemEntry
        def initialize(name, parent, file_path = nil, data_handler = nil)
          super(name, parent, file_path)
          @data_handler = data_handler
        end

        def chefignore
          nil
        end

        def ignore_empty_directories?
          parent.ignore_empty_directories?
        end

        def data_handler
          @data_handler || parent.data_handler
        end

        def chef_object
          begin
            if parent.path == '/cookbooks'
              loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
              # We need the canonical cookbook name if we are using versioned cookbooks, but we don't
              # want to spend a lot of time adding code to the main Chef libraries
              if Chef::Config[:versioned_cookbooks]

                _canonical_name = canonical_cookbook_name(File.basename(file_path))
                fail "When versioned_cookbooks mode is on, cookbook #{file_path} must match format <cookbook_name>-x.y.z"  unless _canonical_name

                # KLUDGE: We shouldn't have to use instance_variable_set
                loader.instance_variable_set(:@cookbook_name, _canonical_name)
              end

              loader.load_cookbooks
              return loader.cookbook_version
            end

            # Otherwise, inflate the file using the chosen JSON class (if any)
            return data_handler.chef_object(JSON.parse(read, :create_additions => false))
          rescue
            Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
          end
          nil
        end

        # Exposed as a class method so that it can be used elsewhere
        def self.canonical_cookbook_name(entry_name)
          name_match = Chef::ChefFS::FileSystem::CookbookDir::VALID_VERSIONED_COOKBOOK_NAME.match(entry_name)
          return nil if name_match.nil?
          return name_match[1]
        end

        def canonical_cookbook_name(entry_name)
          self.class.canonical_cookbook_name(entry_name)
        end

        def children
          @children ||=
            Dir.entries(file_path).
                select { |entry| entry != '.' && entry != '..' }.
                map { |entry| ChefRepositoryFileSystemEntry.new(entry, self) }.
                select { |entry| !ignored?(entry) }
        end

        private

        def ignored?(child_entry)
          if child_entry.dir?
            # empty cookbooks and cookbook directories are ignored
            if ignore_empty_directories? && child_entry.children.size == 0
              return true
            end
          else
            ignorer = parent
            begin
              if ignorer.chefignore
                # Grab the path from entry to child
                path_to_child = child_entry.name
                child = self
                while child.parent != ignorer
                  path_to_child = PathUtils.join(child.name, path_to_child)
                  child = child.parent
                end
                # Check whether that relative path is ignored
                return ignorer.chefignore.ignored?(path_to_child)
              end
              ignorer = ignorer.parent
            end while ignorer
          end
        end

      end
    end
  end
end
