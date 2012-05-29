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
      module Security
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Constants
        ###############################################

        # ACE_HEADER AceType
        ACCESS_MIN_MS_ACE_TYPE                   = 0x0
        ACCESS_ALLOWED_ACE_TYPE                  = 0x0
        ACCESS_DENIED_ACE_TYPE                   = 0x1
        SYSTEM_AUDIT_ACE_TYPE                    = 0x2
        SYSTEM_ALARM_ACE_TYPE                    = 0x3
        ACCESS_MAX_MS_V2_ACE_TYPE                = 0x3
        ACCESS_ALLOWED_COMPOUND_ACE_TYPE         = 0x4
        ACCESS_MAX_MS_V3_ACE_TYPE                = 0x4
        ACCESS_MIN_MS_OBJECT_ACE_TYPE            = 0x5
        ACCESS_ALLOWED_OBJECT_ACE_TYPE           = 0x5
        ACCESS_DENIED_OBJECT_ACE_TYPE            = 0x6
        SYSTEM_AUDIT_OBJECT_ACE_TYPE             = 0x7
        SYSTEM_ALARM_OBJECT_ACE_TYPE             = 0x8
        ACCESS_MAX_MS_OBJECT_ACE_TYPE            = 0x8
        ACCESS_MAX_MS_V4_ACE_TYPE                = 0x8
        ACCESS_MAX_MS_ACE_TYPE                   = 0x8
        ACCESS_ALLOWED_CALLBACK_ACE_TYPE         = 0x9
        ACCESS_DENIED_CALLBACK_ACE_TYPE          = 0xA
        ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE  = 0xB
        ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE   = 0xC
        SYSTEM_AUDIT_CALLBACK_ACE_TYPE           = 0xD
        SYSTEM_ALARM_CALLBACK_ACE_TYPE           = 0xE
        SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE    = 0xF
        SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE    = 0x10
        SYSTEM_MANDATORY_LABEL_ACE_TYPE          = 0x11
        ACCESS_MAX_MS_V5_ACE_TYPE                = 0x11

        # ACE_HEADER AceFlags
        OBJECT_INHERIT_ACE                 = 0x1
        CONTAINER_INHERIT_ACE              = 0x2
        NO_PROPAGATE_INHERIT_ACE           = 0x4
        INHERIT_ONLY_ACE                   = 0x8
        INHERITED_ACE                      = 0x10
        VALID_INHERIT_FLAGS                = 0x1F
        SUCCESSFUL_ACCESS_ACE_FLAG         = 0x40
        FAILED_ACCESS_ACE_FLAG             = 0x80

        # SECURITY_INFORMATION flags (DWORD)
        OWNER_SECURITY_INFORMATION = 0x01
        GROUP_SECURITY_INFORMATION = 0x02
        DACL_SECURITY_INFORMATION = 0x04
        SACL_SECURITY_INFORMATION = 0x08
        LABEL_SECURITY_INFORMATION = 0x10
        UNPROTECTED_SACL_SECURITY_INFORMATION = 0x10000000
        UNPROTECTED_DACL_SECURITY_INFORMATION = 0x20000000
        PROTECTED_SACL_SECURITY_INFORMATION = 0x40000000
        PROTECTED_DACL_SECURITY_INFORMATION = 0x80000000

        # SECURITY_DESCRIPTOR_REVISION
        SECURITY_DESCRIPTOR_REVISION = 1
        SECURITY_DESCRIPTOR_REVISION1 = 1

        # SECURITY_DESCRIPTOR_CONTROL
        SE_OWNER_DEFAULTED                = 0x0001
        SE_GROUP_DEFAULTED                = 0x0002
        SE_DACL_PRESENT                   = 0x0004
        SE_DACL_DEFAULTED                 = 0x0008
        SE_SACL_PRESENT                   = 0x0010
        SE_SACL_DEFAULTED                 = 0x0020
        SE_DACL_AUTO_INHERIT_REQ          = 0x0100
        SE_SACL_AUTO_INHERIT_REQ          = 0x0200
        SE_DACL_AUTO_INHERITED            = 0x0400
        SE_SACL_AUTO_INHERITED            = 0x0800
        SE_DACL_PROTECTED                 = 0x1000
        SE_SACL_PROTECTED                 = 0x2000
        SE_RM_CONTROL_VALID               = 0x4000
        SE_SELF_RELATIVE                  = 0x8000

        # ACCESS_RIGHTS_MASK
        # Generic Access Rights
        GENERIC_READ                      = 0x80000000
        GENERIC_WRITE                     = 0x40000000
        GENERIC_EXECUTE                   = 0x20000000
        GENERIC_ALL                       = 0x10000000
        # Standard Access Rights
        DELETE                            = 0x00010000
        READ_CONTROL                      = 0x00020000
        WRITE_DAC                         = 0x00040000
        WRITE_OWNER                       = 0x00080000
        SYNCHRONIZE                       = 0x00100000
        STANDARD_RIGHTS_REQUIRED          = 0x000F0000
        STANDARD_RIGHTS_READ              = READ_CONTROL
        STANDARD_RIGHTS_WRITE             = READ_CONTROL
        STANDARD_RIGHTS_EXECUTE           = READ_CONTROL
        STANDARD_RIGHTS_ALL               = 0x001F0000
        SPECIFIC_RIGHTS_ALL               = 0x0000FFFF
        # Access System Security Right
        ACCESS_SYSTEM_SECURITY            = 0x01000000
        # File/Directory Specific Rights
        FILE_READ_DATA             =  0x0001
        FILE_LIST_DIRECTORY        =  0x0001
        FILE_WRITE_DATA            =  0x0002
        FILE_ADD_FILE              =  0x0002
        FILE_APPEND_DATA           =  0x0004
        FILE_ADD_SUBDIRECTORY      =  0x0004
        FILE_CREATE_PIPE_INSTANCE  =  0x0004
        FILE_READ_EA               =  0x0008
        FILE_WRITE_EA              =  0x0010
        FILE_EXECUTE               =  0x0020
        FILE_TRAVERSE              =  0x0020
        FILE_DELETE_CHILD          =  0x0040
        FILE_READ_ATTRIBUTES       =  0x0080
        FILE_WRITE_ATTRIBUTES      =  0x0100
        FILE_ALL_ACCESS            = STANDARD_RIGHTS_REQUIRED |
                                     SYNCHRONIZE |
                                     0x1FF
        FILE_GENERIC_READ          = STANDARD_RIGHTS_READ |
                                     FILE_READ_DATA       |
                                     FILE_READ_ATTRIBUTES |
                                     FILE_READ_EA         |
                                     SYNCHRONIZE
        FILE_GENERIC_WRITE         = STANDARD_RIGHTS_WRITE    |
                                     FILE_WRITE_DATA          |
                                     FILE_WRITE_ATTRIBUTES    |
                                     FILE_WRITE_EA            |
                                     FILE_APPEND_DATA         |
                                     SYNCHRONIZE
        FILE_GENERIC_EXECUTE       = STANDARD_RIGHTS_EXECUTE  |
                                     FILE_READ_ATTRIBUTES     |
                                     FILE_EXECUTE             |
                                     SYNCHRONIZE
        # Access Token Rights (for OpenProcessToken)
        # Access Rights for Access-Token Objects (used in OpenProcessToken)
        TOKEN_ASSIGN_PRIMARY = 0x0001
        TOKEN_DUPLICATE = 0x0002
        TOKEN_IMPERSONATE = 0x0004
        TOKEN_QUERY = 0x0008
        TOKEN_QUERY_SOURCE = 0x0010
        TOKEN_ADJUST_PRIVILEGES = 0x0020
        TOKEN_ADJUST_GROUPS = 0x0040
        TOKEN_ADJUST_DEFAULT = 0x0080
        TOKEN_ADJUST_SESSIONID = 0x0100
        TOKEN_READ = (STANDARD_RIGHTS_READ | TOKEN_QUERY)
        TOKEN_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY |
            TOKEN_DUPLICATE | TOKEN_IMPERSONATE | TOKEN_QUERY | TOKEN_QUERY_SOURCE |
            TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT |
            TOKEN_ADJUST_SESSIONID)

        # AdjustTokenPrivileges
        SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x00000001
        SE_PRIVILEGE_ENABLED = 0x00000002
        SE_PRIVILEGE_REMOVED = 0X00000004
        SE_PRIVILEGE_USED_FOR_ACCESS = 0x80000000
        SE_PRIVILEGE_VALID_ATTRIBUTES = SE_PRIVILEGE_ENABLED_BY_DEFAULT |
                                         SE_PRIVILEGE_ENABLED            |
                                         SE_PRIVILEGE_REMOVED            |
                                         SE_PRIVILEGE_USED_FOR_ACCESS

        # Minimum size of a SECURITY_DESCRIPTOR.  TODO: this is probably platform dependent.
        # Make it work on 64 bit.
        SECURITY_DESCRIPTOR_MIN_LENGTH = 20

        # ACL revisions
        ACL_REVISION     = 2
        ACL_REVISION_DS  = 4
        ACL_REVISION1   = 1
        ACL_REVISION2   = 2
        ACL_REVISION3   = 3
        ACL_REVISION4   = 4
        MIN_ACL_REVISION = ACL_REVISION2
        MAX_ACL_REVISION = ACL_REVISION4

        MAXDWORD = 0xffffffff

        ###############################################
        # Win32 API Bindings
        ###############################################

        SE_OBJECT_TYPE = enum :SE_OBJECT_TYPE, [
             :SE_UNKNOWN_OBJECT_TYPE,
             :SE_FILE_OBJECT,
             :SE_SERVICE,
             :SE_PRINTER,
             :SE_REGISTRY_KEY,
             :SE_LMSHARE,
             :SE_KERNEL_OBJECT,
             :SE_WINDOW_OBJECT,
             :SE_DS_OBJECT,
             :SE_DS_OBJECT_ALL,
             :SE_PROVIDER_DEFINED_OBJECT,
             :SE_WMIGUID_OBJECT,
             :SE_REGISTRY_WOW64_32KEY
        ]

        SID_NAME_USE = enum :SID_NAME_USE, [
             :SidTypeUser, 1,
             :SidTypeGroup,
             :SidTypeDomain,
             :SidTypeAlias,
             :SidTypeWellKnownGroup,
             :SidTypeDeletedAccount,
             :SidTypeInvalid,
             :SidTypeUnknown,
             :SidTypeComputer,
             :SidTypeLabel
        ]

        # SECURITY_DESCRIPTOR is an opaque structure whose contents can vary.  Pass the
        # pointer around and free it with LocalFree.
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa379561(v=vs.85).aspx

        # SID is an opaque structure.  Pass the pointer around.

        # ACL type is a header with some information, followed by an array of ACEs
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa374931(v=VS.85).aspx
        class ACLStruct < FFI::Struct
          layout :AclRevision, :uchar,
                 :Sbzl, :uchar,
                 :AclSize, :ushort,
                 :AceCount, :ushort,
                 :Sbz2, :ushort
        end

        class ACE_HEADER < FFI::Struct
          layout :AceType, :uchar,
                 :AceFlags, :uchar,
                 :AceSize, :ushort
        end

        class ACE_WITH_MASK_AND_SID < FFI::Struct
          layout :AceType, :uchar,
                 :AceFlags, :uchar,
                 :AceSize, :ushort,
                 :Mask, :uint32,
                 :SidStart, :uint32

          # The AceTypes this structure supports
          def self.supports?(ace_type)
            [
              ACCESS_ALLOWED_ACE_TYPE,
              ACCESS_DENIED_ACE_TYPE,
              SYSTEM_AUDIT_ACE_TYPE,
              SYSTEM_ALARM_ACE_TYPE
            ].include?(ace_type)
          end
        end

        class LUID < FFI::Struct
          layout :LowPart, :DWORD,
                 :HighPart, :LONG
        end

        class LUID_AND_ATTRIBUTES < FFI::Struct
          layout :Luid, LUID,
                 :Attributes, :DWORD
        end

        class TOKEN_PRIVILEGES < FFI::Struct
          layout :PrivilegeCount, :DWORD,
                 :Privileges, LUID_AND_ATTRIBUTES

          def self.size_with_privileges(num_privileges)
            offset_of(:Privileges) + LUID_AND_ATTRIBUTES.size*num_privileges
          end

          def size_with_privileges
            TOKEN_PRIVILEGES.size_with_privileges(self[:PrivilegeCount])
          end

          def privilege(index)
            LUID_AND_ATTRIBUTES.new(pointer + offset_of(:Privileges) + (index * LUID_AND_ATTRIBUTES.size))
          end
        end

        ffi_lib "advapi32"

        attach_function :AddAce, [ :pointer, :DWORD, :DWORD, :LPVOID, :DWORD ], :BOOL
        attach_function :AddAccessAllowedAce, [ :pointer, :DWORD, :DWORD, :pointer ], :BOOL
        attach_function :AddAccessAllowedAceEx, [ :pointer, :DWORD, :DWORD, :DWORD, :pointer ], :BOOL
        attach_function :AddAccessDeniedAce, [ :pointer, :DWORD, :DWORD, :pointer ], :BOOL
        attach_function :AddAccessDeniedAceEx, [ :pointer, :DWORD, :DWORD, :DWORD, :pointer ], :BOOL
        attach_function :AdjustTokenPrivileges, [ :HANDLE, :BOOL, :pointer, :DWORD, :pointer, :PDWORD ], :BOOL
        attach_function :ConvertSidToStringSidA, [ :pointer, :pointer ], :BOOL
        attach_function :ConvertStringSidToSidW, [ :pointer, :pointer ], :BOOL
        attach_function :DeleteAce, [ :pointer, :DWORD ], :BOOL
        attach_function :EqualSid, [ :pointer, :pointer ], :BOOL
        attach_function :FreeSid, [ :pointer ], :pointer
        attach_function :GetAce, [ :pointer, :DWORD, :pointer ], :BOOL
        attach_function :GetLengthSid, [ :pointer ], :DWORD
        attach_function :GetNamedSecurityInfoW,  [ :LPWSTR, :SE_OBJECT_TYPE, :DWORD, :pointer, :pointer, :pointer, :pointer, :pointer ], :DWORD
        attach_function :GetSecurityDescriptorControl, [ :pointer, :PWORD, :LPDWORD], :BOOL
        attach_function :GetSecurityDescriptorDacl, [ :pointer, :LPBOOL, :pointer, :LPBOOL ], :BOOL
        attach_function :GetSecurityDescriptorGroup, [ :pointer, :pointer, :LPBOOL], :BOOL
        attach_function :GetSecurityDescriptorOwner, [ :pointer, :pointer, :LPBOOL], :BOOL
        attach_function :GetSecurityDescriptorSacl, [ :pointer, :LPBOOL, :pointer, :LPBOOL ], :BOOL
        attach_function :InitializeAcl, [ :pointer, :DWORD, :DWORD ], :BOOL
        attach_function :InitializeSecurityDescriptor, [ :pointer, :DWORD ], :BOOL
        attach_function :IsValidAcl, [ :pointer ], :BOOL
        attach_function :IsValidSecurityDescriptor, [ :pointer ], :BOOL
        attach_function :IsValidSid, [ :pointer ], :BOOL
        attach_function :LookupAccountNameW, [ :LPCWSTR, :LPCWSTR, :pointer, :LPDWORD, :LPWSTR, :LPDWORD, :pointer ], :BOOL
        attach_function :LookupAccountSidW, [ :LPCWSTR, :pointer, :LPWSTR, :LPDWORD, :LPWSTR, :LPDWORD, :pointer ], :BOOL
        attach_function :LookupPrivilegeNameW, [ :LPCWSTR, :PLUID, :LPWSTR, :LPDWORD ], :BOOL
        attach_function :LookupPrivilegeDisplayNameW, [ :LPCWSTR, :LPCWSTR, :LPWSTR, :LPDWORD, :LPDWORD ], :BOOL
        attach_function :LookupPrivilegeValueW, [ :LPCWSTR, :LPCWSTR, :PLUID ], :BOOL
        attach_function :MakeAbsoluteSD, [ :pointer, :pointer, :LPDWORD, :pointer, :LPDWORD, :pointer, :LPDWORD, :pointer, :LPDWORD, :pointer, :LPDWORD], :BOOL
        attach_function :OpenProcessToken, [ :HANDLE, :DWORD, :PHANDLE ], :BOOL
        attach_function :QuerySecurityAccessMask, [ :DWORD, :LPDWORD ], :void
        attach_function :SetFileSecurityW, [ :LPWSTR, :DWORD, :pointer ], :BOOL
        attach_function :SetNamedSecurityInfoW, [ :LPWSTR, :SE_OBJECT_TYPE, :DWORD, :pointer, :pointer, :pointer, :pointer ], :DWORD
        attach_function :SetSecurityAccessMask, [ :DWORD, :LPDWORD ], :void
        attach_function :SetSecurityDescriptorDacl, [ :pointer, :BOOL, :pointer, :BOOL ], :BOOL
        attach_function :SetSecurityDescriptorGroup, [ :pointer, :pointer, :BOOL ], :BOOL
        attach_function :SetSecurityDescriptorOwner, [ :pointer, :pointer, :BOOL ], :BOOL
        attach_function :SetSecurityDescriptorSacl, [ :pointer, :BOOL, :pointer, :BOOL ], :BOOL

      end
    end
  end
end
