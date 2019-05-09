#
# Copyright:: 2011-2018, Joshua Timberman
# Copyright:: 2018, Chef Software, Inc.
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

class Chef
  class Resource
    class MacosUserDefaults < Chef::Resource
      # align with apple's marketing department
      resource_name :macos_userdefaults
      provides(:mac_os_x_userdefaults) { true }
      provides(:macos_userdefaults) { true }

      description "Use the macos_userdefaults resource to manage the macOS user defaults system. The properties of this resource are passed to the defaults command, and the parameters follow the convention of that command. See the defaults(1) man page for details on how the tool works."
      introduced "14.0"

      property :domain, String,
               description: "The domain that the user defaults belong to.",
               required: true

      property :global, [TrueClass, FalseClass],
               description: "Determines whether or not the domain is global.",
               default: false

      property :key, String,
               description: "The preference key."

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
               description: "The value of the key.",
               required: true

      property :type, String,
               description: "The value type of the preference key.",
               default: ""

      property :user, String,
               description: "The system user that the default will be applied to."

      property :sudo, [TrueClass, FalseClass],
               description: "Set to true if the setting you wish to modify requires privileged access.",
               default: false,
               desired_state: false

      # @todo this should get refactored away: https://github.com/chef/chef/issues/7622
      property :is_set, [TrueClass, FalseClass],
               default: false,
               desired_state: false,
               skip_docs: true

       # coerce various ways of representing a boolean into either 0 (false) or 1 (true)
       # which is what the defaults CLI expects. Why? Well defaults itself accepts a few
       # different formats, but when you do a read command it all comes back as 1 or 0.
      def coerce_booleans(val)
        return 1 if [true, "TRUE", "1", "true", "YES", "yes"].include?(val)
        return 0 if [false, "FALSE", "0", "false", "NO", "no"].include?(val)
        val
      end

      load_current_value do |desired|
        value = coerce_booleans(desired.value)
        drcmd = "defaults read '#{desired.domain}' "
        drcmd << "'#{desired.key}' " if desired.key
        shell_out_opts = {}
        shell_out_opts[:user] = desired.user unless desired.user.nil?
        vc = shell_out("#{drcmd} | grep -qx '#{value}'", shell_out_opts)
        is_set vc.exitstatus == 0 ? true : false
      end

      action :write do
        description "Write the setting to the specified domain"

        unless current_resource.is_set
          cmd = ["defaults write"]
          cmd.unshift("sudo") if new_resource.sudo

          cmd << if new_resource.global
                   "NSGlobalDomain"
                 else
                   "'#{new_resource.domain}'"
                 end

          cmd << "'#{new_resource.key}'" if new_resource.key
          value = new_resource.value
          type = new_resource.type.empty? ? value_type(value) : new_resource.type
          # creates a string of Key1 Value1 Key2 Value2...
          value = value.map { |k, v| "\"#{k}\" \"#{v}\"" }.join(" ") if type == "dict"
          if type == "array"
            value = value.join("' '")
            value = "'#{value}'"
          end
          cmd << "-#{type}" if type
          cmd << value

          declare_resource(:execute, cmd.join(" ")) do
            user new_resource.user unless new_resource.user.nil?
          end
        end
      end

      action_class do
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
