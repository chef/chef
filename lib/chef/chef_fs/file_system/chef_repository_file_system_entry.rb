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
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/json_compat'

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

        def write_pretty_json
          root.write_pretty_json
        end

        def data_handler
          @data_handler || parent.data_handler
        end

        def chef_object
          begin
            return data_handler.chef_object(Chef::JSONCompat.parse(read, :create_additions => false))
          rescue
            Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
          end
          nil
        end

        def can_have_child?(name, is_dir)
          !is_dir && name[-5..-1] == '.json'
        end

        def write(file_contents)
          if file_contents && write_pretty_json && name[-5..-1] == '.json'
            file_contents = minimize(file_contents, self)
          end
          super(file_contents)
        end

        def minimize(file_contents, entry)
          object = JSONCompat.from_json(file_contents, :create_additions => false)
          object = data_handler.normalize(object, entry)
          object = data_handler.minimize(object, entry)
          JSONCompat.to_json_pretty(object)
        end

        def children
          # Except cookbooks and data bag dirs, all things must be json files
          begin
            Dir.entries(file_path).sort.
                select { |child_name| can_have_child?(child_name, File.directory?(File.join(file_path, child_name))) }.
                map { |child_name| make_child(child_name) }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end
        end

        protected

        def make_child(child_name)
          ChefRepositoryFileSystemEntry.new(child_name, self)
        end
      end
    end
  end
end
