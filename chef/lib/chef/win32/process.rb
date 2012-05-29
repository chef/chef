#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright 2011 Opscode, Inc.
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

require 'chef/win32/api/process'
require 'chef/win32/api/psapi'
require 'chef/win32/error'
require 'chef/win32/handle'
require 'ffi'

class Chef
  module ReservedNames::Win32
    class Process
      include Chef::ReservedNames::Win32::API::Process
      extend Chef::ReservedNames::Win32::API::Process
      include Chef::ReservedNames::Win32::API::PSAPI
      extend Chef::ReservedNames::Win32::API::PSAPI

      def initialize(handle)
        @handle = handle
      end

      attr_reader :handle

      def id
        Process.get_process_id(handle)
      end

      def handle_count
        Process.get_process_handle_count(handle)
      end

      def memory_info
        Process.get_process_memory_info(handle)
      end

      def self.get_current_process
        Process.new(Handle.new(GetCurrentProcess()))
      end

      def self.get_process_handle_count(handle)
        handle_count = FFI::MemoryPointer.new :uint32
        unless GetProcessHandleCount(handle.handle, handle_count)
          Chef::ReservedNames::Win32::Error.raise!
        end
        handle_count.read_uint32
      end

      def self.get_process_id(handle)
        # Must have PROCESS_QUERY_INFORMATION or PROCESS_QUERY_LIMITED_INFORMATION rights
        result = GetProcessId(handle.handle)
        if result == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        result
      end

        # Must have PROCESS_QUERY_INFORMATION or PROCESS_QUERY_LIMITED_INFORMATION rights,
        # AND the PROCESS_VM_READ right
      def self.get_process_memory_info(handle)
        memory_info = PROCESS_MEMORY_COUNTERS.new
        unless GetProcessMemoryInfo(handle.handle, memory_info, memory_info.size)
          Chef::ReservedNames::Win32::Error.raise!
        end
        memory_info
      end

    end
  end
end
