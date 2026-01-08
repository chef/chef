#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "script"
require_relative "../mixin/windows_architecture_helper"

class Chef
  class Resource
    class WindowsScript < Chef::Resource::Script
      include Chef::Mixin::WindowsArchitectureHelper

      # This is an abstract resource meant to be subclasses; thus no 'provides'

      set_guard_inherited_attributes(:architecture)

      def architecture(arg = nil)
        assert_architecture_compatible!(arg) unless arg.nil?
        result = set_or_return(
          :architecture,
          arg,
          kind_of: Symbol
        )
      end

      protected

      def assert_architecture_compatible!(desired_architecture)
        unless node_supports_windows_architecture?(node, desired_architecture)
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
            "cannot execute script with requested architecture '#{desired_architecture}' on a system with architecture '#{node_windows_architecture(node)}'"
        end
      end
    end
  end
end
