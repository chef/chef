#
# Author:: Greg Zapp (<greg.zapp@gmail.com>)
#
# Copyright:: 2015-2018, Chef Software, Inc
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

require "chef/resource"
require "chef/json_compat"

class Chef
  class Resource
    class WindowsFeaturePowershell < Chef::Resource
      resource_name :windows_feature_powershell
      provides :windows_feature_powershell

      description "Use the windows_feature_powershell resource to add, remove or"\
                  " delete Windows features and roles using PowerShell. This resource"\
                  " offers significant speed benefits over the windows_feature_dism resource,"\
                  " but requires installing the Remote Server Administration Tools on"\
                  " non-server releases of Windows"
      introduced "14.0"

      property :feature_name, [Array, String],
               description: "The name of the feature/role(s) to install if it differs from the resource name.",
               coerce: proc { |x| x.is_a?(String) ? x.split(/\s*,\s*/) : x },
               name_property: true

      property :source, String,
               description: "Use a local repository for the feature install."

      property :all, [TrueClass, FalseClass],
               description: "Install all sub features. This is equivalent to using the"\
                            " -InstallAllSubFeatures switch with Add-WindowsFeature.",
               default: false

      property :timeout, Integer,
               description: "Specifies a timeout (in seconds) for feature install.",
               default: 600

      property :management_tools, [TrueClass, FalseClass],
               description: "",
               default: false

      include Chef::Mixin::PowershellOut

      action :install do
        description "Install a Windows role/feature using PowerShell"

        reload_cached_powershell_data unless node["powershell_features_cache"]
        fail_if_unavailable # fail if the features don't exist
        fail_if_removed # fail if the features are in removed state

        Chef::Log.debug("Windows features needing installation: #{features_to_install.empty? ? 'none' : features_to_install.join(',')}")
        unless features_to_install.empty?
          converge_by("install Windows feature#{'s' if features_to_install.count > 1} #{features_to_install.join(',')}") do
            install_command = "#{install_feature_cmdlet} #{features_to_install.join(',')}"
            install_command << " -IncludeAllSubFeature"  if new_resource.all
            if node["os_version"].to_f < 6.2 && (new_resource.source || new_resource.management_tools)
              Chef::Log.warn("The 'source' and 'management_tools' properties are not available on Windows 2012R2 or great. Skipping these properties!")
            else
              install_command << " -Source \"#{new_resource.source}\"" if new_resource.source
              install_command << " -IncludeManagementTools" if new_resource.management_tools
            end

            cmd = powershell_out!(install_command, timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)

            reload_cached_powershell_data # Reload cached powershell feature state
          end
        end
      end

      action :remove do
        description "Remove a Windows role/feature using PowerShell"

        reload_cached_powershell_data unless node["powershell_features_cache"]

        Chef::Log.debug("Windows features needing removal: #{features_to_remove.empty? ? 'none' : features_to_remove.join(',')}")

        unless features_to_remove.empty?
          converge_by("remove Windows feature#{'s' if features_to_remove.count > 1} #{features_to_remove.join(',')}") do
            cmd = powershell_out!("#{remove_feature_cmdlet} #{features_to_remove.join(',')}", timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)

            reload_cached_powershell_data # Reload cached powershell feature state
          end
        end
      end

      action :delete do
        description "Remove a Windows role/feature from the image using Powershell"

        fail_if_delete_unsupported

        reload_cached_powershell_data unless node["powershell_features_cache"]

        fail_if_unavailable # fail if the features don't exist

        Chef::Log.debug("Windows features needing deletion: #{features_to_delete.empty? ? 'none' : features_to_delete.join(',')}")

        unless features_to_delete.empty?
          converge_by("delete Windows feature#{'s' if features_to_delete.count > 1} #{features_to_delete.join(',')} from the image") do
            cmd = powershell_out!("Uninstall-WindowsFeature #{features_to_delete.join(',')} -Remove", timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)

            reload_cached_powershell_data # Reload cached powershell feature state
          end
        end
      end

      action_class do
        def install_feature_cmdlet
          node["os_version"].to_f < 6.2 ? "Import-Module ServerManager; Add-WindowsFeature" : "Install-WindowsFeature"
        end

        def remove_feature_cmdlet
          node["os_version"].to_f < 6.2 ? "Import-Module ServerManager; Remove-WindowsFeature" : "Uninstall-WindowsFeature"
        end

        # @return [Array] features the user has requested to install which need installation
        def features_to_install
          # the intersection of the features to install & disabled features are what needs installing
          @install ||= new_resource.feature_name & node["powershell_features_cache"]["disabled"]
        end

        # @return [Array] features the user has requested to remove which need removing
        def features_to_remove
          # the intersection of the features to remove & enabled features are what needs removing
          @remove ||= new_resource.feature_name & node["powershell_features_cache"]["enabled"]
        end

        # @return [Array] features the user has requested to delete which need deleting
        def features_to_delete
          # the intersection of the features to remove & enabled/disabled features are what needs removing
          @remove ||= begin
            all_available = node["powershell_features_cache"]["enabled"] +
              node["powershell_features_cache"]["disabled"]
            new_resource.feature_name & all_available
          end
        end

        # if any features are not supported on this release of Windows or
        # have been deleted raise with a friendly message. At one point in time
        # we just warned, but this goes against the behavior of ever other package
        # provider in Chef and it isn't clear what you'd want if you passed an array
        # and some features were available and others were not.
        # @return [void]
        def fail_if_unavailable
          all_available = node["powershell_features_cache"]["enabled"] +
            node["powershell_features_cache"]["disabled"] +
            node["powershell_features_cache"]["removed"]

          # the difference of desired features to install to all features is what's not available
          unavailable = (new_resource.feature_name - all_available)
          raise "The Windows feature#{'s' if unavailable.count > 1} #{unavailable.join(',')} #{unavailable.count > 1 ? 'are' : 'is'} not available on this version of Windows. Run 'Get-WindowsFeature' to see the list of available feature names." unless unavailable.empty?
        end

        # run Get-WindowsFeature to get a list of all available features and their state
        # and save that to the node at node.override level.
        # @return [void]
        def reload_cached_powershell_data
          Chef::Log.debug("Caching Windows features available via Get-WindowsFeature.")
          node.override["powershell_features_cache"] = Mash.new
          node.override["powershell_features_cache"]["enabled"] = []
          node.override["powershell_features_cache"]["disabled"] = []
          node.override["powershell_features_cache"]["removed"] = []

          parsed_feature_list.each do |feature_details_raw|
            case feature_details_raw["InstallState"]
            when 5 # matches 'Removed' InstallState
              add_to_feature_mash("removed", feature_details_raw["Name"])
            when 1, 3 # matches 'Installed' or 'InstallPending' states
              add_to_feature_mash("enabled", feature_details_raw["Name"])
            when 0, 2 # matches 'Available' or 'UninstallPending' states
              add_to_feature_mash("disabled", feature_details_raw["Name"])
            end
          end
          Chef::Log.debug("The powershell cache contains\n#{node['powershell_features_cache']}")
        end

        # fetch the list of available feature names and state in JSON and parse the JSON
        def parsed_feature_list
          # Grab raw feature information from dism command line
          raw_list_of_features = if node["os_version"].to_f < 6.2
                                   powershell_out!("Import-Module ServerManager; Get-WindowsFeature | Select-Object -Property Name,InstallState | ConvertTo-Json -Compress", timeout: new_resource.timeout).stdout
                                 else
                                   powershell_out!("Get-WindowsFeature | Select-Object -Property Name,InstallState | ConvertTo-Json -Compress", timeout: new_resource.timeout).stdout
                                 end

          Chef::JSONCompat.from_json(raw_list_of_features)
        end

        # add the features values to the appropriate array
        # @return [void]
        def add_to_feature_mash(feature_type, feature_details)
          node.override["powershell_features_cache"][feature_type] << feature_details
        end

        # Fail if any of the packages are in a removed state
        # @return [void]
        def fail_if_removed
          return if new_resource.source # if someone provides a source then all is well
          if node["os_version"].to_f > 6.2
            return if registry_key_exists?('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing') && registry_value_exists?('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing', name: "LocalSourcePath") # if source is defined in the registry, still fine
          end
          removed = new_resource.feature_name & node["powershell_features_cache"]["removed"]
          raise "The Windows feature#{'s' if removed.count > 1} #{removed.join(',')} #{removed.count > 1 ? 'are' : 'is'} have been removed from the host and cannot be installed." unless removed.empty?
        end

        # Fail unless we're on windows 8+ / 2012+ where deleting a feature is supported
        def fail_if_delete_unsupported
          raise Chef::Exceptions::UnsupportedAction, "#{self} :delete action not support on Windows releases before Windows 8/2012. Cannot continue!" unless node["platform_version"].to_f >= 6.2
        end
      end
    end
  end
end
