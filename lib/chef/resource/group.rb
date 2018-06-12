#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
      description "Use the group resource to manage a local group."

      allowed_actions :create, :remove, :modify, :manage
      default_action :create

      property :group_name, String, name_property: true, identity: true
      property :gid, [ String, Integer ]
      property :members, [Array, String], default: lazy { [] }, coerce: proc { |arg| arg.is_a?(String) ? arg.split(/\s*,\s*/) : arg }
      property :excluded_members, [Array, String], default: lazy { [] }, coerce: proc { |arg| arg.is_a?(String) ? arg.split(/\s*,\s*/) : arg }
      property :append, [ TrueClass, FalseClass ], default: false
      property :system, [ TrueClass, FalseClass ], default: false
      property :non_unique, [ TrueClass, FalseClass ], default: false

      alias_method :users, :members
    end
  end
end
