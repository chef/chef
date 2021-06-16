#
# Author:: Derek Groh (<derekgroh@github.io>)
# Copyright:: 2018, Derek Groh
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

class Chef
  class Resource
    class WindowsWorkgroup < Chef::Resource
      unified_mode true

      provides :windows_workgroup

      description "Use the **windows_workgroup** resource to join or change the workgroup of a Windows host."
      introduced "14.5"
      examples <<~DOC
      **Join a workgroup**:

      ```ruby
      windows_workgroup 'myworkgroup'
      ```

      **Join a workgroup using a specific user**:

      ```ruby
      windows_workgroup 'myworkgroup' do
        user 'Administrator'
        password 'passw0rd'
      end
      ```
      DOC

      property :workgroup_name, String,
        description: "An optional property to set the workgroup name if it differs from the resource block's name.",
        validation_message: "The 'workgroup_name' property must not contain spaces.",
        regex: /^\S*$/, # no spaces
        name_property: true

      property :user, String,
        description: "The local administrator user to use to change the workgroup. Required if using the `password` property.",
        desired_state: false

      property :password, String,
        description: "The password for the local administrator user. Required if using the `user` property.",
        sensitive: true,
        desired_state: false

      property :reboot, Symbol,
        equal_to: %i{never request_reboot reboot_now},
        validation_message: "The reboot property accepts :immediate (reboot as soon as the resource completes), :delayed (reboot once the #{ChefUtils::Dist::Infra::PRODUCT} run completes), and :never (Don't reboot)",
        description: "Controls the system reboot behavior post workgroup joining. Reboot immediately, after the #{ChefUtils::Dist::Infra::PRODUCT} run completes, or never. Note that a reboot is necessary for changes to take effect.",
        coerce: proc { |x| clarify_reboot(x) },
        default: :immediate, desired_state: false

      # This resource historically took `:immediate` and `:delayed` as arguments to the reboot property but then
      # tried to shove that straight to the `reboot` resource which objected strenuously. We need to convert these
      # legacy actions into actual reboot actions
      #
      # @return [Symbol] chef reboot resource action
      def clarify_reboot(reboot_action)
        case reboot_action
        when :immediate
          :reboot_now
        when :delayed
          :request_reboot
        else
          reboot_action
        end
      end

      # define this again so we can default it to true. Otherwise failures print the password
      # FIXME: this should now be unnecessary with the password property itself marked sensitive?
      property :sensitive, [TrueClass, FalseClass],
        default: true, desired_state: false

      action :join, description: "Update the workgroup." do

        unless workgroup_member?
          converge_by("join workstation workgroup #{new_resource.workgroup_name}") do
            ps_run = powershell_exec(join_command)
            raise "Failed to join the workgroup #{new_resource.workgroup_name}: #{ps_run.errors}}" if ps_run.error?

            unless new_resource.reboot == :never
              reboot "Reboot to join workgroup #{new_resource.workgroup_name}" do
                action new_resource.reboot
                reason "Reboot to join workgroup #{new_resource.workgroup_name}"
              end
            end
          end
        end
      end

      action_class do
        # return [String] the appropriate PS command to joint the workgroup
        def join_command
          cmd = ""
          cmd << "$pswd = ConvertTo-SecureString \'#{new_resource.password}\' -AsPlainText -Force;" if new_resource.password
          cmd << "$credential = New-Object System.Management.Automation.PSCredential (\"#{new_resource.user}\",$pswd);" if new_resource.password
          cmd << "Add-Computer -WorkgroupName #{new_resource.workgroup_name}"
          cmd << " -Credential $credential" if new_resource.password
          cmd << " -Force"
          cmd
        end

        # @return [Boolean] is the node a member of the workgroup specified in the resource
        def workgroup_member?
          node_workgroup = powershell_exec!("(Get-WmiObject -Class Win32_ComputerSystem).Workgroup")
          raise "Failed to determine if system already a member of workgroup #{new_resource.workgroup_name}" if node_workgroup.error?

          String(node_workgroup.result).downcase.strip == new_resource.workgroup_name.downcase
        end
      end
    end
  end
end
