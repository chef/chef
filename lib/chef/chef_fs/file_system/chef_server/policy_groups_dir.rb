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

require "chef/chef_fs/file_system/base_fs_dir"
require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/file_system/exceptions"
require "chef/chef_fs/file_system/chef_server/policy_group_entry"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class PolicyGroupsDir < RestListDir
          def make_child_entry(name, exists = nil)
            PolicyGroupEntry.new(name, self, exists)
          end

          def create_child(name, file_contents)
            entry = make_child_entry(name, true)
            entry.write(file_contents)
            @children = nil
            entry
          end
        end
      end
    end
  end
end
