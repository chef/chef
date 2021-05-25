#
# Copyright:: 2011-2018, Joshua Timberman
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
autoload :Plist, "plist"

class Chef
  class Resource
    class MacosUserDefaults < Chef::Resource
      unified_mode true

      # align with apple's marketing department
      provides(:macos_userdefaults) { true }
      provides(:mac_os_x_userdefaults) { true }

      description "Use the **macos_userdefaults** resource to manage the macOS user defaults system. The properties of this resource are passed to the defaults command, and the parameters follow the convention of that command. See the defaults(1) man page for details on how the tool works."
      introduced "14.0"
      examples <<~DOC
        **Specify a global domain value**

        ```ruby
        macos_userdefaults 'Full keyboard access to all controls' do
          key 'AppleKeyboardUIMode'
          value 2
        end
        ```

        **Setting a value on a specific domain**

        ```ruby
        macos_userdefaults 'Enable macOS firewall' do
          domain '/Library/Preferences/com.apple.alf'
          key 'globalstate'
          value 1
        end
        ```

        **Specifying the type of a key to skip automatic type detection**

        ```ruby
        macos_userdefaults 'Finder expanded save dialogs' do
          key 'NSNavPanelExpandedStateForSaveMode'
          value 'TRUE'
          type 'bool'
        end
        ```
      DOC

      property :domain, String,
        description: "The domain that the user defaults belong to.",
        default: "NSGlobalDomain",
        default_description: "NSGlobalDomain: the global domain.",
        desired_state: false

      property :global, [TrueClass, FalseClass],
        description: "Determines whether or not the domain is global.",
        deprecated: true,
        default: false,
        desired_state: false

      property :key, String,
        description: "The preference key.",
        required: true

      property :host, [String, Symbol],
        description: "Set either :current or a hostname to set the user default at the host level.",
        desired_state: false,
        introduced: "16.3"

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
        description: "The value of the key. Note: With the `type` property set to `bool`, `String` forms of Boolean true/false values that Apple accepts in the defaults command will be coerced: 0/1, 'TRUE'/'FALSE,' 'true'/false', 'YES'/'NO', or 'yes'/'no'.",
        required: [:write],
        coerce: proc { |v| v.is_a?(Hash) ? v.transform_keys(&:to_s) : v } # make sure keys are all strings for comparison

      property :type, String,
        description: "The value type of the preference key.",
        equal_to: %w{bool string int float array dict},
        desired_state: false

      property :user, String,
        description: "The system user that the default will be applied to.",
        desired_state: false

      property :sudo, [TrueClass, FalseClass],
        description: "Set to true if the setting you wish to modify requires privileged access. This requires passwordless sudo for the `/usr/bin/defaults` command to be setup for the user running #{ChefUtils::Dist::Infra::PRODUCT}.",
        default: false,
        desired_state: false

      load_current_value do |new_resource|
        Chef::Log.debug "#load_current_value: shelling out \"#{defaults_export_cmd(new_resource).join(" ")}\" to determine state"
        state = shell_out(defaults_export_cmd(new_resource), user: new_resource.user)

        if state.error? || state.stdout.empty?
          Chef::Log.debug "#load_current_value: #{defaults_export_cmd(new_resource).join(" ")} returned stdout: #{state.stdout} and stderr: #{state.stderr}"
          current_value_does_not_exist!
        end

        plist_data = ::Plist.parse_xml(state.stdout)

        # handle the situation where the key doesn't exist in the domain
        if plist_data.key?(new_resource.key)
          key new_resource.key
        else
          current_value_does_not_exist!
        end

        value plist_data[new_resource.key]
      end

      #
      # The defaults command to export a domain
      #
      # @return [Array] defaults command
      #
      def defaults_export_cmd(resource)
        state_cmd = ["/usr/bin/defaults"]

        if resource.host == "current"
          state_cmd.concat(["-currentHost"])
        elsif resource.host # they specified a non-nil value, which is a hostname
          state_cmd.concat(["-host", resource.host])
        end

        state_cmd.concat(["export", resource.domain, "-"])
        state_cmd
      end

      action :write, description: "Write the value to the specified domain/key." do
        converge_if_changed do
          cmd = defaults_modify_cmd
          Chef::Log.debug("Updating defaults value by shelling out: #{cmd.join(" ")}")

          shell_out!(cmd, user: new_resource.user)
        end
      end

      action :delete, description: "Delete a key from a domain." do
        # if it's not there there's nothing to remove
        return unless current_resource

        converge_by("delete domain:#{new_resource.domain} key:#{new_resource.key}") do

          cmd = defaults_modify_cmd
          Chef::Log.debug("Removing defaults key by shelling out: #{cmd.join(" ")}")

          shell_out!(cmd, user: new_resource.user)
        end
      end

      action_class do
        #
        # The command used to write or delete delete values from domains
        #
        # @return [Array] Array representation of defaults command to run
        #
        def defaults_modify_cmd
          cmd = ["/usr/bin/defaults"]

          if new_resource.host == :current
            cmd.concat(["-currentHost"])
          elsif new_resource.host # they specified a non-nil value, which is a hostname
            cmd.concat(["-host", new_resource.host])
          end

          cmd.concat([action.to_s, new_resource.domain, new_resource.key])
          cmd.concat(processed_value) if action == :write
          cmd.prepend("sudo") if new_resource.sudo
          cmd
        end

        #
        # convert the provided value into the format defaults expects
        #
        # @return [array] array of values starting with the type if applicable
        #
        def processed_value
          type = new_resource.type || value_type(new_resource.value)

          # when dict this creates an array of values ["Key1", "Value1", "Key2", "Value2" ...]
          cmd_values = ["-#{type}"]

          case type
          when "dict"
            cmd_values.concat(new_resource.value.flatten)
          when "array"
            cmd_values.concat(new_resource.value)
          when "bool"
            cmd_values.concat(bool_to_defaults_bool(new_resource.value))
          else
            cmd_values.concat([new_resource.value])
          end

          cmd_values
        end

        #
        # defaults booleans on the CLI must be 'TRUE' or 'FALSE' so convert various inputs to that
        #
        # @param [String, Integer, Boolean] input <description>
        #
        # @return [String] TRUE or FALSE
        #
        def bool_to_defaults_bool(input)
          return ["TRUE"] if [true, "TRUE", "1", "true", "YES", "yes"].include?(input)
          return ["FALSE"] if [false, "FALSE", "0", "false", "NO", "no"].include?(input)

          # make sure it's very clear bad input was given
          raise ArgumentError, "#{input} cannot be converted to a boolean value for use with Apple's defaults command. Acceptable values are: 'TRUE', 'YES', 'true, 'yes', '0', true, 'FALSE', 'false', 'NO', 'no', '1', or false."
        end

        #
        # convert ruby type to defaults type
        #
        # @param [Integer, Float, String, TrueClass, FalseClass, Hash, Array] value The value being set
        #
        # @return [string, nil] the type value used by defaults or nil if not applicable
        #
        def value_type(value)
          case value
          when true, false
            "bool"
          when Integer
            "int"
          when Float
            "float"
          when Hash
            "dict"
          when Array
            "array"
          when String
            "string"
          end
        end
      end
    end
  end
end
