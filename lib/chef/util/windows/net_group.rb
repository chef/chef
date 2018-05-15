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
require "chef/win32/net"

#wrapper around a subset of the NetGroup* APIs.
class Chef::Util::Windows::NetGroup

  private

  def groupname
    @groupname
  end

  public

  def initialize(groupname)
    @groupname = groupname
  end

  def local_get_members
    Chef::ReservedNames::Win32::NetUser.net_local_group_get_members(nil, groupname)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def local_add
    Chef::ReservedNames::Win32::NetUser.net_local_group_add(nil, groupname)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def local_set_members(members)
    Chef::ReservedNames::Win32::NetUser.net_local_group_set_members(nil, groupname, members)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def local_add_members(members)
    Chef::ReservedNames::Win32::NetUser.net_local_group_add_members(nil, groupname, members)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def local_delete_members(members)
    Chef::ReservedNames::Win32::NetUser.net_local_group_del_members(nil, groupname, members)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def local_delete
    Chef::ReservedNames::Win32::NetUser.net_local_group_del(nil, groupname)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end
end
