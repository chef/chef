#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../base_fs_dir"
require_relative "rest_list_entry"
require_relative "../exceptions"
require_relative "../../data_handler/node_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class NodesDir < RestListDir
          # Identical to RestListDir.children, except supports environments
          def children
            @children ||= root.get_json(env_api_path).keys.sort.map do |key|
              make_child_entry(key, true)
            end
          rescue Timeout::Error => e
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "Timeout retrieving children: #{e}")
          rescue Net::HTTPClientException => e
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            else
              raise Chef::ChefFS::FileSystem::OperationFailedError.new(:children, self, e, "HTTP error retrieving children: #{e}")
            end
          end

          def env_api_path
            environment ? "environments/#{environment}/#{api_path}" : api_path
          end
        end
      end
    end
  end
end
