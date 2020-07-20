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
require_relative "../dist"
require "plist"

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
          value '2'
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
        required: true,
        desired_state: false

      property :host, String,
        description: "Set either 'current' or a hostname to set the user default at the host level.",
        desired_state: false,
        introduced: "16.3"

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
        description: "The value of the key. Note: When setting boolean values you can either specify 0/1 or you can pass true/false, 'true'/false', or 'yes'/'no' and we'll automatically convert these to the proper boolean values Apple expects.",
        required: [:write]

      property :type, String,
        description: "The value type of the preference key.",
        desired_state: false

      property :user, String,
        description: "The system user that the default will be applied to.",
        desired_state: false

      property :sudo, [TrueClass, FalseClass],
        description: "Set to true if the setting you wish to modify requires privileged access. This requires passwordless sudo for the '/usr/bin/defaults' command to be setup for the user running #{Chef::Dist::PRODUCT}.",
        default: false,
        desired_state: false

      load_current_value do |desired|
        Chef::Log.debug "#load_current_value: shelling out \"#{defaults_export_cmd(desired).join(" ")}\" to determine state"
        state = if desired.user.nil?
                  shell_out(defaults_export_cmd(desired))
                else
                  shell_out(defaults_export_cmd(desired), user: desired.user)
                end

        if state.error? || state.stdout.empty?
          Chef::Log.debug "#load_current_value: #{defaults_export_cmd(desired).join(" ")} returned stdout: #{state.stdout} and stderr: #{state.stderr}"
          current_value_does_not_exist!
        end

        value ::Plist.parse_xml(state.stdout)[key]
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

      action :write do
        description "Write the value to the specified domain/key."

        converge_if_changed do
          cmd = defaults_modify_cmd
          Chef::Log.debug("Updating defaults value by shelling out: #{cmd.join(" ")}")

          if new_resource.user.nil?
            shell_out!(cmd)
          else
            shell_out!(cmd, user: new_resource.user)
          end
        end
      end

      action :delete do
        description "Delete a key from a domain."

        return unless current_resource.key # if it's not there there's nothing to remove

        converge_by("delete domain:#{new_resource.domain} key:#{new_resource.key}") do

          cmd = defaults_modify_cmd
          Chef::Log.debug("Removing defaults key by shelling out: #{cmd.join(" ")}")

          if new_resource.user.nil?
            shell_out!(cmd)
          else
            shell_out!(cmd, user: new_resource.user)
          end
        end
      end

      action_class do
        def defaults_modify_cmd
          cmd = ["defaults"]

          if new_resource.host == "current"
            state_cmd.concat(["-currentHost"])
          elsif new_resource.host # they specified a non-nil value, which is a hostname
            state_cmd.concat(["-host", new_resource.host])
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
          cmd_values = [ type == "dict" ? new_resource.value.flatten : new_resource.value ]
          cmd_values.prepend("-#{type}") if type
          cmd_values
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
          end
        end
      end
    end
  end
end
