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

      identity_attr :group_name

      state_attrs :members

      allowed_actions :create, :remove, :modify, :manage
      default_action :create

      def initialize(name, run_context = nil)
        super
        @group_name = name
        @gid = nil
        @members = []
        @excluded_members = []
        @append = false
        @non_unique = false
      end

      def group_name(arg = nil)
        set_or_return(
          :group_name,
          arg,
          :kind_of => [ String ]
        )
      end

      def gid(arg = nil)
        set_or_return(
          :gid,
          arg,
          :kind_of => [ String, Integer ]
        )
      end

      def members(arg = nil)
        converted_members = arg.is_a?(String) ? arg.split(",") : arg
        set_or_return(
          :members,
          converted_members,
          :kind_of => [ Array ]
        )
      end

      alias_method :users, :members

      def excluded_members(arg = nil)
        converted_members = arg.is_a?(String) ? arg.split(",") : arg
        set_or_return(
          :excluded_members,
          converted_members,
          :kind_of => [ Array ]
        )
      end

      def append(arg = nil)
        set_or_return(
          :append,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def system(arg = nil)
        set_or_return(
          :system,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def non_unique(arg = nil)
        set_or_return(
          :non_unique,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end
    end
  end
end
