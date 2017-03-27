#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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

require "chef/util/windows"
require "chef/exceptions"
require "chef/win32/net"
require "chef/win32/security"

#wrapper around a subset of the NetUser* APIs.
#nothing Chef specific, but not complete enough to be its own gem, so util for now.
class Chef::Util::Windows::NetUser < Chef::Util::Windows

  private

  NetUser = Chef::ReservedNames::Win32::NetUser
  Security = Chef::ReservedNames::Win32::Security

  USER_INFO_3_TRANSFORM = {
    name: :usri3_name,
    password: :usri3_password,
    password_age: :usri3_password_age,
    priv: :usri3_priv,
    home_dir: :usri3_home_dir,
    comment: :usri3_comment,
    flags: :usri3_flags,
    script_path: :usri3_script_path,
    auth_flags: :usri3_auth_flags,
    full_name: :usri3_full_name,
    user_comment: :usri3_usr_comment,
    parms: :usri3_parms,
    workstations: :usri3_workstations,
    last_logon: :usri3_last_logon,
    last_logoff: :usri3_last_logoff,
    acct_expires: :usri3_acct_expires,
    max_storage: :usri3_max_storage,
    units_per_week: :usri3_units_per_week,
    logon_hours: :usri3_logon_hours,
    bad_pw_count: :usri3_bad_pw_count,
    num_logons: :usri3_num_logons,
    logon_server: :usri3_logon_server,
    country_code: :usri3_country_code,
    code_page: :usri3_code_page,
    user_id: :usri3_user_id,
    primary_group_id: :usri3_primary_group_id,
    profile: :usri3_profile,
    home_dir_drive: :usri3_home_dir_drive,
    password_expired: :usri3_password_expired,
  }

  def transform_usri3(args)
    args.inject({}) do |memo, (k, v)|
      memo[USER_INFO_3_TRANSFORM[k]] = v
      memo
    end
  end

  def usri3_to_hash(usri3)
    t = USER_INFO_3_TRANSFORM.invert
    usri3.inject({}) do |memo, (k, v)|
      memo[t[k]] = v
      memo
    end
  end

  def set_info(args)
    rc = NetUser.net_user_set_info_l3(nil, @username, transform_usri3(args))
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  public

  def initialize(username)
    @username = username
  end

  LOGON32_PROVIDER_DEFAULT = Security::LOGON32_PROVIDER_DEFAULT
  LOGON32_LOGON_NETWORK = Security::LOGON32_LOGON_NETWORK
  #XXX for an extra painful alternative, see: http://support.microsoft.com/kb/180548
  def validate_credentials(passwd)
    token = Security.logon_user(@username, nil, passwd,
               LOGON32_LOGON_NETWORK, LOGON32_PROVIDER_DEFAULT)
    return true
  rescue Chef::Exceptions::Win32APIError
    return false
  end

  def get_info
    begin
      ui3 = NetUser.net_user_get_info_l3(nil, @username)
    rescue Chef::Exceptions::Win32APIError => e
      raise ArgumentError, e
    end
    usri3_to_hash(ui3)
  end

  def add(args)
    transformed_args = transform_usri3(args)
    NetUser.net_user_add_l3(nil, transformed_args)
    NetUser.net_local_group_add_member(nil, Chef::ReservedNames::Win32::Security::SID.BuiltinUsers.account_simple_name, args[:name])
  end

  # FIXME: yard with @yield
  def user_modify
    user = get_info
    user[:last_logon] = user[:units_per_week] = 0 #ignored as per USER_INFO_3 doc
    user[:logon_hours] = nil #PBYTE field; \0 == no changes
    yield(user)
    set_info(user)
  end

  def update(args)
    user_modify do |user|
      args.each do |key, val|
        user[key] = val
      end
    end
  end

  def delete
    NetUser.net_user_del(nil, @username)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def disable_account
    user_modify do |user|
      user[:flags] |= NetUser::UF_ACCOUNTDISABLE
      #This does not set the password to nil. It (for some reason) means to ignore updating the field.
      #See similar behavior for the logon_hours field documented at
      #http://msdn.microsoft.com/en-us/library/windows/desktop/aa371338%28v=vs.85%29.aspx
      user[:password] = nil
    end
  end

  def enable_account
    user_modify do |user|
      user[:flags] &= ~NetUser::UF_ACCOUNTDISABLE
      #This does not set the password to nil. It (for some reason) means to ignore updating the field.
      #See similar behavior for the logon_hours field documented at
      #http://msdn.microsoft.com/en-us/library/windows/desktop/aa371338%28v=vs.85%29.aspx
      user[:password] = nil
    end
  end

  def check_enabled
    (get_info()[:flags] & NetUser::UF_ACCOUNTDISABLE) != 0
  end
end
