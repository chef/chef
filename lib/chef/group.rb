#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "org"

class Chef
  class Group

    def group(groupname)
      @group ||= {}
      @group[groupname] ||= chef_rest.get_rest "organizations/#{name}/groups/#{groupname}"
    end

    def user_member_of_group?(username, groupname)
      group = group(groupname)
      group["actors"].include? username
    end

    def add_user_to_group(groupname, username)
      group = group(groupname)
      body_hash = {
        groupname: "#{groupname}",
        actors: {
          "users" => group["actors"].concat([username]),
          "groups" => group["groups"],
        },
      }
      chef_rest.put_rest "organizations/#{name}/groups/#{groupname}", body_hash
    end

    def remove_user_from_group(groupname, username)
      group = group(groupname)
      group["actors"].delete(username)
      body_hash = {
        groupname: "#{groupname}",
        actors: {
          "users" => group["actors"],
          "groups" => group["groups"],
        },
      }
      chef_rest.put_rest "organizations/#{name}/groups/#{groupname}", body_hash
    end

    def actor_delete_would_leave_admins_empty?
      admins = group("admins")
      if admins["groups"].empty?
        # exclude 'pivotal' but don't mutate the group since we're caching it
        if admins["actors"].include? "pivotal"
          admins["actors"].length <= 2
        else
          admins["actors"].length <= 1
        end
      else
        # We don't check recursively. If the admins group contains a group,
        # and the user is the only member of that group,
        # we'll still turn up a 'safe to delete'.
        false
      end
    end
  end
end
