#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/resource"

class Chef
  class Resource
    # Use the user resource to add users, update existing users, remove users, and to lock/unlock user passwords.
    class User < Chef::Resource
      resource_name :user_resource_abstract_base_class # this prevents magickal class name DSL wiring

      default_action :create
      allowed_actions :create, :remove, :modify, :manage, :lock, :unlock

      property :username, String,
                description: "",
                name_property: true, identity: true

      property :comment, String,
                description: ""

      property :home, String,
                description: ""

      property :salt, String,
                description: "",
                desired_state: false

      property :shell, String,
                description: ""

      property :password, String,
                description: "",
                desired_state: false

      property :iterations, Integer,
                description: "",
                default: 27855, desired_state: false

      property :non_unique, [ TrueClass, FalseClass ],
                description: "",
                default: false, desired_state: false

      property :manage_home, [ TrueClass, FalseClass ],
                description: "",
                default: false, desired_state: false

      property :force, [ TrueClass, FalseClass ],
                description: "",
                default: false, desired_state: false

      property :system, [ TrueClass, FalseClass ],
                description: "",
                default: false

      property :uid, [ String, Integer, NilClass ], # nil for backwards compat
                description: ""

      property :gid, [ String, Integer, NilClass ], # nil for backwards compat
                description: ""

      alias_method :group, :gid
    end
  end
end
