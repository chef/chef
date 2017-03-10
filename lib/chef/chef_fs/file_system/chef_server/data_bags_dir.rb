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

require "chef/chef_fs/file_system/chef_server/rest_list_dir"
require "chef/chef_fs/file_system/chef_server/data_bag_dir"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class DataBagsDir < RestListDir
          def make_child_entry(name, exists = false)
            result = @children.find { |child| child.name == name } if @children
            result || DataBagDir.new(name, self, exists)
          end

          def children
            @children ||= root.get_json(api_path).keys.sort.map { |entry| make_child_entry(entry, true) }
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "Timeout getting children: #{e}")
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "HTTP error getting children: #{e}")
            end
          end

          def can_have_child?(name, is_dir)
            is_dir
          end

          def create_child(name, file_contents)
            begin
              rest.post(api_path, { "name" => name })
            rescue Timeout::Error => e
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e, "Timeout creating child '#{name}': #{e}")
            rescue Net::HTTPServerException => e
              if e.response.code == "409"
                raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, self, e, "Cannot create #{name} under #{path}: already exists")
              else
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:create_child, self, e, "HTTP error creating child '#{name}': #{e}")
              end
            end
            @children = nil
            DataBagDir.new(name, self, true)
          end
        end
      end
    end
  end
end
