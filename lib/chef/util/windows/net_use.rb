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

#the Win32 Volume APIs do not support mapping network drives. not supported by WMI either.
#see also: WNetAddConnection2 and WNetAddConnection3
#see also cmd.exe: net use /?

require 'chef/util/windows'
require 'chef/win32/net'

class Chef::Util::Windows::NetUse < Chef::Util::Windows
  def initialize(localname)
    @use_name = localname
  end

  def to_ui2_struct(use_info)
    use_info.inject({}) do |memo, (k,v)|
      memo["ui2_#{k}".to_sym] = v
      memo
    end
  end

  def add(args)
    if args.class == String
      remote = args
      args = Hash.new
      args[:remote] = remote
    end
    args[:local] ||= use_name
    ui2_hash = to_ui2_struct(args)

    begin
      Chef::ReservedNames::Win32::Net.net_use_add_l2(nil, ui2_hash)
    rescue Chef::Exceptions::Win32APIError => e
      raise ArgumentError, e
    end
  end

  def from_use_info_struct(ui2_hash)
    ui2_hash.inject({}) do |memo, (k,v)|
      memo[k.to_s.sub('ui2_', '').to_sym] = v
      memo
    end
  end

  def get_info
    begin
      ui2 = Chef::ReservedNames::Win32::Net.net_use_get_info_l2(nil, use_name)
      from_use_info_struct(ui2)
    rescue Chef::Exceptions::Win32APIError => e
      raise ArgumentError, e
    end
  end

  def device
    get_info()[:remote]
  end

  def delete
    begin
      Chef::ReservedNames::Win32::Net.net_use_del(nil, use_name, :use_noforce)
    rescue Chef::Exceptions::Win32APIError => e
      raise ArgumentError, e
    end
  end

  def use_name
    @use_name
  end
end
