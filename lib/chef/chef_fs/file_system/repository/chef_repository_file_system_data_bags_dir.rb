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

        # Original Class/superclass
        #class ChefRepositoryFileSystemDataBagsDir < ChefRepositoryFileSystemEntry

        # With ChefRepositoryFileSystemEntry inlined:
        class ChefRepositoryFileSystemDataBagsDir < FileSystemEntry

          # Original
          ## def initialize(name, parent, path = nil)
          ##   super(name, parent, path, Chef::ChefFS::DataHandler::DataBagItemDataHandler.new)
          ## end

          # ChefRepositoryFileSystemEntry#initialize
          ## def initialize(name, parent, file_path = nil, data_handler = nil)
          ##   super(name, parent, file_path)
          ##   @data_handler = data_handler
          ## end

          # inlined initialize
          def initialize(name, parent, path = nil)
            super(name, parent, path)
            @data_handler = Chef::ChefFS::DataHandler::DataBagItemDataHandler.new
          end


          ##############################
          # Original
          ##############################

          def can_have_child?(name, is_dir)
            is_dir && !name.start_with?(".")
          end

          ##############################
          # Inlined
          ##############################

          def write_pretty_json=(value)
            @write_pretty_json = value
          end

          def write_pretty_json
            @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          end

          def data_handler
            @data_handler || parent.data_handler
          end

          def chef_object
            begin
              return data_handler.chef_object(Chef::JSONCompat.parse(read))
            rescue
              Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
            end
            nil
          end

          # Overridden by subclass
          ## def can_have_child?(name, is_dir)
          ##   !is_dir && name[-5..-1] == ".json"
          ## end

          def write(file_contents)
            if file_contents && write_pretty_json && name[-5..-1] == ".json"
              file_contents = minimize(file_contents, self)
            end
            super(file_contents)
          end

          def minimize(file_contents, entry)
            object = Chef::JSONCompat.parse(file_contents)
            object = data_handler.normalize(object, entry)
            object = data_handler.minimize(object, entry)
            Chef::JSONCompat.to_json_pretty(object)
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemEntry.new(child_name, self)
          end
        end
      end
    end
  end
end
