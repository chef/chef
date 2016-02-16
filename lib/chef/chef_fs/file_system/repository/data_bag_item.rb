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

require "chef/chef_fs/data_handler/data_bag_item_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class DataBagItem

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :file_path

          def initialize(name, parent)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils.join(parent.path, name)
            @data_handler = Chef::ChefFS::DataHandler::DataBagItemDataHandler.new
            @file_path = "#{parent.file_path}/#{name}"
          end

          # Public API callied by chef_fs/file_system
          def dir?
            false
          end

          def name_valid?
            !name.start_with?(".") && name.end_with?(".json")
          end

          def fs_entry_valid?
            name_valid? && File.file?(file_path)
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
              File.open(file_path, "rb") { |f| f.read }
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

          def compare_to(other)
            nil
          end
        end

      end
    end
  end
end
