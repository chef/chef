#
# Author:: Jay Mundrawala(<jdm@chef.io>)
# Copyright:: Copyright 2015 Chef Software
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

require 'chef/win32/api/net'
require 'chef/win32/error'
require 'chef/mixin/wstring'

class Chef
  module ReservedNames::Win32
    class Net
      include Chef::ReservedNames::Win32::API::Error
      extend Chef::ReservedNames::Win32::API::Error

      include Chef::ReservedNames::Win32::API::Net
      extend Chef::ReservedNames::Win32::API::Net

      include Chef::Mixin::WideString
      extend Chef::Mixin::WideString

      def self.default_user_info_3
        ui3 = USER_INFO_3.new.tap do |s|
          { usri3_name: nil,
            usri3_password: nil,
            usri3_password_age: 0,
            usri3_priv: 0,
            usri3_home_dir: nil,
            usri3_comment: nil,
            usri3_flags: UF_SCRIPT|UF_DONT_EXPIRE_PASSWD|UF_NORMAL_ACCOUNT,
            usri3_script_path: nil,
            usri3_auth_flags: 0,
            usri3_full_name: nil,
            usri3_usr_comment: nil,
            usri3_parms: nil,
            usri3_workstations: nil,
            usri3_last_logon: 0,
            usri3_last_logoff: 0,
            usri3_acct_expires: -1,
            usri3_max_storage: -1,
            usri3_units_per_week: 0,
            usri3_logon_hours: nil,
            usri3_bad_pw_count: 0,
            usri3_num_logons: 0,
            usri3_logon_server: nil,
            usri3_country_code: 0,
            usri3_code_page: 0,
            usri3_user_id: 0,
            usri3_primary_group_id: DOMAIN_GROUP_RID_USERS,
            usri3_profile: nil,
            usri3_home_dir_drive: nil,
            usri3_password_expired: 0
          }.each do |(k,v)|
            s.set(k, v)
          end
        end
      end

      def self.net_api_error!(code)
        msg = case code
        when NERR_InvalidComputer
          "The user does not have access to the requested information."
        when NERR_NotPrimary
          "The operation is allowed only on the primary domain controller of the domain."
        when NERR_SpeGroupOp
          "This operation is not allowed on this special group."
        when NERR_LastAdmin
          "This operation is not allowed on the last administrative account."
        when NERR_BadUsername
          "The user name or group name parameter is invalid."
        when NERR_BadPassword
          "The password parameter is invalid."
        when NERR_UserNotFound
          raise Chef::Exceptions::UserIDNotFound, code
        when NERR_PasswordTooShort
          <<END
