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

require "chef/resource"

class Chef
  class Resource
    class MacosUserDefaults < Chef::Resource
      # align with apple's marketing department
      resource_name :macos_userdefaults
      provides :mac_os_x_userdefaults
      provides :macos_userdefaults

      description "Use the macos_userdefaults resource to manage the macOS user defaults"\
                  " system. The properties to the resource are passed to the defaults command"\
                  " and the parameters follow convention of the macOS command. See the defaults(1)"\
                  " man page for details on how the tool works."
      introduced "14.0"

      property :domain, String,
               description: "The domain the defaults belong to.",
               required: true

      property :global, [TrueClass, FalseClass],
               description: "Whether the domain is global.",
               default: false

      property :key, String,
               description: "The preference key."

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
               description: "The value of the key.",
               coerce: proc { |v| coerce_booleans(v) },
               required: true

      property :type, String,
               description: "Value type of the preference key.",
               default: ""

      property :user, String,
               description: "User for which to set the default."

      property :sudo, [TrueClass, FalseClass],
               description: "Set to true if the setting requires privileged access to modify.",
               default: false,
               desired_state: false

      property :is_set, [TrueClass, FalseClass],
               description: "",
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
        drcmd = "defaults read '#{desired.domain}' "
        drcmd << "'#{desired.key}' " if desired.key
        shell_out_opts = {}
        shell_out_opts[:user] = desired.user unless desired.user.nil?
        vc = shell_out("#{drcmd} | grep -qx '#{desired.value}'", shell_out_opts)
        is_set vc.exitstatus == 0 ? true : false
      end

      action :write do
        description "Write the setting to the specified domain"

        unless current_value.is_set
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
    end
  end
end
