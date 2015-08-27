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

  private

  USE_NOFORCE = 0
  USE_FORCE = 1
  USE_LOTS_OF_FORCE = 2 #every windows API should support this flag

  USE_INFO_2 = [
    [:local, nil],
    [:remote, nil],
    [:password, nil],
    [:status, 0],
    [:asg_type, 0],
    [:refcount, 0],
    [:usecount, 0],
    [:username, nil],
    [:domainname, nil]
  ]

  USE_INFO_2_TEMPLATE =
    USE_INFO_2.collect { |field| field[1].class == Fixnum ? 'i' : 'L' }.join

  SIZEOF_USE_INFO_2 = #sizeof(USE_INFO_2)
    USE_INFO_2.inject(0) do |sum, item|
      sum + (item[1].class == Fixnum ? 4 : PTR_SIZE)
    end

  def use_info_2(args)
    USE_INFO_2.collect { |field|
      args.include?(field[0]) ? args[field[0]] : field[1]
    }
  end

  def use_info_2_pack(use)
    use.collect { |v|
      v.class == Fixnum ? v : str_to_ptr(multi_to_wide(v))
    }.pack(USE_INFO_2_TEMPLATE)
  end

  def use_info_2_unpack(buffer)
    use = Hash.new
    USE_INFO_2.each_with_index do |field,offset|
      use[field[0]] = field[1].class == Fixnum ?
      dword_to_i(buffer, offset) : lpwstr_to_s(buffer, offset)
    end
    use
  end

  public

  def initialize(localname)
    @localname = localname
    @name = multi_to_wide(localname)
    @use_name = localname
  end

  def add(args)
    if args.class == String
      remote = args
      args = Hash.new
      args[:remote] = remote
    end
    args[:local] ||= @localname
    use = use_info_2(args)
    buffer = use_info_2_pack(use)
    rc = NetUseAdd.call(nil, 2, buffer, nil)
    if rc != NERR_Success
      raise ArgumentError, get_last_error(rc)
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
