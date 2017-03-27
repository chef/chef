#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Matt Wrock <matt@mattwrock.com>
# Copyright:: Copyright 2011-2016, Chef Software, Inc.
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

require "win32/registry" if RUBY_PLATFORM =~ /mswin|mingw32|windows/

class Chef
  class Provider
    class Package
      class Windows
        class RegistryUninstallEntry

          def self.find_entries(package_name)
            Chef::Log.debug("Finding uninstall entries for #{package_name}")
            entries = []
            [
              [::Win32::Registry::HKEY_LOCAL_MACHINE, (::Win32::Registry::Constants::KEY_READ | 0x0100)],
              [::Win32::Registry::HKEY_LOCAL_MACHINE, (::Win32::Registry::Constants::KEY_READ | 0x0200)],
              [::Win32::Registry::HKEY_CURRENT_USER],
            ].each do |hkey|
              desired = hkey.length > 1 ? hkey[1] : ::Win32::Registry::Constants::KEY_READ
              begin
                ::Win32::Registry.open(hkey[0], UNINSTALL_SUBKEY, desired) do |reg|
                  reg.each_key do |key, _wtime|
                    begin
                      entry = reg.open(key, desired)
                      display_name = read_registry_property(entry, "DisplayName")
                      if display_name == package_name
                        quiet_uninstall_string = RegistryUninstallEntry.read_registry_property(entry, "QuietUninstallString")
                        entries.push(quiet_uninstall_string_key?(quiet_uninstall_string, hkey, key, entry))
                      end
                    rescue ::Win32::Registry::Error => ex
                      Chef::Log.debug("Registry error opening key '#{key}' on node #{desired}: #{ex}")
                    end
                  end
                end
              rescue ::Win32::Registry::Error => ex
                Chef::Log.debug("Registry error opening hive '#{hkey[0]}' :: #{desired}: #{ex}")
              end
            end
            entries
          end

          def self.quiet_uninstall_string_key?(quiet_uninstall_string, hkey, key, entry)
            return RegistryUninstallEntry.new(hkey, key, entry) if quiet_uninstall_string.nil?
            RegistryUninstallEntry.new(hkey, key, entry, "QuietUninstallString")
          end

          def self.read_registry_property(data, property)
            data[property]
          rescue ::Win32::Registry::Error => ex
            Chef::Log.debug("Failure to read property '#{property}'")
            nil
          end

          def initialize(hive, key, registry_data, uninstall_key = "UninstallString")
            Chef::Log.debug("Creating uninstall entry for #{hive}::#{key}")
            @hive = hive
            @key = key
            @data = registry_data
            @display_name = RegistryUninstallEntry.read_registry_property(registry_data, "DisplayName")
            @display_version = RegistryUninstallEntry.read_registry_property(registry_data, "DisplayVersion")
            @uninstall_string = RegistryUninstallEntry.read_registry_property(registry_data, uninstall_key)
          end

          attr_reader :hive
          attr_reader :key
          attr_reader :display_name
          attr_reader :display_version
          attr_reader :uninstall_string
          attr_reader :data

          UNINSTALL_SUBKEY = 'Software\Microsoft\Windows\CurrentVersion\Uninstall'.freeze
        end
      end
    end
  end
end
