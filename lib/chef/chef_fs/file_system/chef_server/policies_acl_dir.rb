#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require "chef/chef_fs/file_system/chef_server/acl_dir"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class PoliciesAclDir < AclDir
          # Policies are presented like /NAME-VERSION.json. But there is only
          # one ACL for a given NAME. So we find out the unique policy names,
          # and make one acls/policies/NAME.json for each one.
          def children
            if @children.nil?
              names = parent.parent.child(name).children.map { |child| "#{child.policy_name}.json" }
              @children = names.uniq.map { |name| make_child_entry(name, true) }
            end
            @children
          end
        end
      end
    end
  end
end
