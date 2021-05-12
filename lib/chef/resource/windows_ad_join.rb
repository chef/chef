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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class WindowsAdJoin < Chef::Resource
      provides :windows_ad_join

      unified_mode true

      description "Use the **windows_ad_join** resource to join a Windows Active Directory domain."
      introduced "14.0"
      examples <<~DOC
      **Join a domain**

      ```ruby
      windows_ad_join 'ad.example.org' do
        domain_user 'nick'
        domain_password 'p@ssw0rd1'
      end
      ```

      **Join a domain, as `win-workstation`**

      ```ruby
      windows_ad_join 'ad.example.org' do
        domain_user 'nick'
        domain_password 'p@ssw0rd1'
        new_hostname 'win-workstation'
      end
      ```

      **Leave the current domain and re-join the `local` workgroup**

      ```ruby
      windows_ad_join 'Leave domain' do
        action :leave
        workgroup 'local'
      end
      ```
      DOC

      property :domain_name, String,
        description: "An optional property to set the FQDN of the Active Directory domain to join if it differs from the resource block's name.",
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
        equal_to: %i{immediate delayed never request_reboot reboot_now},
        validation_message: "The reboot property accepts :immediate (reboot as soon as the resource completes), :delayed (reboot once the #{ChefUtils::Dist::Infra::PRODUCT} run completes), and :never (Don't reboot)",
        description: "Controls the system reboot behavior post domain joining. Reboot immediately, after the #{ChefUtils::Dist::Infra::PRODUCT} run completes, or never. Note that a reboot is necessary for changes to take effect.",
        default: :immediate

      property :reboot_delay, Integer,
        description: "The amount of time (in minutes) to delay a reboot request.",
        default: 0,
        introduced: "16.5"

      property :new_hostname, String,
        description: "Specifies a new hostname for the computer in the new domain.",
        introduced: "14.5"

      property :workgroup_name, String,
        description: "Specifies the name of a workgroup to which the computer is added to when it is removed from the domain. The default value is WORKGROUP. This property is only applicable to the :leave action.",
        introduced: "15.4"

      # define this again so we can default it to true. Otherwise failures print the password
      property :sensitive, [TrueClass, FalseClass],
        default: true, desired_state: false

      action :join, description: "Join the Active Directory domain." do
        unless on_desired_domain?
          cmd = "$pswd = ConvertTo-SecureString \'#{new_resource.domain_password}\' -AsPlainText -Force;"
          cmd << "$credential = New-Object System.Management.Automation.PSCredential (\"#{sanitize_usename}\",$pswd);"
          cmd << "Add-Computer -DomainName #{new_resource.domain_name} -Credential $credential"
          cmd << " -OUPath \"#{new_resource.ou_path}\"" if new_resource.ou_path
          cmd << " -NewName \"#{new_resource.new_hostname}\"" if new_resource.new_hostname
          cmd << " -Force"

          converge_by("join Active Directory domain #{new_resource.domain_name}") do
            ps_run = powershell_exec(cmd)
            if ps_run.error?
              if sensitive?
                raise "Failed to join the domain #{new_resource.domain_name}: *suppressed sensitive resource output*"
              else
                raise "Failed to join the domain #{new_resource.domain_name}: #{ps_run.errors}"
              end
            end

            unless new_resource.reboot == :never
              reboot "Reboot to join domain #{new_resource.domain_name}" do
                action clarify_reboot(new_resource.reboot)
                delay_mins new_resource.reboot_delay
                reason "Reboot to join domain #{new_resource.domain_name}"
              end
            end
          end
        end
      end

      action :leave, description: "Leave an Active Directory domain and re-join a workgroup." do
        if joined_to_domain?
          cmd = ""
          cmd << "$pswd = ConvertTo-SecureString \'#{new_resource.domain_password}\' -AsPlainText -Force;"
          cmd << "$credential = New-Object System.Management.Automation.PSCredential (\"#{sanitize_usename}\",$pswd);"
          cmd << "Remove-Computer"
          cmd << " -UnjoinDomainCredential $credential"
          cmd << " -NewName \"#{new_resource.new_hostname}\"" if new_resource.new_hostname
          cmd << " -WorkgroupName \"#{new_resource.workgroup_name}\"" if new_resource.workgroup_name
          cmd << " -Force"

          converge_by("leave Active Directory domain #{node_domain}") do
            ps_run = powershell_exec(cmd)
            if ps_run.error?
              if sensitive?
                raise "Failed to leave the domain #{node_domain}: *suppressed sensitive resource output*"
              else
                raise "Failed to leave the domain #{node_domain}: #{ps_run.errors}"
              end
            end

            unless new_resource.reboot == :never
              reboot "Reboot to leave domain #{new_resource.domain_name}" do
                action clarify_reboot(new_resource.reboot)
                delay_mins new_resource.reboot_delay
                reason "Reboot to leave domain #{new_resource.domain_name}"
              end
            end
          end
        end
      end

      action_class do
        #
        # @return [String] The domain name the node is joined to. When the node
        #   is not joined to a domain this will return the name of the
        #   workgroup the node is a member of.
        #
        def node_domain
          node_domain = powershell_exec!("(Get-WmiObject Win32_ComputerSystem).Domain")
          raise "Failed to check if the system is joined to the domain #{new_resource.domain_name}: #{node_domain.errors}}" if node_domain.error?

          node_domain.result.downcase.strip
        end

        #
        # @return [String] The workgroup the node is a member of. This will
        #   return an empty string if the system is not a member of a
        #   workgroup.
        #
        def node_workgroup
          node_workgroup = powershell_exec!("(Get-WmiObject Win32_ComputerSystem).Workgroup")
          raise "Failed to check if the system is currently a member of a workgroup" if node_workgroup.error?

          node_workgroup.result
        end

        #
        # @return [true, false] Whether or not the node is joined to ANY domain
        #
        def joined_to_domain?
          node_workgroup.empty? && !node_domain.empty?
        end

        #
        # @return [true, false] Whether or not the node is joined to the domain
        #   defined by the resource :domain_name property.
        #
        def on_desired_domain?
          node_domain == new_resource.domain_name.downcase
        end

        #
        # @return [String] the correct user and domain to use.
        #   if the domain_user property contains an @ symbol followed by any number of non white space characters
        #   then we assume it is a user from another domain than the one specified in the resource domain_name property.
        #   if this is the case we do not append the domain_name property to the domain_user property
        #   the domain_user and domain_name form the UPN (userPrincipalName)
        #   The specification for the UPN format is RFC 822
        #   links: https://docs.microsoft.com/en-us/windows/win32/ad/naming-properties#userprincipalname https://tools.ietf.org/html/rfc822
        #   regex: https://rubular.com/r/isAWojpTMKzlnp
        def sanitize_usename
          if /@/.match?(new_resource.domain_user)
            new_resource.domain_user
          else
            "#{new_resource.domain_user}@#{new_resource.domain_name}"
          end
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
