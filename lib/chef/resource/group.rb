#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

class Chef
  class Resource
    class Group < Chef::Resource
      state_attrs :members

      target_mode support: :full,
        platforms: %i{aix bsd linux macos_x solaris}

      description "Use the **group** resource to manage a local group."

      examples <<~EXAMPLES
      The following examples demonstrate various approaches for using the **group** resource in recipes:

      Append users to groups:

      ```ruby
      group 'www-data' do
        action :modify
        members 'maintenance'
        append true
      end
      ```

      Add a user to group on the Windows platform:

      ```ruby
      group 'Administrators' do
        members ['domain\\foo']
        append true
        action :modify
      end
      ```
      EXAMPLES

      provides :group, target_mode: true

      allowed_actions :create, :remove, :modify, :manage
      default_action :create

      property :group_name, String,
        name_property: true,
        description: "The name of the group."

      property :gid, [ String, Integer ],
        description: "The identifier for the group."

      property :members, [String, Array], default: [],
               coerce: proc { |arg| arg.is_a?(Array) ? arg.uniq : arg.split(/\s*,\s*/) },
               description: "Which users should be set or appended to a group. When more than one group member is identified, the list of members should be an array: `members ['user1', 'user2']`."

      property :excluded_members, [String, Array], default: [],
               coerce: proc { |arg| arg.is_a?(Array) ? arg.uniq : arg.split(/\s*,\s*/) },
               description: "Remove users from a group. May only be used when `append` is set to `true`."

      property :append, [ TrueClass, FalseClass ], default: false,
               description: "How members should be appended and/or removed from a group. When true, `members` are appended and `excluded_members` are removed. When `false`, group members are reset to the value of the `members` property."

      property :system, [ TrueClass, FalseClass ], default: false,
               description: "Set to `true` if the group belongs to a system group."

      property :non_unique, [ TrueClass, FalseClass ], default: false,
               description: "Allow gid duplication. May only be used with the `Groupadd` user resource provider."

      property :comment, String,
        introduced: "14.9",
        description: "Specifies a comment to associate with the local group."

      alias_method :users, :members
    end
  end
end
