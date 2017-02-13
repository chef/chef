#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

class Chef
  class Platform

    class << self
      def windows?
        ChefConfig.windows?
      end

      def windows_server_2003?
        # WMI startup shouldn't be performed unless we're on Windows.
        return false unless windows?
        require "wmi-lite/wmi"

        wmi = WmiLite::Wmi.new
        host = wmi.first_of("Win32_OperatingSystem")
        is_server_2003 = (host["version"] && host["version"].start_with?("5.2"))

        is_server_2003
      end

      def windows_nano_server?
        return false unless windows?
        require "win32/registry"

        # This method may be called before ohai runs (e.g., it may be used to
        # determine settings in config.rb). Chef::Win32::Registry.new uses
        # node attributes to verify the machine architecture which aren't
        # accessible before ohai runs.
        nano = nil
        key = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Server\\ServerLevels"
        access = ::Win32::Registry::KEY_QUERY_VALUE | 0x0100 # nano is 64-bit only
        begin
          ::Win32::Registry::HKEY_LOCAL_MACHINE.open(key, access) do |reg|
            nano = reg["NanoServer"]
          end
        rescue ::Win32::Registry::Error
          # If accessing the registry key failed, then we're probably not on
          # nano. Fail through.
        end
        nano == 1
      end

      def supports_msi?
        return false unless windows?
        require "win32/registry"

        key = "System\\CurrentControlSet\\Services\\msiserver"
        access = ::Win32::Registry::KEY_QUERY_VALUE

        begin
          ::Win32::Registry::HKEY_LOCAL_MACHINE.open(key, access) do |reg|
            true
          end
        rescue ::Win32::Registry::Error
          false
        end
      end

      def supports_powershell_execution_bypass?(node)
        node[:languages] && node[:languages][:powershell] &&
          node[:languages][:powershell][:version].to_i >= 3
      end

      def supports_dsc?(node)
        node[:languages] && node[:languages][:powershell] &&
          node[:languages][:powershell][:version].to_i >= 4
      end

      def supports_dsc_invoke_resource?(node)
        supports_dsc?(node) &&
          supported_powershell_version?(node, "5.0.10018.0")
      end

      def supports_refresh_mode_enabled?(node)
        supported_powershell_version?(node, "5.0.10586.0")
      end

      def dsc_refresh_mode_disabled?(node)
        require "chef/util/powershell/cmdlet"
        cmdlet = Chef::Util::Powershell::Cmdlet.new(node, "Get-DscLocalConfigurationManager", :object)
        metadata = cmdlet.run!.return_value
        metadata["RefreshMode"] == "Disabled"
      end

      def supported_powershell_version?(node, version_string)
        return false unless node[:languages] && node[:languages][:powershell]
        require "rubygems"
        Gem::Version.new(node[:languages][:powershell][:version]) >=
          Gem::Version.new(version_string)
      end

    end
  end
end
