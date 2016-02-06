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
require "chef/chef_fs/file_system/repository/chef_repository_file_system_cookbooks_dir"
require "chef/chef_fs/file_system/not_found_error"

class Chef
  module ChefFS
    module FileSystem
      module Repository
        # Original
        #class ChefRepositoryFileSystemCookbookEntry < ChefRepositoryFileSystemEntry

        # With ChefRepositoryFileSystemEntry inlined
        class ChefRepositoryFileSystemCookbookEntry < FileSystemEntry

          # Original initialize
          ##  def initialize(name, parent, file_path = nil, ruby_only = false, recursive = false)
          ##    super(name, parent, file_path)
          ##    @ruby_only = ruby_only
          ##    @recursive = recursive
          ##  end

          # ChefRepositoryFileSystemEntry#initialize
          ##  def initialize(name, parent, file_path = nil, data_handler = nil)
          ##    super(name, parent, file_path)
          ##    @data_handler = data_handler
          ##  end

          # inlined initialize
          def initialize(name, parent, file_path = nil, ruby_only = false, recursive = false)
            super(name, parent, file_path)
            @ruby_only = ruby_only
            @recursive = recursive
            @data_handler = nil
          end

          attr_reader :ruby_only
          attr_reader :recursive

          def children
            super.select { |entry| !(entry.dir? && entry.children.size == 0 ) }
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
              break unless ignorer
            end

            true
          end

          def write_pretty_json
            false
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemCookbookEntry.new(child_name, self, nil, ruby_only, recursive)
          end

          public

          ##############################
          # inlined from ChefRepositoryFileSystemEntry
          ##############################

          # overriden by superclass
          ##  def write_pretty_json
          ##    @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          ##  end

          # unused?
          ##  def data_handler
          ##    @data_handler || parent.data_handler
          ##  end

          # unused?
          ##  def chef_object
          ##    begin
          ##      return data_handler.chef_object(Chef::JSONCompat.parse(read))
          ##    rescue
          ##      Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
          ##    end
          ##    nil
          ##  end

          # overriden by superclass
          ##  def can_have_child?(name, is_dir)
          ##    !is_dir && name[-5..-1] == ".json"
          ##  end

          # unused?
          ##  def write(file_contents)
          ##    if file_contents && write_pretty_json && name[-5..-1] == ".json"
          ##      file_contents = minimize(file_contents, self)
          ##    end
          ##    super(file_contents)
          ##  end

          # unused?
          ##  def minimize(file_contents, entry)
          ##    object = Chef::JSONCompat.parse(file_contents)
          ##    object = data_handler.normalize(object, entry)
          ##    object = data_handler.minimize(object, entry)
          ##    Chef::JSONCompat.to_json_pretty(object)
          ##  end

          # overriden by superclass
          ## protected

          ## def make_child_entry(child_name)
          ##   ChefRepositoryFileSystemEntry.new(child_name, self)
          ## end
        end
      end
    end
  end
end
