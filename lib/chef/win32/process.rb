#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "chef/win32/api/process"
require "chef/win32/api/psapi"
require "chef/win32/error"
require "chef/win32/handle"
require "ffi"

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

      def self.is_wow64_process
        is_64_bit_process_result = FFI::MemoryPointer.new(:int)

        # The return value of IsWow64Process is nonzero value if the API call succeeds.
        # The result data are returned in the last parameter, not the return value.
        call_succeeded = IsWow64Process(GetCurrentProcess(), is_64_bit_process_result)

        # The result is nonzero if IsWow64Process's calling process, in the case here
        # this process, is running under WOW64, i.e. the result is nonzero if this
        # process is 32-bit (aka :i386).
        (call_succeeded != 0) && (is_64_bit_process_result.get_int(0) != 0)
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
