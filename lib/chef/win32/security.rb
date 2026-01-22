#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "api/security"
require_relative "error"
require_relative "memory"
require_relative "process"
require_relative "unicode"
require_relative "security/token"
require_relative "../mixin/wide_string"

class Chef
  module ReservedNames::Win32
    class Security
      include Chef::ReservedNames::Win32::API::Error
      extend Chef::ReservedNames::Win32::API::Error
      include Chef::ReservedNames::Win32::API::Security
      extend Chef::ReservedNames::Win32::API::Security
      extend Chef::ReservedNames::Win32::API::Macros
      include Chef::Mixin::WideString
      extend Chef::Mixin::WideString

      def self.access_check(security_descriptor, token, desired_access, generic_mapping)
        token_handle = token.handle.handle
        security_descriptor_ptr = security_descriptor.pointer

        rights_ptr = FFI::MemoryPointer.new(:ulong)
        rights_ptr.write_ulong(desired_access)

        # This function takes care of calling MapGenericMask, so you don't have to
        MapGenericMask(rights_ptr, generic_mapping)

        result_ptr = FFI::MemoryPointer.new(:ulong)

        # Because optional actually means required
        privileges = PRIVILEGE_SET.new
        privileges[:PrivilegeCount] = 0
        privileges_length_ptr = FFI::MemoryPointer.new(:ulong)
        privileges_length_ptr.write_ulong(privileges.size)

        granted_access_ptr = FFI::MemoryPointer.new(:ulong)

        unless AccessCheck(security_descriptor_ptr, token_handle, rights_ptr.read_ulong,
          generic_mapping, privileges, privileges_length_ptr, granted_access_ptr,
          result_ptr)
          Chef::ReservedNames::Win32::Error.raise!
        end
        result_ptr.read_ulong == 1
      end

      def self.add_ace(acl, ace, insert_position = MAXDWORD, revision = ACL_REVISION)
        acl = acl.pointer if acl.respond_to?(:pointer)
        ace = ace.pointer if ace.respond_to?(:pointer)
        ace_size = ACE_HEADER.new(ace)[:AceSize]
        unless AddAce(acl, revision, insert_position, ace, ace_size)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.add_access_allowed_ace(acl, sid, access_mask, revision = ACL_REVISION)
        acl = acl.pointer if acl.respond_to?(:pointer)
        sid = sid.pointer if sid.respond_to?(:pointer)
        unless AddAccessAllowedAce(acl, revision, access_mask, sid)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.add_access_allowed_ace_ex(acl, sid, access_mask, flags = 0, revision = ACL_REVISION)
        acl = acl.pointer if acl.respond_to?(:pointer)
        sid = sid.pointer if sid.respond_to?(:pointer)
        unless AddAccessAllowedAceEx(acl, revision, flags, access_mask, sid)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.add_access_denied_ace(acl, sid, access_mask, revision = ACL_REVISION)
        acl = acl.pointer if acl.respond_to?(:pointer)
        sid = sid.pointer if sid.respond_to?(:pointer)
        unless AddAccessDeniedAce(acl, revision, access_mask, sid)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.add_access_denied_ace_ex(acl, sid, access_mask, flags = 0, revision = ACL_REVISION)
        acl = acl.pointer if acl.respond_to?(:pointer)
        sid = sid.pointer if sid.respond_to?(:pointer)
        unless AddAccessDeniedAceEx(acl, revision, flags, access_mask, sid)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.add_account_right(name, privilege)
        privilege_pointer = FFI::MemoryPointer.new LSA_UNICODE_STRING, 1
        privilege_lsa_string = LSA_UNICODE_STRING.new(privilege_pointer)
        privilege_lsa_string[:Buffer] = FFI::MemoryPointer.from_string(privilege.to_wstring)
        privilege_lsa_string[:Length] = privilege.length * 2
        privilege_lsa_string[:MaximumLength] = (privilege.length + 1) * 2

        with_lsa_policy(name) do |policy_handle, sid|
          result = LsaAddAccountRights(policy_handle.read_pointer, sid, privilege_pointer, 1)
          test_and_raise_lsa_nt_status(result)
        end
      end

      def self.remove_account_right(name, privilege)
        privilege_pointer = FFI::MemoryPointer.new LSA_UNICODE_STRING, 1
        privilege_lsa_string = LSA_UNICODE_STRING.new(privilege_pointer)
        privilege_lsa_string[:Buffer] = FFI::MemoryPointer.from_string(privilege.to_wstring)
        privilege_lsa_string[:Length] = privilege.length * 2
        privilege_lsa_string[:MaximumLength] = (privilege.length + 1) * 2

        with_lsa_policy(name) do |policy_handle, sid|
          result = LsaRemoveAccountRights(policy_handle.read_pointer, sid, false, privilege_pointer, 1)
          test_and_raise_lsa_nt_status(result)
        end
      end

      def self.clear_account_rights(name)
        return if get_account_right(name) == []

        with_lsa_policy(name) do |policy_handle, sid|
          result = LsaRemoveAccountRights(policy_handle.read_pointer, sid, true, nil, 1)
          test_and_raise_lsa_nt_status(result)
        end
      end

      def self.adjust_token_privileges(token, privileges)
        token = token.handle if token.respond_to?(:handle)
        old_privileges_size = FFI::Buffer.new(:long).write_long(privileges.size_with_privileges)
        old_privileges = TOKEN_PRIVILEGES.new(FFI::Buffer.new(old_privileges_size.read_long))
        unless AdjustTokenPrivileges(token.handle, false, privileges, privileges.size_with_privileges, old_privileges, old_privileges_size)
          Chef::ReservedNames::Win32::Error.raise!
        end

        old_privileges
      end

      def self.convert_sid_to_string_sid(sid)
        sid = sid.pointer if sid.respond_to?(:pointer)
        result = FFI::MemoryPointer.new :pointer
        # TODO: use the W version
        unless ConvertSidToStringSidA(sid, result)
          Chef::ReservedNames::Win32::Error.raise!
        end

        result_string = result.read_pointer.read_string

        Chef::ReservedNames::Win32::Memory.local_free(result.read_pointer)

        result_string
      end

      def self.convert_string_sid_to_sid(string_sid)
        result = FFI::MemoryPointer.new :pointer
        unless ConvertStringSidToSidW(string_sid.to_wstring, result)
          Chef::ReservedNames::Win32::Error.raise!
        end

        result_pointer = result.read_pointer
        sid = SID.new(result_pointer)

        # The result pointer must be freed with local_free
        ObjectSpace.define_finalizer(sid, Memory.local_free_finalizer(result_pointer))

        sid
      end

      def self.delete_ace(acl, index)
        acl = acl.pointer if acl.respond_to?(:pointer)
        unless DeleteAce(acl, index)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.equal_sid(sid1, sid2)
        sid1 = sid1.pointer if sid1.respond_to?(:pointer)
        sid2 = sid2.pointer if sid2.respond_to?(:pointer)
        EqualSid(sid1, sid2)
      end

      def self.free_sid(sid)
        sid = sid.pointer if sid.respond_to?(:pointer)
        unless FreeSid(sid).null?
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.get_account_right(name)
        privileges = []
        privilege_pointer = FFI::MemoryPointer.new(:pointer)
        privilege_length = FFI::MemoryPointer.new(:ulong)

        with_lsa_policy(name) do |policy_handle, sid|
          result = LsaEnumerateAccountRights(policy_handle.read_pointer, sid, privilege_pointer, privilege_length)
          win32_error = LsaNtStatusToWinError(result)
          return [] if win32_error == 2 # FILE_NOT_FOUND - No rights assigned

          test_and_raise_lsa_nt_status(result)

          privilege_length.read_ulong.times do |i|
            privilege = LSA_UNICODE_STRING.new(privilege_pointer.read_pointer + i * LSA_UNICODE_STRING.size)
            privileges << privilege[:Buffer].read_wstring
          end
          result = LsaFreeMemory(privilege_pointer.read_pointer)
          test_and_raise_lsa_nt_status(result)
        end

        privileges
      end

      def self.get_account_with_user_rights(privilege)
        privilege_pointer = FFI::MemoryPointer.new LSA_UNICODE_STRING, 1
        privilege_lsa_string = LSA_UNICODE_STRING.new(privilege_pointer)
        privilege_lsa_string[:Buffer] = FFI::MemoryPointer.from_string(privilege.to_wstring)
        privilege_lsa_string[:Length] = privilege.length * 2
        privilege_lsa_string[:MaximumLength] = (privilege.length + 1) * 2

        buffer = FFI::MemoryPointer.new(:pointer)
        count = FFI::MemoryPointer.new(:ulong)

        accounts = []
        with_lsa_policy(nil) do |policy_handle, sid|
          result = LsaEnumerateAccountsWithUserRight(policy_handle.read_pointer, privilege_pointer, buffer, count)
          if result == 0
            win32_error = LsaNtStatusToWinError(result)
            return [] if win32_error == 1313 # NO_SUCH_PRIVILEGE - https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes--1300-1699-

            test_and_raise_lsa_nt_status(result)

            count.read_ulong.times do |i|
              sid = LSA_ENUMERATION_INFORMATION.new(buffer.read_pointer + i * LSA_ENUMERATION_INFORMATION.size)
              sid_name = lookup_account_sid(sid[:Sid])
              domain, name, use = sid_name
              account_name = (!domain.nil? && domain.length > 0) ? "#{domain}\\#{name}" : name
              accounts << account_name
            end
          end

          result = LsaFreeMemory(buffer.read_pointer)
          test_and_raise_lsa_nt_status(result)
        end

        accounts
      end

      def self.get_ace(acl, index)
        acl = acl.pointer if acl.respond_to?(:pointer)
        ace = FFI::Buffer.new :pointer
        unless GetAce(acl, index, ace)
          Chef::ReservedNames::Win32::Error.raise!
        end
        ACE.new(ace.read_pointer, acl)
      end

      def self.get_length_sid(sid)
        sid = sid.pointer if sid.respond_to?(:pointer)
        GetLengthSid(sid)
      end

      def self.get_file_security(path, info = OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION)
        size_ptr = FFI::MemoryPointer.new(:ulong)

        success = GetFileSecurityW(path.to_wstring, info, nil, 0, size_ptr)

        if !success && FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        security_descriptor_ptr = FFI::MemoryPointer.new(size_ptr.read_ulong)
        unless GetFileSecurityW(path.to_wstring, info, security_descriptor_ptr, size_ptr.read_ulong, size_ptr)
          Chef::ReservedNames::Win32::Error.raise!
        end

        SecurityDescriptor.new(security_descriptor_ptr)
      end

      def self.get_named_security_info(path, type = :SE_FILE_OBJECT, info = OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION)
        security_descriptor = FFI::MemoryPointer.new :pointer
        hr = GetNamedSecurityInfoW(path.to_wstring, type, info, nil, nil, nil, nil, security_descriptor)
        if hr != ERROR_SUCCESS
          Chef::ReservedNames::Win32::Error.raise!("get_named_security_info(#{path}, #{type}, #{info})", hr)
        end

        result_pointer = security_descriptor.read_pointer
        result = SecurityDescriptor.new(result_pointer)

        # This memory has to be freed with LocalFree.
        ObjectSpace.define_finalizer(result, Memory.local_free_finalizer(result_pointer))

        result
      end

      def self.get_security_descriptor_control(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        result = FFI::Buffer.new :ushort
        version = FFI::Buffer.new :uint32
        unless GetSecurityDescriptorControl(security_descriptor, result, version)
          Chef::ReservedNames::Win32::Error.raise!
        end
        [ result.read_ushort, version.read_uint32 ]
      end

      def self.get_security_descriptor_dacl(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        present = FFI::Buffer.new :bool
        defaulted = FFI::Buffer.new :bool
        acl = FFI::Buffer.new :pointer
        unless GetSecurityDescriptorDacl(security_descriptor, present, acl, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
        acl = acl.read_pointer
        [ present.read_char != 0, acl.null? ? nil : ACL.new(acl, security_descriptor), defaulted.read_char != 0 ]
      end

      def self.get_security_descriptor_group(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        result = FFI::Buffer.new :pointer
        defaulted = FFI::Buffer.new :long
        unless GetSecurityDescriptorGroup(security_descriptor, result, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end

        sid = SID.new(result.read_pointer, security_descriptor)
        defaulted = defaulted.read_char != 0
        [ sid, defaulted ]
      end

      def self.get_security_descriptor_owner(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        result = FFI::Buffer.new :pointer
        defaulted = FFI::Buffer.new :long
        unless GetSecurityDescriptorOwner(security_descriptor, result, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end

        sid = SID.new(result.read_pointer, security_descriptor)
        defaulted = defaulted.read_char != 0
        [ sid, defaulted ]
      end

      def self.get_security_descriptor_sacl(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        present = FFI::Buffer.new :bool
        defaulted = FFI::Buffer.new :bool
        acl = FFI::Buffer.new :pointer
        unless GetSecurityDescriptorSacl(security_descriptor, present, acl, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
        acl = acl.read_pointer
        [ present.read_char != 0, acl.null? ? nil : ACL.new(acl, security_descriptor), defaulted.read_char != 0 ]
      end

      def self.get_token_information_owner(token)
        owner_result_size = FFI::MemoryPointer.new(:ulong)
        if GetTokenInformation(token.handle.handle, :TokenOwner, nil, 0, owner_result_size)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from GetTokenInformation, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        owner_result_storage = FFI::MemoryPointer.new owner_result_size.read_ulong
        unless GetTokenInformation(token.handle.handle, :TokenOwner, owner_result_storage, owner_result_size.read_ulong, owner_result_size)
          Chef::ReservedNames::Win32::Error.raise!
        end
        owner_result = TOKEN_OWNER.new owner_result_storage
        SID.new(owner_result[:Owner], owner_result_storage)
      end

      def self.get_token_information_primary_group(token)
        group_result_size = FFI::MemoryPointer.new(:ulong)
        if GetTokenInformation(token.handle.handle, :TokenPrimaryGroup, nil, 0, group_result_size)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from GetTokenInformation, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        group_result_storage = FFI::MemoryPointer.new group_result_size.read_ulong
        unless GetTokenInformation(token.handle.handle, :TokenPrimaryGroup, group_result_storage, group_result_size.read_ulong, group_result_size)
          Chef::ReservedNames::Win32::Error.raise!
        end
        group_result = TOKEN_PRIMARY_GROUP.new group_result_storage
        SID.new(group_result[:PrimaryGroup], group_result_storage)
      end

      def self.get_token_information_elevation_type(token)
        token_result_size = FFI::MemoryPointer.new(:ulong)
        if GetTokenInformation(token.handle.handle, :TokenElevationType, nil, 0, token_result_size)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from GetTokenInformation, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        info_ptr = FFI::MemoryPointer.new(:pointer)
        token_info_pointer = TOKEN_ELEVATION_TYPE.new info_ptr
        token_info_length = 4
        unless GetTokenInformation(token.handle.handle, :TokenElevationType, token_info_pointer, token_info_length, token_result_size)
          Chef::ReservedNames::Win32::Error.raise!
        end
        token_info_pointer[:ElevationType]
      end

      def self.initialize_acl(acl_size)
        acl = FFI::MemoryPointer.new acl_size
        unless InitializeAcl(acl, acl_size, ACL_REVISION)
          Chef::ReservedNames::Win32::Error.raise!
        end
        ACL.new(acl)
      end

      def self.initialize_security_descriptor(revision = SECURITY_DESCRIPTOR_REVISION)
        security_descriptor = FFI::MemoryPointer.new SECURITY_DESCRIPTOR_MIN_LENGTH
        unless InitializeSecurityDescriptor(security_descriptor, revision)
          Chef::ReservedNames::Win32::Error.raise!
        end
        SecurityDescriptor.new(security_descriptor)
      end

      def self.is_valid_acl(acl)
        acl = acl.pointer if acl.respond_to?(:pointer)
        IsValidAcl(acl) != 0
      end

      def self.is_valid_security_descriptor(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        IsValidSecurityDescriptor(security_descriptor) != 0
      end

      def self.is_valid_sid(sid)
        sid = sid.pointer if sid.respond_to?(:pointer)
        IsValidSid(sid) != 0
      end

      def self.lookup_account_name(name, system_name = nil)
        # Figure out how big the buffers need to be
        sid_size = FFI::Buffer.new(:long).write_long(0)
        referenced_domain_name_size = FFI::Buffer.new(:long).write_long(0)
        system_name = system_name.to_wstring if system_name
        if LookupAccountNameW(system_name, name.to_wstring, nil, sid_size, nil, referenced_domain_name_size, nil)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from LookupAccountName, and got no error!"
        elsif !([NO_ERROR, ERROR_INSUFFICIENT_BUFFER].include?(FFI::LastError.error))
          Chef::ReservedNames::Win32::Error.raise!
        end

        sid = FFI::MemoryPointer.new :char, sid_size.read_long
        referenced_domain_name = FFI::MemoryPointer.new :char, (referenced_domain_name_size.read_long * 2)
        use = FFI::Buffer.new(:long).write_long(0)
        unless LookupAccountNameW(system_name, name.to_wstring, sid, sid_size, referenced_domain_name, referenced_domain_name_size, use)
          Chef::ReservedNames::Win32::Error.raise!
        end

        [ referenced_domain_name.read_wstring(referenced_domain_name_size.read_long), SID.new(sid), use.read_long ]
      end

      def self.lookup_account_sid(sid, system_name = nil)
        sid = sid.pointer if sid.respond_to?(:pointer)
        # Figure out how big the buffer needs to be
        name_size = FFI::Buffer.new(:long).write_long(0)
        referenced_domain_name_size = FFI::Buffer.new(:long).write_long(0)
        system_name = system_name.to_wstring if system_name
        if LookupAccountSidW(system_name, sid, nil, name_size, nil, referenced_domain_name_size, nil)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from LookupAccountSid, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        name = FFI::MemoryPointer.new :char, (name_size.read_long * 2)
        referenced_domain_name = FFI::MemoryPointer.new :char, (referenced_domain_name_size.read_long * 2)
        use = FFI::Buffer.new(:long).write_long(0)
        unless LookupAccountSidW(system_name, sid, name, name_size, referenced_domain_name, referenced_domain_name_size, use)
          Chef::ReservedNames::Win32::Error.raise!
        end

        [ referenced_domain_name.read_wstring(referenced_domain_name_size.read_long), name.read_wstring(name_size.read_long), use.read_long ]
      end

      def self.lookup_privilege_name(system_name, luid)
        system_name = system_name.to_wstring if system_name
        name_size = FFI::Buffer.new(:long).write_long(0)
        if LookupPrivilegeNameW(system_name, luid, nil, name_size)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from LookupPrivilegeName, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        name = FFI::MemoryPointer.new :char, (name_size.read_long * 2)
        unless LookupPrivilegeNameW(system_name, luid, name, name_size)
          Chef::ReservedNames::Win32::Error.raise!
        end

        name.read_wstring(name_size.read_long)
      end

      def self.lookup_privilege_display_name(system_name, name)
        system_name = system_name.to_wstring if system_name
        display_name_size = FFI::Buffer.new(:long).write_long(0)
        language_id = FFI::Buffer.new(:long)
        if LookupPrivilegeDisplayNameW(system_name, name.to_wstring, nil, display_name_size, language_id)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from LookupPrivilegeDisplayName, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        display_name = FFI::MemoryPointer.new :char, (display_name_size.read_long * 2)
        unless LookupPrivilegeDisplayNameW(system_name, name.to_wstring, display_name, display_name_size, language_id)
          Chef::ReservedNames::Win32::Error.raise!
        end

        [ display_name.read_wstring(display_name_size.read_long), language_id.read_long ]
      end

      def self.lookup_privilege_value(system_name, name)
        luid = FFI::Buffer.new(:uint64).write_uint64(0)
        system_name = system_name.to_wstring if system_name
        unless LookupPrivilegeValueW(system_name, name.to_wstring, luid)
          Win32::Error.raise!
        end
        luid.read_uint64
      end

      def self.make_absolute_sd(security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)

        # Figure out buffer sizes
        absolute_sd_size = FFI::Buffer.new(:long).write_long(0)
        dacl_size = FFI::Buffer.new(:long).write_long(0)
        sacl_size = FFI::Buffer.new(:long).write_long(0)
        owner_size = FFI::Buffer.new(:long).write_long(0)
        group_size = FFI::Buffer.new(:long).write_long(0)
        if MakeAbsoluteSD(security_descriptor, nil, absolute_sd_size, nil, dacl_size, nil, sacl_size, nil, owner_size, nil, group_size)
          raise "Expected ERROR_INSUFFICIENT_BUFFER from MakeAbsoluteSD, and got no error!"
        elsif FFI::LastError.error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        absolute_sd = FFI::MemoryPointer.new absolute_sd_size.read_long
        owner = FFI::MemoryPointer.new owner_size.read_long
        group = FFI::MemoryPointer.new group_size.read_long
        dacl = FFI::MemoryPointer.new dacl_size.read_long
        sacl = FFI::MemoryPointer.new sacl_size.read_long
        unless MakeAbsoluteSD(security_descriptor, absolute_sd, absolute_sd_size, dacl, dacl_size, sacl, sacl_size, owner, owner_size, group, group_size)
          Chef::ReservedNames::Win32::Error.raise!
        end

        [ SecurityDescriptor.new(absolute_sd), SID.new(owner), SID.new(group), ACL.new(dacl), ACL.new(sacl) ]
      end

      def self.open_current_process_token(desired_access = TOKEN_READ)
        open_process_token(Chef::ReservedNames::Win32::Process.get_current_process, desired_access)
      end

      def self.open_process_token(process, desired_access)
        process = process.handle if process.respond_to?(:handle)
        process = process.handle if process.respond_to?(:handle)
        token = FFI::Buffer.new(:ulong)
        unless OpenProcessToken(process, desired_access, token)
          Chef::ReservedNames::Win32::Error.raise!
        end
        Token.new(Handle.new(token.read_ulong))
      end

      def self.query_security_access_mask(security_information)
        result = FFI::Buffer.new(:long)
        QuerySecurityAccessMask(security_information, result)
        result.read_long
      end

      def self.set_file_security(path, security_information, security_descriptor)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        unless SetFileSecurityW(path.to_wstring, security_information, security_descriptor)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.set_named_security_info(path, type, args)
        owner = args[:owner]
        group = args[:group]
        dacl = args[:dacl]
        sacl = args[:sacl]
        owner = owner.pointer if owner && owner.respond_to?(:pointer)
        group = group.pointer if group && group.respond_to?(:pointer)
        dacl = dacl.pointer if dacl && dacl.respond_to?(:pointer)
        sacl = sacl.pointer if sacl && sacl.respond_to?(:pointer)

        # Determine the security_information flags
        security_information = 0
        security_information |= OWNER_SECURITY_INFORMATION if args.key?(:owner)
        security_information |= GROUP_SECURITY_INFORMATION if args.key?(:group)
        security_information |= DACL_SECURITY_INFORMATION if args.key?(:dacl)
        security_information |= SACL_SECURITY_INFORMATION if args.key?(:sacl)
        if args.key?(:dacl_inherits)
          security_information |= (args[:dacl_inherits] ? UNPROTECTED_DACL_SECURITY_INFORMATION : PROTECTED_DACL_SECURITY_INFORMATION)
        end
        if args.key?(:sacl_inherits)
          security_information |= (args[:sacl_inherits] ? UNPROTECTED_SACL_SECURITY_INFORMATION : PROTECTED_SACL_SECURITY_INFORMATION)
        end

        hr = SetNamedSecurityInfoW(path.to_wstring, type, security_information, owner, group, dacl, sacl)
        if hr != ERROR_SUCCESS
          Chef::ReservedNames::Win32::Error.raise! nil, hr
        end
      end

      def self.set_security_access_mask(security_information)
        result = FFI::Buffer.new(:long)
        SetSecurityAccessMask(security_information, result)
        result.read_long
      end

      def set_security_descriptor_dacl(security_descriptor, acl, defaulted = false, present = nil)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        acl = acl.pointer if acl.respond_to?(:pointer)
        present = !security_descriptor.null? if present.nil?

        unless SetSecurityDescriptorDacl(security_descriptor, present, acl, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.set_security_descriptor_group(security_descriptor, sid, defaulted = false)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        sid = sid.pointer if sid.respond_to?(:pointer)

        unless SetSecurityDescriptorGroup(security_descriptor, sid, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.set_security_descriptor_owner(security_descriptor, sid, defaulted = false)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        sid = sid.pointer if sid.respond_to?(:pointer)

        unless SetSecurityDescriptorOwner(security_descriptor, sid, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.set_security_descriptor_sacl(security_descriptor, acl, defaulted = false, present = nil)
        security_descriptor = security_descriptor.pointer if security_descriptor.respond_to?(:pointer)
        acl = acl.pointer if acl.respond_to?(:pointer)
        present = !security_descriptor.null? if present.nil?

        unless SetSecurityDescriptorSacl(security_descriptor, present, acl, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.with_lsa_policy(username)
        sid = lookup_account_name(username)[1] if username

        access = 0
        access |= POLICY_CREATE_ACCOUNT
        access |= POLICY_LOOKUP_NAMES
        access |= POLICY_VIEW_LOCAL_INFORMATION if username.nil?

        policy_handle = FFI::MemoryPointer.new(:pointer)
        result = LsaOpenPolicy(nil, LSA_OBJECT_ATTRIBUTES.new, access, policy_handle)
        test_and_raise_lsa_nt_status(result)

        sid_pointer = username.nil? ? nil : sid.pointer

        begin
          yield policy_handle, sid_pointer
        ensure
          result = LsaClose(policy_handle.read_pointer)
          test_and_raise_lsa_nt_status(result)
        end
      end

      def self.with_privileges(*privilege_names)
        # Set privileges
        token = open_current_process_token(TOKEN_READ | TOKEN_ADJUST_PRIVILEGES)
        old_privileges = token.enable_privileges(*privilege_names)

        # Let the caller do their privileged stuff
        begin
          yield
        ensure
          # Set privileges back to what they were before
          token.adjust_privileges(old_privileges)
        end
      end

      # Checks if the caller has the admin privileges in their
      # security token
      def self.has_admin_privileges?
        # a regular user doesn't have privileges to call Chef::ReservedNames::Win32::Security.OpenProcessToken
        # hence we return false if the open_current_process_token fails with `Access is denied.` error message.
        begin
          process_token = open_current_process_token(TOKEN_READ)
        rescue Exception => run_error
          return false if /Access is denied/.match?(run_error.message)

          Chef::ReservedNames::Win32::Error.raise!
        end

        # display token elevation details
        token_elevation_type = get_token_information_elevation_type(process_token)
        Chef::Log.trace("Token Elevation Type: #{token_elevation_type}")

        elevation_result = FFI::Buffer.new(:ulong)
        elevation_result_size = FFI::MemoryPointer.new(:uint32)
        success = GetTokenInformation(process_token.handle.handle, :TokenElevation, elevation_result, 4, elevation_result_size)

        # Assume process is not elevated if the call fails.
        # Process is elevated if the result is different than 0.
        success && (elevation_result.read_ulong != 0)
      end

      def self.logon_user(username, domain, password, logon_type, logon_provider)
        username = wstring(username)
        domain = wstring(domain)
        password = wstring(password)

        token = FFI::Buffer.new(:pointer)
        unless LogonUserW(username, domain, password, logon_type, logon_provider, token)
          Chef::ReservedNames::Win32::Error.raise!
        end

        # originally this was .read_pointer, but that is interpreted as a non-primitive
        # class (FFI::Pointer) and causes an ArgumentError (Invalid Memory Object) when
        # compared to GetCurrentProcess(), which returns a HANDLE (void *). Since a
        # HANDLE is not a pointer to allocated memory that Ruby C extensions can understand,
        # the Invalid Memory Object error is raised.
        Token.new(Handle.new(token.read_ulong))
      end

      def self.test_and_raise_lsa_nt_status(result)
        win32_error = LsaNtStatusToWinError(result)
        if win32_error != 0
          Chef::ReservedNames::Win32::Error.raise!(nil, win32_error)
        end
      end
    end
  end
end

require_relative "security/ace"
require_relative "security/acl"
require_relative "security/securable_object"
require_relative "security/security_descriptor"
require_relative "security/sid"
