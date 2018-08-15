#
# Author:: Salim Alam (<salam@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

require "chef/win32/api/system"
require "chef/win32/error"
require "ffi"

class Chef
  module ReservedNames::Win32
    class System
      include Chef::ReservedNames::Win32::API::System
      extend Chef::ReservedNames::Win32::API::System

      def self.get_system_wow64_directory
        ptr = FFI::MemoryPointer.new(:char, 255, true)
        succeeded = GetSystemWow64DirectoryA(ptr, 255)

        if succeeded == 0
          raise Win32APIError, "Failed to get Wow64 system directory"
        end

        ptr.read_string.strip
      end

      def self.wow64_disable_wow64_fs_redirection
        original_redirection_state = FFI::MemoryPointer.new(:pointer)

        succeeded = Wow64DisableWow64FsRedirection(original_redirection_state)

        if succeeded == 0
          raise Win32APIError, "Failed to disable Wow64 file redirection"
        end

        original_redirection_state
      end

      def self.wow64_revert_wow64_fs_redirection(original_redirection_state)
        succeeded = Wow64RevertWow64FsRedirection(original_redirection_state)

        if succeeded == 0
          raise Win32APIError, "Failed to revert Wow64 file redirection"
        end
      end

    end
  end
end
