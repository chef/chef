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
require_relative "selinux/common_helpers"

class Chef
  class Resource
    class SelinuxBoolean < Chef::Resource
      unified_mode true

      provides :selinux_boolean, target_mode: true
      target_mode support: :full

      description "Use **selinux_boolean** resource to set SELinux boolean values."
      introduced "18.0"
      examples <<~DOC
      **Set ssh_keysign to true**:

      ```ruby
      selinux_boolean 'ssh_keysign' do
        value true
      end
      ```

      **Set ssh_sysadm_login to 'on'**:

      ```ruby
      selinux_boolean 'ssh_sysadm_login' do
        value 'on'
      end
      ```
      DOC

      property :boolean, String,
        name_property: true,
        description: "SELinux boolean to set."

      property :value, [Integer, String, true, false],
        required: true,
        equal_to: %w{on off},
        coerce: proc { |p| selinux_bool(p) },
        description: "SELinux boolean value."

      property :persistent, [true, false],
        default: true,
        desired_state: false,
        description: "Set to true for value setting to survive reboot."

      load_current_value do |new_resource|
        value shell_out!("getsebool", new_resource.boolean).stdout.split("-->").map(&:strip).last
      end

      action_class do
        include Chef::SELinux::CommonHelpers
      end

      action :set , description: "Set the state of the boolean." do
        if selinux_disabled?
          Chef::Log.warn("Unable to set SELinux boolean #{new_resource.name} as SELinux is disabled")
          return
        end

        converge_if_changed do
          cmd = "setsebool"
          cmd += " -P" if new_resource.persistent
          cmd += " #{new_resource.boolean} #{new_resource.value}"

          shell_out!(cmd)
        end
      end

      private

      #
      # Validate and return input boolean value in required format
      # @param bool [String, Integer, Boolean] Input boolean value in allowed formats
      #
      # @return [String] [description] Boolean value in required format
      def selinux_bool(bool)
        if ["on", "true", "1", true, 1].include?(bool)
          "on"
        elsif ["off", "false", "0", false, 0].include?(bool)
          "off"
        else
          raise ArgumentError, "selinux_bool: Invalid selinux boolean value #{bool}"
        end
      end
    end
  end
end
