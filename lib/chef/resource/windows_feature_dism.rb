#
# Author:: Seth Chisamore (<schisamo@chef.io>)
#
# Copyright:: 2011-2018, Chef Software, Inc.
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

class Chef
  class Resource
    class WindowsFeatureDism < Chef::Resource
      resource_name :windows_feature_dism
      provides :windows_feature_dism

      description "Using the windows_feature_dism resource to add, remove or"\
                  " delete Windows features and roles using DISM"
      introduced "14.0"

      property :feature_name, [Array, String],
               description: "The name of the feature/role(s) to install if it differs from the resource name.",
               coerce: proc { |x| Array(x) },
               name_property: true

      property :source, String,
               description: "Use a local repository for the feature install."

      property :all, [true, false],
               description: "Install all sub features. This is the equivalent of specifying the /All switch to dism.exe",
               default: false

      property :timeout, Integer,
               description: "Specifies a timeout (in seconds) for feature install.",
               default: 600

      action :install do
        description "Install a Windows role/feature using DISM"

        reload_cached_dism_data unless node["dism_features_cache"]
        fail_if_unavailable # fail if the features don't exist
        fail_if_removed # fail if the features are in removed state

        Chef::Log.debug("Windows features needing installation: #{features_to_install.empty? ? 'none' : features_to_install.join(',')}")
        unless features_to_install.empty?
          message = "install Windows feature#{'s' if features_to_install.count > 1} #{features_to_install.join(',')}"
          converge_by(message) do
            addsource = new_resource.source ? "/LimitAccess /Source:\"#{new_resource.source}\"" : ""
            addall = new_resource.all ? "/All" : ""
            shell_out!("dism.exe /online /enable-feature #{features_to_install.map { |f| "/featurename:#{f}" }.join(' ')} /norestart #{addsource} #{addall}", returns: [0, 42, 127, 3010], timeout: new_resource.timeout)

            reload_cached_dism_data # Reload cached dism feature state
          end
        end
      end

      action :remove do
        description "Remove a Windows role/feature using DISM"

        reload_cached_dism_data unless node["dism_features_cache"]

        Chef::Log.debug("Windows features needing removal: #{features_to_remove.empty? ? 'none' : features_to_remove.join(',')}")
        unless features_to_remove.empty?
          message = "remove Windows feature#{'s' if features_to_remove.count > 1} #{features_to_remove.join(',')}"

          converge_by(message) do
            shell_out!("dism.exe /online /disable-feature #{features_to_remove.map { |f| "/featurename:#{f}" }.join(' ')} /norestart", returns: [0, 42, 127, 3010], timeout: new_resource.timeout)

            reload_cached_dism_data # Reload cached dism feature state
          end
        end
      end

      action :delete do
        description "Remove a Windows role/feature from the image using DISM"

        fail_if_delete_unsupported

        reload_cached_dism_data unless node["dism_features_cache"]

        fail_if_unavailable # fail if the features don't exist

        Chef::Log.debug("Windows features needing deletion: #{features_to_delete.empty? ? 'none' : features_to_delete.join(',')}")
        unless features_to_delete.empty?
          message = "delete Windows feature#{'s' if features_to_delete.count > 1} #{features_to_delete.join(',')} from the image"
          converge_by(message) do
            shell_out!("dism.exe /online /disable-feature #{features_to_delete.map { |f| "/featurename:#{f}" }.join(' ')} /Remove /norestart", returns: [0, 42, 127, 3010], timeout: new_resource.timeout)

            reload_cached_dism_data # Reload cached dism feature state
          end
        end
      end

      action_class do
        # @return [Array] features the user has requested to install which need installation
        def features_to_install
          # the intersection of the features to install & disabled features are what needs installing
          @install ||= new_resource.feature_name & node["dism_features_cache"]["disabled"]
        end

        # @return [Array] features the user has requested to remove which need removing
        def features_to_remove
          # the intersection of the features to remove & enabled features are what needs removing
          @remove ||= new_resource.feature_name & node["dism_features_cache"]["enabled"]
        end

        # @return [Array] features the user has requested to delete which need deleting
        def features_to_delete
          # the intersection of the features to remove & enabled/disabled features are what needs removing
          @remove ||= begin
            all_available = node["dism_features_cache"]["enabled"] +
              node["dism_features_cache"]["disabled"]
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
          all_available = node["dism_features_cache"]["enabled"] +
            node["dism_features_cache"]["disabled"] +
            node["dism_features_cache"]["removed"]

          # the difference of desired features to install to all features is what's not available
          unavailable = (new_resource.feature_name - all_available)
          raise "The Windows feature#{'s' if unavailable.count > 1} #{unavailable.join(',')} #{unavailable.count > 1 ? 'are' : 'is'} not available on this version of Windows. Run 'dism /online /Get-Features' to see the list of available feature names." unless unavailable.empty?
        end

        # run dism.exe to get a list of all available features and their state
        # and save that to the node at node.normal (same as ohai) level.
        # We do this because getting a list of features in dism takes at least a second
        # and this data will be persisted across multiple resource runs which gives us
        # a much faster run when no features actually need to be installed / removed.
        # @return [void]
        def reload_cached_dism_data
          Chef::Log.debug("Caching Windows features available via dism.exe.")
          node.normal["dism_features_cache"] = Mash.new
          node.normal["dism_features_cache"]["enabled"] = []
          node.normal["dism_features_cache"]["disabled"] = []
          node.normal["dism_features_cache"]["removed"] = []

          # Grab raw feature information from dism command line
          raw_list_of_features = shell_out("dism.exe /Get-Features /Online /Format:Table /English").stdout

          # Split stdout into an array by windows line ending
          features_list = raw_list_of_features.split("\r\n")
          features_list.each do |feature_details_raw|
            case feature_details_raw
            when /Payload Removed/ # matches 'Disabled with Payload Removed'
              add_to_feature_mash("removed", feature_details_raw)
            when /Enable/ # matches 'Enabled' and 'Enable Pending' aka after reboot
              add_to_feature_mash("enabled", feature_details_raw)
            when /Disable/ # matches 'Disabled' and 'Disable Pending' aka after reboot
              add_to_feature_mash("disabled", feature_details_raw)
            end
          end
          Chef::Log.debug("The cache contains\n#{node['dism_features_cache']}")
        end

        # parse the feature string and add the values to the appropriate array
        # in the
        # strips trailing whitespace characters then split on n number of spaces
        # + | +  n number of spaces
        # @return [void]
        def add_to_feature_mash(feature_type, feature_string)
          feature_details = feature_string.strip.split(/\s+[|]\s+/)
          node.normal["dism_features_cache"][feature_type] << feature_details.first
        end

        # Fail if any of the packages are in a removed state
        # @return [void]
        def fail_if_removed
          return if new_resource.source # if someone provides a source then all is well
          removed = new_resource.feature_name & node["dism_features_cache"]["removed"]
          raise "The Windows feature#{'s' if removed.count > 1} #{removed.join(',')} #{removed.count > 1 ? 'are' : 'is'} have been removed from the host and cannot be installed." unless removed.empty?
        end

        # Fail unless we're on windows 8+ / 2012+ where deleting a feature is supported
        # @return [void]
        def fail_if_delete_unsupported
          raise Chef::Exceptions::UnsupportedAction, "#{self} :delete action not support on Windows releases before Windows 8/2012. Cannot continue!" unless node["platform_version"].to_f >= 6.2
        end
      end
    end
  end
end
