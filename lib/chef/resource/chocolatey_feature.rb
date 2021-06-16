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

class Chef
  class Resource
    class ChocolateyFeature < Chef::Resource
      unified_mode true
      provides :chocolatey_feature

      description "Use the **chocolatey_feature** resource to enable and disable Chocolatey features."
      introduced "15.1"
      examples <<~DOC
        **Enable the checksumFiles Chocolatey feature**

        ```ruby
        chocolatey_feature 'checksumFiles' do
          action :enable
        end
        ```

        **Disable the checksumFiles Chocolatey feature**

        ```ruby
        chocolatey_feature 'checksumFiles' do
          action :disable
        end
        ```
      DOC

      property :feature_name, String, name_property: true,
               description: "The name of the Chocolatey feature to enable or disable."

      property :feature_state, [TrueClass, FalseClass], default: false, skip_docs: true

      load_current_value do
        current_state = fetch_feature_element(feature_name)
        current_value_does_not_exist! if current_state.nil?

        feature_name feature_name
        feature_state current_state == "true"
      end

      # @param [String] id the feature name
      # @return [String] the element's value field
      def fetch_feature_element(name)
        require "rexml/document" unless defined?(REXML::Document)
        config_file = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\config\\chocolatey.config"
        raise "Could not find the Chocolatey config at #{config_file}!" unless ::File.exist?(config_file)

        contents = REXML::Document.new(::File.read(config_file))
        data = REXML::XPath.first(contents, "//features/feature[@name=\"#{name}\"]")
        data ? data.attribute("enabled").to_s : nil # REXML just returns nil if it can't find anything so avoid an undefined method error
      end

      action :enable, description: "Enables a named Chocolatey feature." do
        if current_resource.feature_state != true
          converge_by("enable Chocolatey feature '#{new_resource.feature_name}'") do
            shell_out!(choco_cmd("enable"))
          end
        end
      end

      action :disable, description: "Disables a named Chocolatey feature." do
        if current_resource.feature_state == true
          converge_by("disable Chocolatey feature '#{new_resource.feature_name}'") do
            shell_out!(choco_cmd("disable"))
          end
        end
      end

      action_class do
        # @param [String] action the name of the action to perform
        # @return [String] the choco feature command string
        def choco_cmd(action)
          "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\bin\\choco feature #{action} --name #{new_resource.feature_name}"
        end
      end
    end
  end
end
