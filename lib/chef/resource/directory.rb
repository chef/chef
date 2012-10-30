#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011 Opscode, Inc.
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

require 'chef/resource'
require 'chef/provider/directory'
require 'chef/mixin/securable'

class Chef
  class Resource
    class Directory < Chef::Resource
      
      identity_attr :path

      state_attrs :group, :mode, :owner
      
      include Chef::Mixin::Securable

      provides :directory, :on_platforms => :all

      def initialize(name, run_context=nil)
        super
        @resource_name = :directory
        @path = name
        @action = :create
        @recursive = false
        @allowed_actions.push(:create, :delete)
        @provider = Chef::Provider::Directory
      end

      def recursive(arg=nil)
        set_or_return(
          :recursive,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def path(arg=nil)
        set_or_return(
          :path,
          arg,
          :kind_of => String
        )
      end

    end
  end
end
