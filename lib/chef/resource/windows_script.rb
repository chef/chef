#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/resource/script'
require 'chef/mixin/windows_architecture_helper'

class Chef
  class Resource
    class WindowsScript < Chef::Resource::Script
      # This is an abstract resource meant to be subclasses; thus no 'provides'

      set_guard_inherited_attributes(:architecture)

      protected

      def initialize(name, run_context, resource_name, interpreter_command)
        super(name, run_context)
        @interpreter = interpreter_command
        @resource_name = resource_name
        @default_guard_interpreter = resource_name
      end

      include Chef::Mixin::WindowsArchitectureHelper

      public

      def architecture(arg=nil)
        assert_architecture_compatible!(arg) if ! arg.nil?
        result = set_or_return(
          :architecture,
          arg,
          :kind_of => Symbol
        )
      end

      protected

      def assert_architecture_compatible!(desired_architecture)
        if ! node_supports_windows_architecture?(node, desired_architecture)
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
          "cannot execute script with requested architecture '#{desired_architecture.to_s}' on a system with architecture '#{node_windows_architecture(node)}'"
        end
      end
    end
  end
end
