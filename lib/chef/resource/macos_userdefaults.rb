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
require "shellwords"

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
        macos_userdefaults 'full keyboard access to all controls' do
          key 'AppleKeyboardUIMode'
          value '2'
        end
        ```

        **Use an integer value**

        ```ruby
        macos_userdefaults 'enable macOS firewall' do
          domain '/Library/Preferences/com.apple.alf'
          key 'globalstate'
          value '1'
          type 'int'
        end
        ```

        **Use a boolean value**

        ```ruby
        macos_userdefaults 'finder expanded save dialogs' do
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

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
        description: "The value of the key. Note: When setting boolean values you can either specify 0/1 or you can pass true/false, 'true'/false', or 'yes'/'no' and we'll automatically convert these to the proper boolean values Apple expects.",
        coerce: proc { |v| coerce_booleans(v) },
        required: true

      property :type, String,
        description: "The value type of the preference key.",
        desired_state: false

      property :user, String,
        description: "The system user that the default will be applied to.",
        desired_state: false

      property :sudo, [TrueClass, FalseClass],
        description: "Set to true if the setting you wish to modify requires privileged access.",
        default: false,
        desired_state: false

      # coerce various ways of representing a boolean into either 0 (false) or 1 (true)
      # which is what the defaults CLI expects. Why? Well defaults itself accepts a few
      # different formats, but when you do a read command it all comes back as 1 or 0.
      def coerce_booleans(val)
        return 1 if [true, "TRUE", "1", "true", "YES", "yes"].include?(val)
        return 0 if [false, "FALSE", "0", "false", "NO", "no"].include?(val)

        val
      end

      load_current_value do |desired|
        coerced_value = coerce_booleans(desired.value)

        state_cmd = ["/usr/bin/defaults", "read", desired.domain, desired.key]

        state = if desired.user.nil?
                  shell_out(state_cmd)
                else
                  shell_out(state_cmd, user: desired.user)
                end

        if state.error?
          Chef::Log.debug "#load_current_value: #{state_cmd.join(" ")} returned stdout: #{state.stdout} and stderr: #{state.stderr}"
          current_value_does_not_exist!
        end

        value state.stdout.strip
      end

      action :write do
        description "Write the value to the specified domain/key."

        converge_if_changed do
          # FIXME: this should use cmd directly as an array argument, but then the quoting
          # of individual args above needs to be removed as well.
          execute defaults_write_cmd.join(" ") do
            user new_resource.user unless new_resource.user.nil?
          end
        end
      end

      action_class do
        def defaults_write_cmd
          cmd = ["defaults", "write", "'#{new_resource.domain}'", "'#{new_resource.key}'"]
          cmd.prepend("sudo") if new_resource.sudo

          value = new_resource.value
          type = new_resource.type || value_type(value)
          # creates a string of Key1 Value1 Key2 Value2...
          value = value.map { |k, v| "\"#{k}\" \"#{v}\"" }.join(" ") if type == "dict"
          if type == "array"
            value = value.join("' '")
            value = "'#{value}'"
          end
          cmd << "-#{type}" if type
          cmd << value
          cmd
        end

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
