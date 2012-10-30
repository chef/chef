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

require 'chef/win32/security'
require 'chef/win32/api/security'

require 'ffi'

class Chef
  module ReservedNames::Win32
    class Security
      class Token

        def initialize(handle)
          @handle = handle
        end

        attr_reader :handle

        def enable_privileges(*privilege_names)
          # Build the list of privileges we want to set
          new_privileges = Chef::ReservedNames::Win32::API::Security::TOKEN_PRIVILEGES.new(
            FFI::MemoryPointer.new(Chef::ReservedNames::Win32::API::Security::TOKEN_PRIVILEGES.size_with_privileges(privilege_names.length)))
          new_privileges[:PrivilegeCount] = 0
          privilege_names.each do |privilege_name|
            luid = Chef::ReservedNames::Win32::API::Security::LUID.new
            # Ignore failure (with_privileges TRIES but does not guarantee success--
            # APIs down the line will fail if privilege escalation fails)
            if Chef::ReservedNames::Win32::API::Security.LookupPrivilegeValueW(nil, privilege_name.to_wstring, luid)
              new_privilege = new_privileges.privilege(new_privileges[:PrivilegeCount])
              new_privilege[:Luid][:LowPart] = luid[:LowPart]
              new_privilege[:Luid][:HighPart] = luid[:HighPart]
              new_privilege[:Attributes] = Chef::ReservedNames::Win32::API::Security::SE_PRIVILEGE_ENABLED
              new_privileges[:PrivilegeCount] = new_privileges[:PrivilegeCount] + 1
            end
          end

          old_privileges = Chef::ReservedNames::Win32::Security.adjust_token_privileges(self, new_privileges)
        end

        def adjust_privileges(privileges_struct)
          if privileges_struct[:PrivilegeCount] > 0
            Chef::ReservedNames::Win32::Security::adjust_token_privileges(self, privileges_struct)
          end
        end
      end
    end
  end
end
