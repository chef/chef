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

require 'chef/resource'
require 'chef/provider/execute'

class Chef
  class Resource
    class Execute < Chef::Resource
      provides :execute

      identity_attr :command

      # The ResourceGuardInterpreter wraps a resource's guards in another resource.  That inner resource
      # needs to behave differently during (for example) why_run mode, so we flag it here. For why_run mode
      # we still want to execute the guard resource even if we are not executing the wrapping resource.
      # Only execute resources (and subclasses) can be guard interpreters.
      attr_accessor :is_guard_interpreter

      def initialize(name, run_context=nil)
        super
        @resource_name = :execute
        @command = name
        @backup = 5
        @action = "run"
        @creates = nil
        @cwd = nil
        @environment = nil
        @group = nil
        @path = nil
        @returns = 0
        @timeout = nil
        @user = nil
        @allowed_actions.push(:run)
        @umask = nil
        @default_guard_interpreter = :execute
        @is_guard_interpreter = false
      end

      def umask(arg=nil)
        set_or_return(
          :umask,
          arg,
          :kind_of => [ String, Integer ]
        )
      end

      def command(arg=nil)
        set_or_return(
          :command,
          arg,
          :kind_of => [ String, Array ]
        )
      end

      def creates(arg=nil)
        set_or_return(
          :creates,
          arg,
          :kind_of => [ String ]
        )
      end

      def cwd(arg=nil)
        set_or_return(
          :cwd,
          arg,
          :kind_of => [ String ]
        )
      end

      def environment(arg=nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end

      alias :env :environment

      def group(arg=nil)
        set_or_return(
          :group,
          arg,
          :kind_of => [ String, Integer ]
        )
      end

      def path(arg=nil)
        Chef::Log.warn "'path' attribute of 'execute' is not used by any provider in Chef 11 and Chef 12. Use 'environment' attribute to configure 'PATH'. This attribute will be removed in Chef 13."

        set_or_return(
          :path,
          arg,
          :kind_of => [ Array ]
        )
      end

      def returns(arg=nil)
        set_or_return(
          :returns,
          arg,
          :kind_of => [ Integer, Array ]
        )
      end

      def timeout(arg=nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [ Integer, Float ]
        )
      end

      def user(arg=nil)
        set_or_return(
          :user,
          arg,
          :kind_of => [ String, Integer ]
        )
      end

      def self.set_guard_inherited_attributes(*inherited_attributes)
        @class_inherited_attributes = inherited_attributes
      end

      def self.guard_inherited_attributes(*inherited_attributes)
        # Similar to patterns elsewhere, return attributes from this
        # class and superclasses as a form of inheritance
        ancestor_attributes = []

        if superclass.respond_to?(:guard_inherited_attributes)
          ancestor_attributes = superclass.guard_inherited_attributes
        end

        ancestor_attributes.concat(@class_inherited_attributes ? @class_inherited_attributes : []).uniq
      end

      set_guard_inherited_attributes(
        :cwd,
        :environment,
        :group,
        :user,
        :umask
      )

    end
  end
end
