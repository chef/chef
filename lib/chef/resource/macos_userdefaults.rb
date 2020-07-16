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

      property :current_host_level, [TrueClass, FalseClass],
        description: "Set the key/value at current host level, saving plist files to `$HOME/Library/Preferences/ByHost/`.",
        desired_state: false,
        introduced: "16.3"

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
        description: "The value of the key. Note: When setting boolean values you can either specify 0/1 or you can pass true/false, 'true'/false', or 'yes'/'no' and we'll automatically convert these to the proper boolean values Apple expects.",
        required: true

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

        state_cmd = ["/usr/bin/defaults"]
        state_cmd << "-currentHost" if desired.current_host_level
        state_cmd << ["read", "'#{desired.domain}'", "'#{desired.key}'"]

        state = if desired.user.nil?
                  shell_out(state_cmd)
                else
                  shell_out(state_cmd, user: desired.user)
                end

        if state.error?
          Chef::Log.debug "#load_current_value: #{state_cmd.join(" ")} returned stdout: #{state.stdout} and stderr: #{state.stderr}"
          current_value_does_not_exist!
        end

        # parse the output from the defaults command to ruby data type
        # todo: This is a pretty basic implementation. PRs welcome ;)
        case state.stdout[0]
        when "{" # dict aka hash
          # https://rubular.com/r/cBnFu1nttMdsXq
          data = /^\s{2,}(.*)\s=\s(.*);/.match(state.stdout)
          fail_if_unparsable(data, state.stdout)
          value Hash[*data.captures]
        when "(" # array
          # https://rubular.com/r/TfYejXUJny11OG
          data = /^\s{2,}(.*),?/.match(state.stdout)
          fail_if_unparsable(data, state.stdout)
          value data.captures
        else # a string/int/float/bool
          value state.stdout.strip
        end
      end

      #
      # If there were not matches raise a warning that we couldn't parse the output of the defaults
      # CLI and return a nil current_resource by calling current_value_does_not_exist!
      #
      # @param [MatchData] match_data
      # @param [String] stdout
      #
      def fail_if_unparsable(match_data, stdout)
        return unless match_data.captures.empty?

        Chef::Log.warn("Could not parse macos defaults CLI value data: #{stdout}.")
        current_value_does_not_exist!
      end

      action :write do
        description "Write the value to the specified domain/key."

        converge_if_changed do
          cmd = defaults_write_cmd
          Chef::Log.debug("Updating defaults value by shelling out: #{cmd.join(" ")}")

          if new_resource.user.nil?
            shell_out!(cmd)
          else
            shell_out!(cmd, user: new_resource.user)
          end
        end
      end

      action_class do
        def defaults_write_cmd
          value = new_resource.value
          type = new_resource.type || value_type(value)

          value = case type
                  when "dict"
                    # creates an array of quoted values ["'Key1'", "'Value1'", "'Key2'", "'Value2'" ...]
                    value.flatten.map { |x| "'#{x}'" }
                  when "array"
                    value.map { |x| "'#{x}'" }
                  when "bool"
                    value
                  else
                    "'#{value}'"
                  end

          cmd = ["defaults"]
          cmd << "-currentHost" if new_resource.current_host_level
          cmd << ["write", "'#{new_resource.domain}'", "'#{new_resource.key}'"]
          cmd << "-#{type}" if type
          cmd << value
          cmd.prepend("sudo") if new_resource.sudo
          cmd.flatten
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
