#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

require "chef/resource"
require "chef/provider/directory"
require "chef/mixin/securable"

class Chef
  class Resource
    class Directory < Chef::Resource

      identity_attr :path

      state_attrs :group, :mode, :owner

      include Chef::Mixin::Securable

      default_action :create
      allowed_actions :create, :delete

      def initialize(name, run_context = nil)
        super
        @path = name
        @recursive = false
      end

      def recursive(arg = nil)
        set_or_return(
          :recursive,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def path(arg = nil)
        set_or_return(
          :path,
          arg,
          :kind_of => String
        )
      end

    end
  end
end
