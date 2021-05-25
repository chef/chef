#
# Author:: Greg Zapp (<greg.zapp@gmail.com>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../json_compat"
require_relative "../resource"
require_relative "../platform/query_helpers"

class Chef
  class Resource
    class WindowsFeaturePowershell < Chef::Resource
      unified_mode true

      provides(:windows_feature_powershell) { true }

      description "Use the **windows_feature_powershell** resource to add, remove, or entirely delete Windows features and roles using PowerShell. This resource offers significant speed benefits over the windows_feature_dism resource, but requires installation of the Remote Server Administration Tools on non-server releases of Windows."
      introduced "14.0"
      examples <<~DOC
      **Add the SMTP Server feature**:

      ```ruby
      windows_feature_powershell "smtp-server" do
        action :install
        all true
      end
      ```

      **Install multiple features using one resource**:

      ```ruby
      windows_feature_powershell ['Web-Asp-Net45', 'Web-Net-Ext45'] do
        action :install
      end
      ```

      **Install the Network Policy and Access Service feature**:

      ```ruby
      windows_feature_powershell 'NPAS' do
        action :install
        management_tools true
      end
      ```
      DOC

      property :feature_name, [Array, String],
        description: "The name of the feature(s) or role(s) to install if they differ from the resource block's name.",
        coerce: proc { |x| to_formatted_array(x) },
        name_property: true

      property :source, String,
        description: "Specify a local repository for the feature install."

      property :all, [TrueClass, FalseClass],
        description: "Install all subfeatures. When set to `true`, this is the equivalent of specifying the `-InstallAllSubFeatures` switch with `Add-WindowsFeature`.",
        default: false

      property :timeout, Integer,
        description: "Specifies a timeout (in seconds) for the feature installation.",
        default: 600,
        desired_state: false

      property :management_tools, [TrueClass, FalseClass],
        description: "Install all applicable management tools for the roles, role services, or features.",
        default: false

      # Converts strings of features into an Array. Array objects are lowercased
      # @return [Array] array of features
      def to_formatted_array(x)
        x = x.split(/\s*,\s*/) if x.is_a?(String) # split multiple forms of a comma separated list

        # features aren't case sensitive so let's compare in lowercase
        x.map(&:downcase)
      end

      action :install, description: "Install a Windows role or feature using PowerShell." do
        reload_cached_powershell_data unless node["powershell_features_cache"]
        fail_if_unavailable # fail if the features don't exist
        fail_if_removed # fail if the features are in removed state

        Chef::Log.debug("Windows features needing installation: #{features_to_install.empty? ? "none" : features_to_install.join(",")}")
        unless features_to_install.empty?
          converge_by("install Windows feature#{"s" if features_to_install.count > 1} #{features_to_install.join(",")}") do
            install_command = "Install-WindowsFeature #{features_to_install.join(",")}"
            install_command << " -IncludeAllSubFeature" if new_resource.all
            install_command << " -Source \"#{new_resource.source}\"" if new_resource.source
            install_command << " -IncludeManagementTools" if new_resource.management_tools

            cmd = powershell_out!(install_command, timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)

            reload_cached_powershell_data # Reload cached powershell feature state
          end
        end
      end

      action :remove, description: "Remove a Windows role or feature using PowerShell." do
        reload_cached_powershell_data unless node["powershell_features_cache"]

        Chef::Log.debug("Windows features needing removal: #{features_to_remove.empty? ? "none" : features_to_remove.join(",")}")

        unless features_to_remove.empty?
          converge_by("remove Windows feature#{"s" if features_to_remove.count > 1} #{features_to_remove.join(",")}") do
            cmd = powershell_out!("Uninstall-WindowsFeature #{features_to_remove.join(",")}", timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)

            reload_cached_powershell_data # Reload cached powershell feature state
          end
        end
      end

      action :delete, description: "Delete a Windows role or feature from the image using PowerShell." do
        reload_cached_powershell_data unless node["powershell_features_cache"]

        fail_if_unavailable # fail if the features don't exist

        Chef::Log.debug("Windows features needing deletion: #{features_to_delete.empty? ? "none" : features_to_delete.join(",")}")

        unless features_to_delete.empty?
          converge_by("delete Windows feature#{"s" if features_to_delete.count > 1} #{features_to_delete.join(",")} from the image") do
            cmd = powershell_out!("Uninstall-WindowsFeature #{features_to_delete.join(",")} -Remove", timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)

            reload_cached_powershell_data # Reload cached powershell feature state
          end
        end
      end

      action_class do
        # @return [Array] features the user has requested to install which need installation
        def features_to_install
          # the intersection of the features to install & disabled/removed features are what needs installing
          @features_to_install ||= begin
            features = node["powershell_features_cache"]["disabled"]
            features |= node["powershell_features_cache"]["removed"] if new_resource.source
            new_resource.feature_name & features
          end
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
          raise "The Windows feature#{"s" if unavailable.count > 1} #{unavailable.join(",")} #{unavailable.count > 1 ? "are" : "is"} not available on this version of Windows. Run 'Get-WindowsFeature' to see the list of available feature names." unless unavailable.empty?
        end

        # run Get-WindowsFeature to get a list of all available features and their state
        # and save that to the node at node.override level.
        # @return [void]
        def reload_cached_powershell_data
          Chef::Log.debug("Caching Windows features available via Get-WindowsFeature.")

          #
          # FIXME FIXME FIXME
          # The node object should not be used for caching state like this and this is not a public API and may break.
          # FIXME FIXME FIXME
          #
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
          Chef::Log.debug("The powershell cache contains\n#{node["powershell_features_cache"]}")
        end

        # fetch the list of available feature names and state in JSON and parse the JSON
        def parsed_feature_list
          # Grab raw feature information from WindowsFeature
          raw_list_of_features = powershell_out!("Get-WindowsFeature | Select-Object -Property Name,InstallState | ConvertTo-Json -Compress", timeout: new_resource.timeout).stdout

          Chef::JSONCompat.from_json(raw_list_of_features)
        end

        # add the features values to the appropriate array
        # @return [void]
        def add_to_feature_mash(feature_type, feature_details)
          # add the lowercase feature name to the mash so we can compare it lowercase later
          node.override["powershell_features_cache"][feature_type] << feature_details.downcase
        end

        # Fail if any of the packages are in a removed state
        # @return [void]
        def fail_if_removed
          return if new_resource.source # if someone provides a source then all is well
          return if registry_key_exists?('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing') && registry_value_exists?('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing', name: "LocalSourcePath") # if source is defined in the registry, still fine

          removed = new_resource.feature_name & node["powershell_features_cache"]["removed"]
          raise "The Windows feature#{"s" if removed.count > 1} #{removed.join(",")} #{removed.count > 1 ? "are" : "is"} removed from the host and cannot be installed." unless removed.empty?
        end
      end
    end
  end
end
