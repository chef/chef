#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require 'chef/util/windows'
require 'chef/win32/net'

#wrapper around a subset of the NetGroup* APIs.
#nothing Chef specific, but not complete enough to be its own gem, so util for now.
class Chef::Util::Windows::NetGroup < Chef::Util::Windows

  private

  def pack_str(s)
    [str_to_ptr(s)].pack('L')
  end

  def modify_members(members, func)
    buffer = 0.chr * (members.size * PTR_SIZE)
    members.each_with_index do |member,offset|
      buffer[offset*PTR_SIZE,PTR_SIZE] = pack_str(multi_to_wide(member))
    end
    rc = func.call(nil, @name, 3, buffer, members.size)
    if rc != NERR_Success
      raise ArgumentError, get_last_error(rc)
    end
  end

  public

  def initialize(groupname)
    @name = multi_to_wide(groupname)
    @groupname = groupname
  end

  def local_get_members
    begin
      Chef::ReservedNames::Win32::NetUser::net_local_group_get_members(nil, @groupname)
    rescue Chef::Exceptions::Win32NetAPIError => e
      raise ArgumentError, e.msg
    end
  end

  def local_add
    begin
      Chef::ReservedNames::Win32::NetUser::net_local_group_add(nil, @groupname)
    rescue Chef::Exceptions::Win32NetAPIError => e
      raise ArgumentError, e.msg
    end
  end

  def local_set_members(members)
    modify_members(members, NetLocalGroupSetMembers)
  end

  def local_add_members(members)
    modify_members(members, NetLocalGroupAddMembers)
  end

  def local_delete_members(members)
    modify_members(members, NetLocalGroupDelMembers)
  end

  def local_delete
    begin
      Chef::ReservedNames::Win32::NetUser::net_local_group_del(nil, @groupname)
    rescue Chef::Exceptions::Win32NetAPIError => e
      raise ArgumentError, e.msg
    end
  end
end
