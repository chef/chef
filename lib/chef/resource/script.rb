#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/resource/execute'
require 'chef/provider/script'

class Chef
  class Resource
    class Script < Chef::Resource::Execute
      provides :script

      # Chef-13: go back to using :name as the identity attr
      identity_attr :command

      def initialize(name, run_context=nil)
        super
        @resource_name = :script
        # Chef-13: the command variable should be initialized to nil
        @command = name
        @code = nil
        @interpreter = nil
        @flags = nil
        @default_guard_interpreter = :default
      end

      def command(arg=nil)
        unless arg.nil?
          # Chef-13: change this to raise if the user is trying to set a value here
          Chef::Log.warn "Specifying command attribute on a script resource is a coding error, use the 'code' attribute, or the execute resource"
          Chef::Log.warn "This attribute is deprecated and must be fixed or this code will fail on Chef-13"
        end
        super
      end

      def code(arg=nil)
        set_or_return(
          :code,
          arg,
          :kind_of => [ String ]
        )
      end

      def interpreter(arg=nil)
        set_or_return(
          :interpreter,
          arg,
          :kind_of => [ String ]
        )
      end

      def flags(arg=nil)
        set_or_return(
          :flags,
          arg,
          :kind_of => [ String ]
        )
      end

    end
  end
end
