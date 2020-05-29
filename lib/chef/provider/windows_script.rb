#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
  class Provider
    class WindowsScript < Chef::Provider::Script

      protected

      include Chef::Mixin::WindowsArchitectureHelper

      def target_architecture
        @target_architecture ||= if new_resource.architecture.nil?
                                   node_windows_architecture(run_context.node)
                                 else
                                   new_resource.architecture
                                 end
      end

      def basepath
        if forced_32bit_override_required?(run_context.node, target_architecture)
          wow64_directory
        else
          run_context.node["kernel"]["os_info"]["system_directory"]
        end
      end

      def with_wow64_redirection_disabled
        wow64_redirection_state = nil

        if wow64_architecture_override_required?(run_context.node, target_architecture)
          wow64_redirection_state = disable_wow64_file_redirection(run_context.node)
        end

        begin
          yield
        rescue
          raise
        ensure
          unless wow64_redirection_state.nil?
            restore_wow64_file_redirection(run_context.node, wow64_redirection_state)
          end
        end
      end

      public

      action :run do
        with_wow64_redirection_disabled do
          super()
        end
      end

      def script_file
        @script_file ||= Tempfile.open(["chef-script", script_extension])
      end

      def script_extension
        raise Chef::Exceptions::Override, "You must override #{__method__} in #{self}"
      end
    end
  end
end
