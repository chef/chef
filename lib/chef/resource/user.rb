#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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
      identity_attr :username

      state_attrs :uid, :gid, :home

      default_action :create
      allowed_actions :create, :remove, :modify, :manage, :lock, :unlock

      property :username, String, name_property: true
      property :comment, String
      property :uid, [ String, Integer ]
      property :gid, [ String, Integer ]
      property :home, String
      property :shell, String
      property :password, String
      property :salt, String
      property :iterations, [Integer, nil], default: 27855
      property :system, [ TrueClass, FalseClass ], default: false
      property :manage_home, [ TrueClass, FalseClass ], default: false
      property :force, [ TrueClass, FalseClass ], default: false
      property :non_unique, [ TrueClass, FalseClass ], default: false

      alias_method :group, :gid
    end
  end
end
