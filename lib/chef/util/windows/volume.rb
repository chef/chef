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

#simple wrapper around Volume APIs. might be possible with WMI, but possibly more complex.

require "chef/win32/api/file"
require "chef/util/windows"

class Chef::Util::Windows::Volume < Chef::Util::Windows
  attr_reader :mount_point

  def initialize(name)
    name += "\\" unless name =~ /\\$/ #trailing slash required
    @mount_point = name
  end

  def device
    Chef::ReservedNames::Win32::File.get_volume_name_for_volume_mount_point(mount_point)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def delete
    Chef::ReservedNames::Win32::File.delete_volume_mount_point(mount_point)
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def add(args)
    Chef::ReservedNames::Win32::File.set_volume_mount_point(mount_point, args[:remote])
  rescue Chef::Exceptions::Win32APIError => e
    raise ArgumentError, e
  end

  def mount_point
    @mount_point
  end
end
