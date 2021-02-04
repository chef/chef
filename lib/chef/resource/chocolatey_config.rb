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
    class ChocolateyConfig < Chef::Resource
      unified_mode true

      provides :chocolatey_config

      description "Use the **chocolatey_config** resource to add or remove Chocolatey configuration keys."
      introduced "14.3"
      examples <<~DOC
        **Set the Chocolatey cacheLocation config**:

        ```ruby
        chocolatey_config 'Set cacheLocation config' do
          config_key 'cacheLocation'
          value 'C:\temp\choco'
        end
        ```

        **Unset a Chocolatey config**:

        ```ruby
        chocolatey_config 'BogusConfig' do
          action :unset
        end
        ```
      DOC

      property :config_key, String, name_property: true,
               description: "An optional property to set the config key name if it differs from the resource block's name."

      property :value, String,
        description: "The value to set."

      load_current_value do
        current_val = fetch_config_element(config_key)
        current_value_does_not_exist! if current_val.nil?

        config_key config_key
        value current_val
      end

      # @param [String] id the config name
      # @return [String] the element's value field
      def fetch_config_element(id)
        require "rexml/document" unless defined?(REXML::Document)
        config_file = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\config\\chocolatey.config"
        raise "Could not find the Chocolatey config at #{config_file}!" unless ::File.exist?(config_file)

        contents = REXML::Document.new(::File.read(config_file))
        data = REXML::XPath.first(contents, "//config/add[@key=\"#{id}\"]")
        data ? data.attribute("value").to_s : nil # REXML just returns nil if it can't find anything so avoid an undefined method error
      end

      action :set, description: "Sets a Chocolatey config value." do
        raise "#{new_resource}: When adding a Chocolatey config you must pass the 'value' property!" unless new_resource.value

        converge_if_changed do
          shell_out!(choco_cmd("set"))
        end
      end

      action :unset, description: "Unsets a Chocolatey config value." do
        if current_resource
          converge_by("unset Chocolatey config '#{new_resource.config_key}'") do
            shell_out!(choco_cmd("unset"))
          end
        end
      end

      action_class do
        # @param [String] action the name of the action to perform
        # @return [String] the choco config command string
        def choco_cmd(action)
          cmd = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\bin\\choco config #{action} --name #{new_resource.config_key}"
          cmd << " --value #{new_resource.value}" if action == "set"
          cmd
        end
      end
    end
  end
end
