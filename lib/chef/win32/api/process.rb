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

require 'chef/win32/api'

class Chef
  module ReservedNames::Win32
    module API
      module Process
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib 'kernel32'

        safe_attach_function :GetCurrentProcess, [], :HANDLE
        safe_attach_function :GetProcessHandleCount, [ :HANDLE, :LPDWORD ], :BOOL
        safe_attach_function :GetProcessId, [ :HANDLE ], :DWORD
        safe_attach_function :CloseHandle, [ :HANDLE ], :BOOL
        safe_attach_function :IsWow64Process, [ :HANDLE, :PBOOL ], :BOOL

      end
    end
  end
end
