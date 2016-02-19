#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/platform/query_helpers"
require "chef/resource/script"
require "chef/mixin/windows_architecture_helper"

class Chef
  class Resource
    class WindowsScript < Chef::Resource::Script
      # This is an abstract resource meant to be subclasses; thus no 'provides'

      set_guard_inherited_attributes(:architecture)

      protected

      def initialize(name, run_context, resource_name, interpreter_command)
        super(name, run_context)
        @interpreter = interpreter_command
        @resource_name = resource_name if resource_name
        @default_guard_interpreter = self.resource_name
      end

      include Chef::Mixin::WindowsArchitectureHelper

      public

      def architecture(arg = nil)
        assert_architecture_compatible!(arg) if ! arg.nil?
        result = set_or_return(
          :architecture,
          arg,
          :kind_of => Symbol
        )
      end

      protected

      def assert_architecture_compatible!(desired_architecture)
        if desired_architecture == :i386 && Chef::Platform.windows_nano_server?
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
            "cannot execute script with requested architecture 'i386' on Windows Nano Server"
        elsif ! node_supports_windows_architecture?(node, desired_architecture)
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
            "cannot execute script with requested architecture '#{desired_architecture}' on a system with architecture '#{node_windows_architecture(node)}'"
        end
      end
    end
  end
end
