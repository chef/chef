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

require "chef/resource"
require "chef/mixin/powershell_out"

class Chef
  class Resource
    class WindowsWorkgroup < Chef::Resource
      resource_name :windows_workgroup
      provides :windows_workgroup

      include Chef::Mixin::PowershellOut

      description "Use the windows_workgroup resource to join change the workgroup of a machine."
      introduced "14.0"

      property :workgroup_name, String,
               description: "The name of the workgroup for the computer.",
               validation_message: "The 'workgroup_name' property must not contain spaces.",
               regex: /^\S*$/, # no spaces
               name_property: true

      property :user, String,
               description: "The local user to use to change the workgroup.",
               required: true

      property :password, String,
               description: "The password for the local user.",
               required: true

      property :reboot, Symbol,
               equal_to: [:immediate, :delayed, :never, :request_reboot, :reboot_now],
               validation_message: "The reboot property accepts :immediate (reboot as soon as the resource completes), :delayed (reboot once the Chef run completes), and :never (Don't reboot)",
               description: "Controls the system reboot behavior post workgroup joining. Reboot immediately, after the Chef run completes, or never. Note that a reboot is necessary for changes to take effect.",
               default: :immediate

      # define this again so we can default it to true. Otherwise failures print the password
      property :sensitive, [TrueClass, FalseClass],
               default: true

      action :join do
        description "Update the workgroup."

        cmd = "$pswd = ConvertTo-SecureString \'#{new_resource.password}\' -AsPlainText -Force;"
        cmd << "$credential = New-Object System.Management.Automation.PSCredential (\"#{new_resource.user}\",$pswd);"
        cmd << "Add-Computer -WorkgroupName #{new_resource.workgroup_name} -Credential $credential" if new_resource.workgroup_name
        cmd << " -Force"
        converge_by("join workstation workgroup #{new_resource.workgroup_name}") do
          ps_run = powershell_out(cmd)
          raise "Failed to join the workgroup #{new_resource.workgroup_name}: #{ps_run.stderr}}" if ps_run.error?
          unless new_resource.reboot == :never
            reboot "Reboot to join workgroup #{new_resource.workgroup_name}" do
              action clarify_reboot(new_resource.reboot)
              reason "Reboot to join workgroup #{new_resource.workgroup_name}"
            end
          end
        end
      end

      action_class do
        # This resource historically took `:immediate` and `:delayed` as arguments to the reboot property but then
        # tried to shove that straight to the `reboot` resource which objected strenuously
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
      end
    end
  end
end
