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
    class WindowsSystemScript < Chef::Resource::Script
      include Chef::Mixin::WindowsArchitectureHelper

      def architecture(arg=nil)
        assert_architecture_compatible!(arg) if ! arg.nil?
        result = set_or_return(
          :architecture,
          arg,
          :kind_of => Symbol
        )
      end

      def interpreter
        target_architecture = architecture.nil? ? node_windows_architecture(node) : architecture
        path_prefix = (target_architecture == :x86_64) ? INTERPRETER_64_BIT_PATH_PREFIX : INTERPRETER_32_BIT_PATH_PREFIX
        interpreter_path = "#{path_prefix}\\#{@interpreter_relative_path}"
      end
      
      INTERPRETER_64_BIT_PATH_PREFIX = "#{ENV['systemroot']}\\sysnative"
      INTERPRETER_32_BIT_PATH_PREFIX = "#{ENV['systemroot']}\\system32"

      def initialize(name, run_context=nil, resource_name, interpreter_relative_path)
        super(name, run_context)
        @resource_name = resource_name
        @interpreter_relative_path = interpreter_relative_path
        init_arch = node_windows_architecture(node)
      end

      protected

      def node
        run_context && run_context.node
      end
      
      def assert_architecture_compatible!(desired_architecture)
        if ! node_supports_windows_architecture?(node, desired_architecture)
          raise Chef::Exceptions::Win32ArchitectureIncorrect, "cannot execute script with requested architecture '#{desired_architecture.to_s}' on a system with architecture '#{node_windows_architecture(node)}'"
        end
      end
      
    end
  end
end