The password is shorter than required. (The password could also be too
long, be too recent in its change history, not have enough unique characters,
or not meet another password policy requirement.)
END
        when NERR_GroupNotFound
          "The group name could not be found."
        when ERROR_ACCESS_DENIED
          "The user does not have access to the requested information."
        else
          "Received unknown error code (#{code})"
        end

        raise Chef::Exceptions::Win32NetAPIError.new(msg, code)
      end

      def self.net_local_group_add(server_name, group_name)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        buf = LOCALGROUP_INFO_0.new
        buf[:lgrpi0_name] = FFI::MemoryPointer.from_string(group_name)

        rc = NetLocalGroupAdd(server_name, 0, buf, nil)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_local_group_del(server_name, group_name)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        rc = NetLocalGroupDel(server_name, group_name)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_local_group_get_members(server_name, group_name)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        buf = FFI::MemoryPointer.new(:pointer)
        entries_read_ptr = FFI::MemoryPointer.new(:long)
        total_read_ptr = FFI::MemoryPointer.new(:long)
        resume_handle_ptr = FFI::MemoryPointer.new(:pointer)

        rc = ERROR_MORE_DATA
        group_members = []
        while rc == ERROR_MORE_DATA
          rc = NetLocalGroupGetMembers(
            server_name, group_name, 0, buf, -1,
            entries_read_ptr, total_read_ptr, resume_handle_ptr
          )

          nread = entries_read_ptr.read_long
          nread.times do |i|
            member = LOCALGROUP_MEMBERS_INFO_0.new(buf.read_pointer +
                       (i * LOCALGROUP_MEMBERS_INFO_0.size))
            member_sid = Chef::ReservedNames::Win32::Security::SID.new(member[:lgrmi0_sid])
            group_members << member_sid.to_s
          end
          NetApiBufferFree(buf.read_pointer)
        end

        if rc != NERR_Success
          net_api_error!(rc)
        end

        group_members
      end

      def self.net_user_add_l3(server_name, args)
        buf = default_user_info_3

        args.each do |k, v|
          buf.set(k, v)
        end

        server_name = wstring(server_name)

        rc = NetUserAdd(server_name, 3, buf, nil)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_user_get_info_l3(server_name, user_name)
        server_name = wstring(server_name)
        user_name = wstring(user_name)

        ui3_p = FFI::MemoryPointer.new(:pointer)

        rc = NetUserGetInfo(server_name, user_name, 3, ui3_p)

        if rc != NERR_Success
          net_api_error!(rc)
        end

        ui3 = USER_INFO_3.new(ui3_p.read_pointer).as_ruby

        rc = NetApiBufferFree(ui3_p.read_pointer)

        if rc != NERR_Success
          net_api_error!(rc)
        end

        ui3
      end

      def self.net_user_set_info_l3(server_name, user_name, info)
        buf = default_user_info_3

        info.each do |k, v|
          buf.set(k, v)
        end

        server_name = wstring(server_name)
        user_name = wstring(user_name)

        rc = NetUserSetInfo(server_name, user_name, 3, buf, nil)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_user_del(server_name, user_name)
        server_name = wstring(server_name)
        user_name = wstring(user_name)

        rc = NetUserDel(server_name, user_name)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_local_group_add_member(server_name, group_name, domain_user)
        server_name = wstring(server_name)
        group_name = wstring(group_name)
        domain_user = wstring(domain_user)

        buf = LOCALGROUP_MEMBERS_INFO_3.new
        buf[:lgrmi3_domainandname] = FFI::MemoryPointer.from_string(domain_user)

        rc = NetLocalGroupAddMembers(server_name, group_name, 3, buf, 1)

        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.members_to_lgrmi3(members)
        buf = FFI::MemoryPointer.new(LOCALGROUP_MEMBERS_INFO_3, members.size)
        members.size.times.collect do |i|
          member_info = LOCALGROUP_MEMBERS_INFO_3.new(
            buf + i * LOCALGROUP_MEMBERS_INFO_3.size)
          member_info[:lgrmi3_domainandname] = FFI::MemoryPointer.from_string(wstring(members[i]))
          member_info
        end
      end

      def self.net_local_group_add_members(server_name, group_name, members)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        lgrmi3s = members_to_lgrmi3(members)
        rc = NetLocalGroupAddMembers(
          server_name, group_name, 3, lgrmi3s[0], members.size)

        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_local_group_set_members(server_name, group_name, members)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        lgrmi3s = members_to_lgrmi3(members)
        rc = NetLocalGroupSetMembers(
          server_name, group_name, 3, lgrmi3s[0], members.size)

        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_local_group_del_members(server_name, group_name, members)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        lgrmi3s = members_to_lgrmi3(members)
        rc = NetLocalGroupDelMembers(
          server_name, group_name, 3, lgrmi3s[0], members.size)

        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_use_del(server_name, use_name, force=:use_noforce)
        server_name = wstring(server_name)
        use_name = wstring(use_name)
        force_const = case force
                      when :use_noforce
                        USE_NOFORCE
                      when :use_force
                        USE_FORCE
                      when :use_lots_of_force
                        USE_LOTS_OF_FORCE
                      else
                        raise ArgumentError, "force must be one of [:use_noforce, :use_force, or :use_lots_of_force]"
                      end

        rc = NetUseDel(server_name, use_name, force_const)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end

      def self.net_use_get_info_l2(server_name, use_name)
        server_name = wstring(server_name)
        use_name = wstring(use_name)
        ui2_p = FFI::MemoryPointer.new(:pointer)

        rc = NetUseGetInfo(server_name, use_name, 2, ui2_p)
        if rc != NERR_Success
          net_api_error!(rc)
        end

        ui2 = USE_INFO_2.new(ui2_p.read_pointer).as_ruby
        NetApiBufferFree(ui2_p.read_pointer)

        ui2
      end

      def self.net_use_add_l2(server_name, ui2_hash)
        server_name = wstring(server_name)
        group_name = wstring(group_name)

        buf = USE_INFO_2.new

        ui2_hash.each do |(k,v)|
          buf.set(k,v)
        end

        rc = NetUseAdd(server_name, 2, buf, nil)
        if rc != NERR_Success
          net_api_error!(rc)
        end
      end
    end
    NetUser = Net # For backwards compatibility
  end
end
