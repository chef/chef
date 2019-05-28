#
# Author:: John Snow (<jsnow@chef.io>)
# Copyright:: 2016-2018, John Snow
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
require_relative "../mixin/powershell_out"
require_relative "../dist"

class Chef
  class Resource
    class WindowsAdJoin < Chef::Resource
      resource_name :windows_ad_join
      provides :windows_ad_join

      include Chef::Mixin::PowershellOut

      description "Use the windows_ad_join resource to join a Windows Active Directory domain."
      introduced "14.0"

      property :domain_name, String,
               description: "The FQDN of the Active Directory domain to join if it differs from the resource block's name.",
               validation_message: "The 'domain_name' property must be a FQDN.",
               regex: /.\../, # anything.anything
               name_property: true

      property :domain_user, String,
               description: "The domain user that will be used to join the domain.",
               required: true

      property :domain_password, String,
               description: "The password for the domain user. Note that this resource is set to hide sensitive information by default. ",
               required: true

      property :ou_path, String,
               description: "The path to the Organizational Unit where the host will be placed."

      property :reboot, Symbol,
               equal_to: [:immediate, :delayed, :never, :request_reboot, :reboot_now],
               validation_message: "The reboot property accepts :immediate (reboot as soon as the resource completes), :delayed (reboot once the #{Chef::Dist::PRODUCT} run completes), and :never (Don't reboot)",
               description: "Controls the system reboot behavior post domain joining. Reboot immediately, after the #{Chef::Dist::PRODUCT} run completes, or never. Note that a reboot is necessary for changes to take effect.",
               default: :immediate

      property :new_hostname, String,
               description: "Specifies a new hostname for the computer in the new domain.",
               introduced: "14.5"

      # define this again so we can default it to true. Otherwise failures print the password
      property :sensitive, [TrueClass, FalseClass],
               default: true, desired_state: false

      action :join do
        description "Join the Active Directory domain."

        unless on_domain?
          cmd = "$pswd = ConvertTo-SecureString \'#{new_resource.domain_password}\' -AsPlainText -Force;"
          cmd << "$credential = New-Object System.Management.Automation.PSCredential (\"#{new_resource.domain_user}@#{new_resource.domain_name}\",$pswd);"
          cmd << "Add-Computer -DomainName #{new_resource.domain_name} -Credential $credential"
          cmd << " -OUPath \"#{new_resource.ou_path}\"" if new_resource.ou_path
          cmd << " -NewName \"#{new_resource.new_hostname}\"" if new_resource.new_hostname
          cmd << " -Force"

          converge_by("join Active Directory domain #{new_resource.domain_name}") do
            ps_run = powershell_out(cmd)
            if ps_run.error?
              if sensitive?
                raise "Failed to join the domain #{new_resource.domain_name}: *suppressed sensitive resource output*"
              else
                raise "Failed to join the domain #{new_resource.domain_name}: #{ps_run.stderr}"
              end
            end

            unless new_resource.reboot == :never
              reboot "Reboot to join domain #{new_resource.domain_name}" do
                action clarify_reboot(new_resource.reboot)
                reason "Reboot to join domain #{new_resource.domain_name}"
              end
            end
          end
        end
      end

      action_class do
        def on_domain?
          node_domain = powershell_out!("(Get-WmiObject Win32_ComputerSystem).Domain")
          raise "Failed to check if the system is joined to the domain #{new_resource.domain_name}: #{node_domain.stderr}}" if node_domain.error?
          node_domain.stdout.downcase.strip == new_resource.domain_name.downcase
        end

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

        def sensitive?
          !!new_resource.sensitive
        end
      end
    end
  end
end
