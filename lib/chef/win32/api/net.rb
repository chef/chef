#
# Author:: Serdar Sutay (<serdar@getchef.com>)
# Copyright:: Copyright 2014 Chef Software, Inc.
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
      module Net
        extend Chef::ReservedNames::Win32::API

        FILTER_TEMP_DUPLICATE_ACCOUNT       = 0x0001
        FILTER_NORMAL_ACCOUNT               = 0x0002
        FILTER_INTERDOMAIN_TRUST_ACCOUNT    = 0x0008
        FILTER_WORKSTATION_TRUST_ACCOUNT    = 0x0010
        FILTER_SERVER_TRUST_ACCOUNT         = 0x0020

        MAX_PREFERRED_LENGTH                = 0xFFFF

        NERR_Success                        = 0

        ffi_lib "netapi32"

        class USER_INFO_3 < FFI::Struct
          layout :usri3_name, :LPWSTR,
            :usri3_password, :LPWSTR,
            :usri3_password_age, :DWORD,
            :usri3_priv, :DWORD,
            :usri3_home_dir, :LPWSTR,
            :usri3_comment, :LPWSTR,
            :usri3_flags, :DWORD,
            :usri3_script_path, :LPWSTR,
            :usri3_auth_flags, :DWORD,
            :usri3_full_name, :LPWSTR,
            :usri3_usr_comment, :LPWSTR,
            :usri3_parms, :LPWSTR,
            :usri3_workstations, :LPWSTR,
            :usri3_last_logon, :DWORD,
            :usri3_last_logoff, :DWORD,
            :usri3_acct_expires, :DWORD,
            :usri3_max_storage, :DWORD,
            :usri3_units_per_week, :DWORD,
            :usri3_logon_hours, :PBYTE,
            :usri3_bad_pw_count, :DWORD,
            :usri3_num_logons, :DWORD,
            :usri3_logon_server, :LPWSTR,
            :usri3_country_code, :DWORD,
            :usri3_code_page, :DWORD,
            :usri3_user_id, :DWORD,
            :usri3_primary_group_id, :DWORD,
            :usri3_profile, :LPWSTR,
            :usri3_home_dir_drive, :LPWSTR,
            :usri3_password_expired, :DWORD
        end

# NET_API_STATUS NetUserEnum(
#   _In_     LPCWSTR servername,
#   _In_     DWORD level,
#   _In_     DWORD filter,
#   _Out_    LPBYTE *bufptr,
#   _In_     DWORD prefmaxlen,
#   _Out_    LPDWORD entriesread,
#   _Out_    LPDWORD totalentries,
#   _Inout_  LPDWORD resume_handle
# );
        safe_attach_function :NetUserEnum, [ :LPCWSTR, :DWORD, :DWORD, :LPBYTE, :DWORD, :LPDWORD, :LPDWORD, :LPDWORD ], :DWORD

# NET_API_STATUS NetApiBufferFree(
#   _In_  LPVOID Buffer
# );
        safe_attach_function :NetApiBufferFree, [ :LPVOID ], :DWORD
      end
    end
  end
end
