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

require 'chef/chef_fs/file_system/base_fs_dir'
require 'chef/chef_fs/file_system/rest_list_entry'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/chef_fs/data_handler/node_data_handler'

class Chef
  module ChefFS
    module FileSystem
      class NodesDir < RestListDir
        def initialize(parent)
          super("nodes", parent, nil, Chef::ChefFS::DataHandler::NodeDataHandler.new)
        end

        # Override to respond to environment
        def chef_collection
          rest.get_rest(env_api_path)
        end

        def env_api_path
          environment ? "environments/#{environment}/#{api_path}" : api_path
        end
      end
    end
  end
end
