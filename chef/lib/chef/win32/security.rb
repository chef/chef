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

require 'chef/win32/api/security'
require 'chef/win32/error'
require 'chef/win32/memory'
require 'chef/win32/process'
require 'chef/win32/unicode'
require 'chef/win32/security/token'

class Chef
  module ReservedNames::Win32
    class Security
      include Chef::ReservedNames::Win32::API::Error
      extend Chef::ReservedNames::Win32::API::Error
      include Chef::ReservedNames::Win32::API::Security
      extend Chef::ReservedNames::Win32::API::Security
      extend Chef::ReservedNames::Win32::API::Macros

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

      def self.get_named_security_info(path, type = :SE_FILE_OBJECT, info = OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION)
        security_descriptor = FFI::MemoryPointer.new :pointer
        hr = GetNamedSecurityInfoW(path.to_wstring, type, info, nil, nil, nil, nil, security_descriptor)
        if hr != ERROR_SUCCESS
          Chef::ReservedNames::Win32::Error.raise!("get_named_security_info(#{path}, #{type}, #{info})")
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
        elsif Chef::ReservedNames::Win32::Error.get_last_error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        sid = FFI::MemoryPointer.new :char, sid_size.read_long
        referenced_domain_name = FFI::MemoryPointer.new :char, (referenced_domain_name_size.read_long*2)
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
        elsif Chef::ReservedNames::Win32::Error::get_last_error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        name = FFI::MemoryPointer.new :char, (name_size.read_long*2)
        referenced_domain_name = FFI::MemoryPointer.new :char, (referenced_domain_name_size.read_long*2)
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
        elsif Chef::ReservedNames::Win32::Error.get_last_error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        name = FFI::MemoryPointer.new :char, (name_size.read_long*2)
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
        elsif Chef::ReservedNames::Win32::Error.get_last_error != ERROR_INSUFFICIENT_BUFFER
          Chef::ReservedNames::Win32::Error.raise!
        end

        display_name = FFI::MemoryPointer.new :char, (display_name_size.read_long*2)
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
        elsif Chef::ReservedNames::Win32::Error.get_last_error != ERROR_INSUFFICIENT_BUFFER
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
        security_information |= OWNER_SECURITY_INFORMATION if args.has_key?(:owner)
        security_information |= GROUP_SECURITY_INFORMATION if args.has_key?(:group)
        security_information |= DACL_SECURITY_INFORMATION if args.has_key?(:dacl)
        security_information |= SACL_SECURITY_INFORMATION if args.has_key?(:sacl)
        if args.has_key?(:dacl_inherits)
          security_information |= (args[:dacl_inherits] ? UNPROTECTED_DACL_SECURITY_INFORMATION : PROTECTED_DACL_SECURITY_INFORMATION)
        end
        if args.has_key?(:sacl_inherits)
          security_information |= (args[:sacl_inherits] ? UNPROTECTED_SACL_SECURITY_INFORMATION : PROTECTED_SACL_SECURITY_INFORMATION)
        end

        hr = SetNamedSecurityInfoW(path.to_wstring, type, security_information, owner, group, dacl, sacl)
        if hr != ERROR_SUCCESS
          Chef::ReservedNames::Win32::Error.raise!
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
        present = !security_descriptor.null? if present == nil

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
        present = !security_descriptor.null? if present == nil

        unless SetSecurityDescriptorSacl(security_descriptor, present, acl, defaulted)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def self.with_privileges(*privilege_names)
        # Set privileges
        token = open_process_token(Chef::ReservedNames::Win32::Process.get_current_process, TOKEN_READ | TOKEN_ADJUST_PRIVILEGES)
        old_privileges = token.enable_privileges(*privilege_names)

        # Let the caller do their privileged stuff
        begin
          yield
        ensure
          # Set privileges back to what they were before
          token.adjust_privileges(old_privileges)
        end
      end
    end
  end
end

require 'chef/win32/security/ace'
require 'chef/win32/security/acl'
require 'chef/win32/security/securable_object'
require 'chef/win32/security/security_descriptor'
require 'chef/win32/security/sid'
