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

require 'chef/provider/script'
require 'chef/mixin/windows_architecture_helper'

class Chef
  class Provider
    class WindowsScript < Chef::Provider::Script

      protected

      include Chef::Mixin::WindowsArchitectureHelper

      def initialize( new_resource, run_context, script_extension='')
        super( new_resource, run_context )
        @script_extension = script_extension

        target_architecture = new_resource.architecture.nil? ?
          node_windows_architecture(run_context.node) : new_resource.architecture

        @is_wow64 = wow64_architecture_override_required?(run_context.node, target_architecture)

        if ( target_architecture == :i386 ) && ! is_i386_process_on_x86_64_windows?
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
          "Support for the i386 architecture from a 64-bit Ruby runtime is not yet implemented"
        end
      end

      public

      def action_run
        wow64_redirection_state = nil

        if @is_wow64
          wow64_redirection_state = disable_wow64_file_redirection(@run_context.node)
        end

        begin
          super
        rescue
          raise
        ensure
          if ! wow64_redirection_state.nil?
            restore_wow64_file_redirection(@run_context.node, wow64_redirection_state)
          end
        end
      end

      def script_file
        base_script_name = "chef-script"
        temp_file_arguments = [ base_script_name, @script_extension ]

        @script_file ||= Tempfile.open(temp_file_arguments)
      end
    end
  end
end
