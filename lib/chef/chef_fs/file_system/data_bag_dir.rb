#
# Author:: John Keiser (<jkeiser@opscode.com>)
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

require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/chef_fs/file_system/must_delete_recursively_error'
require 'chef/chef_fs/data_handler/data_bag_item_data_handler'

class Chef
  module ChefFS
    module FileSystem
      class DataBagDir < RestListDir
        def initialize(name, parent, exists = nil)
          super(name, parent, nil, Chef::ChefFS::DataHandler::DataBagItemDataHandler.new)
          @exists = nil
        end

        def dir?
          exists?
        end

        def read
          # This will only be called if dir? is false, which means exists? is false.
          raise Chef::ChefFS::FileSystem::NotFoundError.new(self)
        end

        def exists?
          if @exists.nil?
            @exists = parent.children.any? { |child| child.name == name }
          end
          @exists
        end

        def delete(recurse)
          if !recurse
            raise NotFoundError.new(self) if !exists?
            raise MustDeleteRecursivelyError.new(self), "#{path_for_printing} must be deleted recursively"
          end
          begin
            rest.delete_rest(api_path)
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e), "Timeout deleting: #{e}"
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:delete, self, e), "HTTP error deleting: #{e}"
            end
          end
        end
      end
    end
  end
end
