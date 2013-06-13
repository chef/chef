#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/chef_fs/file_system/chef_repository_file_system_entry'
require 'chef/chef_fs/file_system/chef_repository_file_system_cookbooks_dir'

class Chef
  module ChefFS
    module FileSystem
      class ChefRepositoryFileSystemCookbookEntry < ChefRepositoryFileSystemEntry
        def initialize(name, parent, file_path = nil, ruby_only = false, recursive = false)
          super(name, parent, file_path)
          @ruby_only = ruby_only
          @recursive = recursive
        end

        attr_reader :ruby_only
        attr_reader :recursive

        def children
          Dir.entries(file_path).sort.
              select { |child_name| can_have_child?(child_name, File.directory?(File.join(file_path, child_name))) }.
              map { |child_name| ChefRepositoryFileSystemCookbookEntry.new(child_name, self, nil, ruby_only, recursive) }.
              select { |entry| !(entry.dir? && entry.children.size == 0) }
        end

        def can_have_child?(name, is_dir)
          if is_dir
            return recursive && name != '.' && name != '..'
          elsif ruby_only
            return false if name[-3..-1] != '.rb'
          end

          # Check chefignore
          ignorer = parent
          begin
            if ignorer.is_a?(ChefRepositoryFileSystemCookbooksDir)
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
          end while ignorer

          true
        end
      end
    end
  end
end
