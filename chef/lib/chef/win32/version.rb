#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
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

require 'chef/win32/api'
require 'chef/win32/api/system'

class Chef
  module ReservedNames::Win32
    class Version
      include Chef::ReservedNames::Win32::API::Macros
      include Chef::ReservedNames::Win32::API::System

      # Ruby implementation of
      # http://msdn.microsoft.com/en-us/library/ms724833(v=vs.85).aspx
      # http://msdn.microsoft.com/en-us/library/ms724358(v=vs.85).aspx

      WIN_VERSIONS = {
        "Windows 7" => {:major => 6, :minor => 1, :callable => lambda{ @product_type == VER_NT_WORKSTATION }},
        "Windows Server 2008 R2" => {:major => 6, :minor => 1, :callable => lambda{ @product_type != VER_NT_WORKSTATION }},
        "Windows Server 2008" => {:major => 6, :minor => 0, :callable => lambda{ @product_type != VER_NT_WORKSTATION }},
        "Windows Vista" => {:major => 6, :minor => 0, :callable => lambda{ @product_type == VER_NT_WORKSTATION }},
        "Windows Server 2003 R2" => {:major => 5, :minor => 2, :callable => lambda{ get_system_metrics(SM_SERVERR2) != 0 }},
        "Windows Home Server" => {:major => 5, :minor => 2, :callable => lambda{  (@suite_mask & VER_SUITE_WH_SERVER) == VER_SUITE_WH_SERVER }},
        "Windows Server 2003" => {:major => 5, :minor => 2, :callable => lambda{ get_system_metrics(SM_SERVERR2) == 0 }},
        "Windows XP" => {:major => 5, :minor => 1},
        "Windows 2000" => {:major => 5, :minor => 0}
      }

      def initialize
        @major_version, @minor_version, @build_number = get_version
        ver_info = get_version_ex
        @product_type = ver_info[:w_product_type]
        @suite_mask = ver_info[:w_suite_mask]
        @sp_major_version = ver_info[:w_service_pack_major]
        @sp_minor_version = ver_info[:w_service_pack_minor]
        @sku = get_product_info(@major_version, @minor_version, @sp_major_version, @sp_minor_version)
      end

      marketing_names = Array.new

      # General Windows checks
      WIN_VERSIONS.each do |k,v|
        method_name = "#{k.gsub(/\s/, '_').downcase}?"
        define_method(method_name) do
          (@major_version == v[:major]) &&
          (@minor_version == v[:minor]) &&
          (v[:callable] ? v[:callable].call : true)
        end
        marketing_names << [k, method_name]
      end

      define_method(:marketing_name) do
        marketing_names.each do |mn|
          break mn[0] if self.send(mn[1])
        end
      end

      # Server Type checks
      %w{ cluster core datacenter }.each do |m|
        define_method("#{m}?") do
          self.class.constants.any? do |c|
            (self.class.const_get(c) == @sku) &&
              (c.to_s =~ /#{m}/i )
          end
          # if @sku
          #   !(PRODUCT_TYPE[@sku][:name] =~ /#{m}/i).nil?
          # else
          #   false
          # end
        end
      end

      private

      def get_version
        version = GetVersion()
        major = LOBYTE(LOWORD(version))
        minor = HIBYTE(LOWORD(version))
        build = version < 0x80000000 ? HIWORD(version) : 0
        [major, minor, build]
      end

      def get_version_ex
        lp_version_info = OSVERSIONINFOEX.new
        lp_version_info[:dw_os_version_info_size] = OSVERSIONINFOEX.size
        unless GetVersionExW(lp_version_info)
          Chef::ReservedNames::Win32::Error.raise!
        end
        lp_version_info
      end

      def get_product_info(major, minor, sp_major, sp_minor)
        out = FFI::MemoryPointer.new(:uint32)
        GetProductInfo(major, minor, sp_major, sp_minor, out)
        out.get_uint(0)
      end

      def get_system_metrics(n_index)
        GetSystemMetrics(n_index)
      end

    end
  end
end
