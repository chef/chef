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

class Chef
  module ChefFS
    module FileSystem
      class NodesDir < RestListDir
        def initialize(parent)
          super("nodes", parent)
        end

        # Override children to respond to environment
        # TODO let's not do this mmkay
        def children
          @children ||= begin
            env_api_path = environment ? "environments/#{environment}/#{api_path}" : api_path
            rest.get_rest(env_api_path).keys.sort.map { |key| RestListEntry.new("#{key}.json", self, true) }
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
            else
              raise
            end
          end
      end
      end
    end
  end
end
