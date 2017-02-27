#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/win32/unicode"

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

        DOMAIN_GROUP_RID_USERS = 0x00000201

        UF_SCRIPT              = 0x000001
        UF_ACCOUNTDISABLE      = 0x000002
        UF_PASSWD_CANT_CHANGE  = 0x000040
        UF_NORMAL_ACCOUNT      = 0x000200
        UF_DONT_EXPIRE_PASSWD  = 0x010000

        USE_NOFORCE = 0
        USE_FORCE = 1
        USE_LOTS_OF_FORCE = 2 #every windows API should support this flag

        NERR_Success = 0 # rubocop:disable Style/ConstantName
        ERROR_MORE_DATA = 234

        ffi_lib "netapi32"

        module StructHelpers
          def set(key, val)
            val = if val.is_a? String
                    encoded = if val.encoding == Encoding::UTF_16LE
                                val
                              else
                                val.to_wstring
                              end
                    FFI::MemoryPointer.from_string(encoded)
                  else
                    val
                  end
            self[key] = val
          end

          def get(key)
            if respond_to? key
              send(key)
            else
              val = self[key]
              if val.is_a? FFI::Pointer
                if val.null?
                  nil
                else
                  val.read_wstring
                end
              else
                val
              end
            end
          end

          def as_ruby
            members.inject({}) do |memo, key|
              memo[key] = get(key)
              memo
            end
          end
        end

        class USER_INFO_3 < FFI::Struct
          include StructHelpers
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

          def usri3_logon_hours
            val = self[:usri3_logon_hours]
            if !val.nil? && !val.null?
              val.read_bytes(21)
            else
              nil
            end
          end
        end

        class LOCALGROUP_MEMBERS_INFO_0 < FFI::Struct
          layout :lgrmi0_sid, :PSID
        end

        class LOCALGROUP_MEMBERS_INFO_3 < FFI::Struct
          layout :lgrmi3_domainandname, :LPWSTR
        end

        class LOCALGROUP_INFO_0 < FFI::Struct
          layout :lgrpi0_name, :LPWSTR
        end

        class USE_INFO_2 < FFI::Struct
          include StructHelpers

          layout :ui2_local, :LMSTR,
            :ui2_remote, :LMSTR,
            :ui2_password, :LMSTR,
            :ui2_status, :DWORD,
            :ui2_asg_type, :DWORD,
            :ui2_refcount, :DWORD,
            :ui2_usecount, :DWORD,
            :ui2_username, :LPWSTR,
            :ui2_domainname, :LMSTR
        end

        #NET_API_STATUS NetLocalGroupAdd(
        #_In_  LPCWSTR servername,
        #_In_  DWORD   level,
        #_In_  LPBYTE  buf,
        #_Out_ LPDWORD parm_err
        #);
        safe_attach_function :NetLocalGroupAdd, [
          :LPCWSTR, :DWORD, :LPBYTE, :LPDWORD
        ], :DWORD

        #NET_API_STATUS NetLocalGroupDel(
        #_In_ LPCWSTR servername,
        #_In_ LPCWSTR groupname
        #);
        safe_attach_function :NetLocalGroupDel, [:LPCWSTR, :LPCWSTR], :DWORD

        #NET_API_STATUS NetLocalGroupGetMembers(
        #_In_    LPCWSTR    servername,
        #_In_    LPCWSTR    localgroupname,
        #_In_    DWORD      level,
        #_Out_   LPBYTE     *bufptr,
        #_In_    DWORD      prefmaxlen,
        #_Out_   LPDWORD    entriesread,
        #_Out_   LPDWORD    totalentries,
        #_Inout_ PDWORD_PTR resumehandle
        #);
        safe_attach_function :NetLocalGroupGetMembers, [
          :LPCWSTR, :LPCWSTR, :DWORD, :LPBYTE, :DWORD,
          :LPDWORD, :LPDWORD, :PDWORD_PTR
        ], :DWORD

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
        safe_attach_function :NetUserEnum, [
          :LPCWSTR, :DWORD, :DWORD, :LPBYTE,
          :DWORD, :LPDWORD, :LPDWORD, :LPDWORD
        ], :DWORD

        # NET_API_STATUS NetApiBufferFree(
        #   _In_  LPVOID Buffer
        # );
        safe_attach_function :NetApiBufferFree, [:LPVOID], :DWORD

        #NET_API_STATUS NetUserAdd(
        #_In_  LMSTR   servername,
        #_In_  DWORD   level,
        #_In_  LPBYTE  buf,
        #_Out_ LPDWORD parm_err
        #);
        safe_attach_function :NetUserAdd, [
          :LMSTR, :DWORD, :LPBYTE, :LPDWORD
        ], :DWORD

        #NET_API_STATUS NetLocalGroupAddMembers(
        #  _In_ LPCWSTR servername,
        #  _In_ LPCWSTR groupname,
        #  _In_ DWORD   level,
        #  _In_ LPBYTE  buf,
        #  _In_ DWORD   totalentries
        #);
        safe_attach_function :NetLocalGroupAddMembers, [
          :LPCWSTR, :LPCWSTR, :DWORD, :LPBYTE, :DWORD
        ], :DWORD

        #NET_API_STATUS NetLocalGroupSetMembers(
        #  _In_ LPCWSTR servername,
        #  _In_ LPCWSTR groupname,
        #  _In_ DWORD   level,
        #  _In_ LPBYTE  buf,
        #  _In_ DWORD   totalentries
        #);
        safe_attach_function :NetLocalGroupSetMembers, [
          :LPCWSTR, :LPCWSTR, :DWORD, :LPBYTE, :DWORD
        ], :DWORD

        #NET_API_STATUS NetLocalGroupDelMembers(
        #  _In_ LPCWSTR servername,
        #  _In_ LPCWSTR groupname,
        #  _In_ DWORD   level,
        #  _In_ LPBYTE  buf,
        #  _In_ DWORD   totalentries
        #);
        safe_attach_function :NetLocalGroupDelMembers, [
          :LPCWSTR, :LPCWSTR, :DWORD, :LPBYTE, :DWORD
        ], :DWORD

        #NET_API_STATUS NetUserGetInfo(
        #  _In_  LPCWSTR servername,
        #  _In_  LPCWSTR username,
        #  _In_  DWORD   level,
        #  _Out_ LPBYTE  *bufptr
        #);
        safe_attach_function :NetUserGetInfo, [
          :LPCWSTR, :LPCWSTR, :DWORD, :LPBYTE
        ], :DWORD

        #NET_API_STATUS NetApiBufferFree(
        #  _In_ LPVOID Buffer
        #);
        safe_attach_function :NetApiBufferFree, [:LPVOID], :DWORD

        #NET_API_STATUS NetUserSetInfo(
        #  _In_  LPCWSTR servername,
        #  _In_  LPCWSTR username,
        #  _In_  DWORD   level,
        #  _In_  LPBYTE  buf,
        #  _Out_ LPDWORD parm_err
        #);
        safe_attach_function :NetUserSetInfo, [
          :LPCWSTR, :LPCWSTR, :DWORD, :LPBYTE, :LPDWORD
        ], :DWORD

        #NET_API_STATUS NetUserDel(
        #  _In_ LPCWSTR servername,
        #  _In_ LPCWSTR username
        #);
        safe_attach_function :NetUserDel, [:LPCWSTR, :LPCWSTR], :DWORD

        #NET_API_STATUS NetUseDel(
        #_In_ LMSTR UncServerName,
        #_In_ LMSTR UseName,
        #_In_ DWORD ForceCond
        #);
        safe_attach_function :NetUseDel, [:LMSTR, :LMSTR, :DWORD], :DWORD

        #NET_API_STATUS NetUseGetInfo(
        #_In_  LMSTR  UncServerName,
        #_In_  LMSTR  UseName,
        #_In_  DWORD  Level,
        #_Out_ LPBYTE *BufPtr
        #);
        safe_attach_function :NetUseGetInfo, [:LMSTR, :LMSTR, :DWORD, :pointer], :DWORD

        #NET_API_STATUS NetUseAdd(
        #_In_  LMSTR   UncServerName,
        #_In_  DWORD   Level,
        #_In_  LPBYTE  Buf,
        #_Out_ LPDWORD ParmError
        #);
        safe_attach_function :NetUseAdd, [:LMSTR, :DWORD, :LPBYTE, :LPDWORD], :DWORD
      end
    end
  end
end
