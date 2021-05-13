#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

require_relative "../resource"
require_relative "../platform/query_helpers"

class Chef
  class Resource
    class WindowsFeatureDism < Chef::Resource
      unified_mode true

      provides(:windows_feature_dism) { true }

      description "Use the **windows_feature_dism** resource to add, remove, or entirely delete Windows features and roles using DISM."
      introduced "14.0"
      examples <<~DOC
      **Installing the TelnetClient service**:

      ```ruby
      windows_feature_dism "TelnetClient"
      ```

      **Installing two features by using an array**:

      ```ruby
      windows_feature_dism %w(TelnetClient TFTP)
      ```
      DOC

      property :feature_name, [Array, String],
        description: "The name of the feature(s) or role(s) to install if they differ from the resource name.",
        coerce: proc { |x| to_formatted_array(x) },
        name_property: true

      property :source, String,
        description: "Specify a local repository for the feature install."

      property :all, [TrueClass, FalseClass],
        description: "Install all sub-features. When set to `true`, this is the equivalent of specifying the `/All` switch to `dism.exe`",
        default: false

      property :timeout, Integer,
        description: "Specifies a timeout (in seconds) for the feature installation.",
        default: 600,
        desired_state: false

      # @return [Array] lowercase the array
      def to_formatted_array(x)
        x = x.split(/\s*,\s*/) if x.is_a?(String) # split multiple forms of a comma separated list
        x.map(&:downcase)
      end

      action :install, description: "Install a Windows role/feature using DISM." do
        reload_cached_dism_data unless node["dism_features_cache"]
        fail_if_unavailable # fail if the features don't exist

        logger.trace("Windows features needing installation: #{features_to_install.empty? ? "none" : features_to_install.join(",")}")
        unless features_to_install.empty?
          message = "install Windows feature#{"s" if features_to_install.count > 1} #{features_to_install.join(",")}"
          converge_by(message) do
            install_command = "dism.exe /online /enable-feature #{features_to_install.map { |f| "/featurename:#{f}" }.join(" ")} /norestart"
            install_command << " /LimitAccess /Source:\"#{new_resource.source}\"" if new_resource.source
            install_command << " /All" if new_resource.all
            begin
              shell_out!(install_command, returns: [0, 42, 127, 3010], timeout: new_resource.timeout)
            rescue Mixlib::ShellOut::ShellCommandFailed => e
              raise "Error 50 returned by DISM related to parent features, try setting the 'all' property to 'true' on the 'windows_feature_dism' resource." if required_parent_feature?(e.inspect)

              raise e.message
            end

            reload_cached_dism_data # Reload cached dism feature state
          end
        end
      end

      action :remove, description: "Remove a Windows role or feature using DISM." do
        reload_cached_dism_data unless node["dism_features_cache"]

        logger.trace("Windows features needing removal: #{features_to_remove.empty? ? "none" : features_to_remove.join(",")}")
        unless features_to_remove.empty?
          message = "remove Windows feature#{"s" if features_to_remove.count > 1} #{features_to_remove.join(",")}"

          converge_by(message) do
            shell_out!("dism.exe /online /disable-feature #{features_to_remove.map { |f| "/featurename:#{f}" }.join(" ")} /norestart", returns: [0, 42, 127, 3010], timeout: new_resource.timeout)

            reload_cached_dism_data # Reload cached dism feature state
          end
        end
      end

      action :delete, description: "Remove a Windows role or feature from the image using DISM." do
        reload_cached_dism_data unless node["dism_features_cache"]

        fail_if_unavailable # fail if the features don't exist

        logger.trace("Windows features needing deletion: #{features_to_delete.empty? ? "none" : features_to_delete.join(",")}")
        unless features_to_delete.empty?
          message = "delete Windows feature#{"s" if features_to_delete.count > 1} #{features_to_delete.join(",")} from the image"
          converge_by(message) do
            shell_out!("dism.exe /online /disable-feature #{features_to_delete.map { |f| "/featurename:#{f}" }.join(" ")} /Remove /norestart", returns: [0, 42, 127, 3010], timeout: new_resource.timeout)

            reload_cached_dism_data # Reload cached dism feature state
          end
        end
      end

      action_class do
        private

        # @return [Array] features the user has requested to install which need installation
        def features_to_install
          @install ||= begin
            # disabled features are always available to install
            available_for_install = node["dism_features_cache"]["disabled"].dup

            # removed features are also available for installation
            available_for_install.concat(node["dism_features_cache"]["removed"])

            # the intersection of the features to install & disabled/removed features are what needs installing
            new_resource.feature_name & available_for_install
          end
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
          raise "The Windows feature#{"s" if unavailable.count > 1} #{unavailable.join(",")} #{unavailable.count > 1 ? "are" : "is"} not available on this version of Windows. Run 'dism /online /Get-Features' to see the list of available feature names." unless unavailable.empty?
        end

        #
        # FIXME FIXME FIXME
        # The node object should not be used for caching state like this and this is not a public API and may break.
        # FIXME FIXME FIXME
        #

        # run dism.exe to get a list of all available features and their state
        # and save that to the node at node.override level.
        # We do this because getting a list of features in dism takes at least a second
        # and this data will be persisted across multiple resource runs which gives us
        # a much faster run when no features actually need to be installed / removed.
        # @return [void]
        def reload_cached_dism_data
          logger.trace("Caching Windows features available via dism.exe.")
          node.override["dism_features_cache"] = Mash.new
          node.override["dism_features_cache"]["enabled"] = []
          node.override["dism_features_cache"]["disabled"] = []
          node.override["dism_features_cache"]["removed"] = []

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
          logger.trace("The cache contains\n#{node["dism_features_cache"]}")
        end

        # parse the feature string and add the values to the appropriate array in the strips
        # trailing whitespace characters then split on n number of spaces + | +  n number of spaces
        # @return [void]
        def add_to_feature_mash(feature_type, feature_string)
          feature_details = feature_string.strip.split(/\s+[|]\s+/).first

          # dism isn't case sensitive so it's best to compare lowercase lists so the
          # user input doesn't need to be case sensitive
          feature_details.downcase!
          node.override["dism_features_cache"][feature_type] << feature_details
        end

        def required_parent_feature?(error_message)
          error_message.include?("Error: 50") && error_message.include?("required parent feature")
        end
      end
    end
  end
end
