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
class Chef
  module ReservedNames::Win32
    class NetUser
      include Chef::ReservedNames::Win32::API::Error
      extend Chef::ReservedNames::Win32::API::Error

      include Chef::ReservedNames::Win32::API::Net
      extend Chef::ReservedNames::Win32::API::Net

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
        formatted_message = ""
        formatted_message << "---- Begin Win32 API output ----\n"
        formatted_message << "Net Api Error Code: #{code}\n"

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
          "The user name could not be found."
        when NERR_PasswordTooShort
          <<END
The password is shorter than required. (The password could also be too
long, be too recent in its change history, not have enough unique characters,
or not meet another password policy requirement.)
END
        when ERROR_ACCESS_DENIED
          "The user does not have access to the requested information."
        else
          "Received unknown error code (#{code})"
        end

        formatted_message << "Net Api Error Message: #{msg}\n"
        formatted_message << "---- End Win32 API output ----\n"
        raise Chef::Exceptions::Win32APIError, msg + "\n" + formatted_message
      end

      def self.net_user_add_l3(server_name, args)
        param_err = FFI::Buffer.new(:long)
        buf = default_user_info_3

        args.each do |k, v|
          buf.set(k, v)
        end

        server_name = server_name.to_wstring if server_name

        rc = NetUserAdd(server_name, 3, buf, param_err)
        if rc != NERR_Success
          if Chef::ReservedNames::Win32::Error.get_last_error != 0
            Chef::ReservedNames::Win32::Error.raise!
          else
            net_api_error!(rc)
          end
        end
      end

      def self.net_local_group_add_member(server_name, group_name, domain_user)
        server_name = server_name.to_wstring if server_name
        group_name = group_name.to_wstring
        domain_user = domain_user.to_wstring

        buf = LOCALGROUP_MEMBERS_INFO_3.new
        buf[:lgrmi3_domainandname] = FFI::MemoryPointer.from_string(domain_user)

        rc = NetLocalGroupAddMembers(server_name, group_name, 3, buf, 1)

        if rc != NERR_Success
          if Chef::ReservedNames::Win32::Error.get_last_error != 0
            Chef::ReservedNames::Win32::Error.raise!
          else
            net_api_error!(rc)
          end
        end
      end

    end
  end
end
