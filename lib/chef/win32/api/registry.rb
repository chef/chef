#
# Author:: Salim Alam (<salam@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/win32/api"

class Chef
  module ReservedNames::Win32
    module API
      module Registry
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib "advapi32"

        # LONG WINAPI RegDeleteKeyEx(
        #   _In_       HKEY    hKey,
        #   _In_       LPCTSTR lpSubKey,
        #   _In_       REGSAM  samDesired,
        #   _Reserved_ DWORD   Reserved
        # );
        safe_attach_function :RegDeleteKeyExW, [ :HKEY, :LPCTSTR, :LONG, :DWORD ], :LONG
        safe_attach_function :RegDeleteKeyExA, [ :HKEY, :LPCTSTR, :LONG, :DWORD ], :LONG

        # LONG WINAPI RegDeleteValue(
        #   _In_     HKEY    hKey,
        #   _In_opt_ LPCTSTR lpValueName
        # );
        safe_attach_function :RegDeleteValueW, [ :HKEY, :LPCTSTR ], :LONG

      end
    end
  end
end
