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

require "chef/exceptions"
require "chef/platform/query_helpers"
require "chef/win32/process" if Chef::Platform.windows?
require "chef/win32/system" if Chef::Platform.windows?

class Chef
  module Mixin
    module WindowsArchitectureHelper

      def node_windows_architecture(node)
        node[:kernel][:machine].to_sym
      end

      def wow64_architecture_override_required?(node, desired_architecture)
        desired_architecture == :x86_64 &&
          node_windows_architecture(node) == :x86_64 &&
          is_i386_process_on_x86_64_windows?
      end

      def forced_32bit_override_required?(node, desired_architecture)
        desired_architecture == :i386 &&
          node_windows_architecture(node) == :x86_64 &&
          !is_i386_process_on_x86_64_windows?
      end

      def wow64_directory
        Chef::ReservedNames::Win32::System.get_system_wow64_directory
      end

      def with_os_architecture(node, architecture: nil)
        node ||= begin
          os_arch = ENV["PROCESSOR_ARCHITEW6432"] ||
            ENV["PROCESSOR_ARCHITECTURE"]
          Hash.new.tap do |n|
            n[:kernel] = Hash.new
            n[:kernel][:machine] = os_arch == "AMD64" ? :x86_64 : :i386
          end
        end

        architecture ||= node_windows_architecture(node)

        wow64_redirection_state = nil

        if wow64_architecture_override_required?(node, architecture)
          wow64_redirection_state = disable_wow64_file_redirection(node)
        end

        begin
          yield
        ensure
          if wow64_redirection_state
            restore_wow64_file_redirection(node, wow64_redirection_state)
          end
        end
      end

      def node_supports_windows_architecture?(node, desired_architecture)
        assert_valid_windows_architecture!(desired_architecture)
        ( node_windows_architecture(node) == :x86_64 ) || ( desired_architecture == :i386 )
      end

      def valid_windows_architecture?(architecture)
        ( architecture == :x86_64 ) || ( architecture == :i386 )
      end

      def assert_valid_windows_architecture!(architecture)
        if !valid_windows_architecture?(architecture)
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
          "The specified architecture was not valid. It must be one of :i386 or :x86_64"
        end
      end

      def is_i386_process_on_x86_64_windows?
        if Chef::Platform.windows?
          Chef::ReservedNames::Win32::Process.is_wow64_process
        else
          false
        end
      end

      def disable_wow64_file_redirection( node )
        if ( node_windows_architecture(node) == :x86_64) && ::Chef::Platform.windows?
          Chef::ReservedNames::Win32::System.wow64_disable_wow64_fs_redirection
        end
      end

      def restore_wow64_file_redirection( node, original_redirection_state )
        if (node_windows_architecture(node) == :x86_64) && ::Chef::Platform.windows?
          Chef::ReservedNames::Win32::System.wow64_revert_wow64_fs_redirection(original_redirection_state)
        end
      end

    end
  end
end
