#
# Author:: John McCrae (<jmccrae@chef.io>)
# Author:: Davin Taddeo (<davin@chef.io>)
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

class Chef
  class Resource
    class WindowsFirewallProfile < Chef::Resource
      provides :windows_firewall_profile
      description "Use the **windows_firewall_profile** resource to enable, disable, and configure the Windows firewall."
      introduced "16.3"

      examples <<~DOC
      **Enable and Configure the Private Profile of the Windows Profile**:

      ```ruby
      windows_firewall_profile 'Configure and Enable Windows Firewall Private Profile' do
        profiles 'Private'
        default_inbound_action 'True'
        default_outbound_action 'True'
        allow_inbound_rules 'True'
        display_notification 'False'
        action :enable
      end
      ```

      **Enable and Configure the Public Profile of the Windows Firewall**:

      ```ruby
      windows_firewall_profile 'Configure and Enable Windows Firewall Public Profile' do
        profile 'Public'
        default_inbound_action 'True'
        default_outbound_action 'True'
        allow_inbound_rules 'False'
        display_notification 'False'
        action :enable
      end
      ```

      **Disable the Domain Profile of the Windows Firewall**:

      ```ruby
      windows_firewall_profile 'Disable the Domain Profile of the Windows Firewall' do
        profile 'Domain'
        action :disable
      end
      ```
      DOC

      unified_mode true

      property :profile, String,
        name_property: true,
        equal_to: %w{ Domain Public Private },
        description: "Set the Windows Profile being configured"

      property :default_inbound_action, [String, nil],
        equal_to: %w{ Allow Block NotConfigured },
        description: "Set the default policy for inbound network traffic"

      property :default_outbound_action, [String, nil],
        equal_to: %w{ Allow Block NotConfigured },
        description: "Set the default policy for outbound network traffic"

      property :allow_inbound_rules, String, equal_to: %w{ True False NotConfigured }, description: "Allow users to set inbound firewall rules"
      property :allow_local_firewall_rules, String, equal_to: %w{ True False NotConfigured }, description: "Merges inbound firewall rules into the policy"
      property :allow_local_ipsec_rules, String, equal_to: %w{ True False NotConfigured }, description: "Allow users to manage local connection security rules"
      property :allow_user_apps, String, equal_to: %w{ True False NotConfigured }, description: "Allow user applications to manage firewall"
      property :allow_user_ports, String, equal_to: %w{ True False NotConfigured }, description: "Allow users to manage firewall port rules"
      property :allow_unicast_response, String, equal_to: %w{ True False NotConfigured }, description: "Allow unicast responses to multicast and broadcast messages"
      property :display_notification, String, equal_to: %w{ True False NotConfigured }, description: "Display a notification when firewall blocks certain activity"

      load_current_value do |desired|
        ps_get_net_fw_profile = load_firewall_state(desired.profile)
        output = powershell_out(ps_get_net_fw_profile)
        if output.stdout.empty?
          current_value_does_not_exist!
        else
          state = Chef::JSONCompat.from_json(output.stdout)
        end

        default_inbound_action state["default_inbound_action"]
        default_outbound_action state["default_outbound_action"]
        allow_inbound_rules state["allow_inbound_rules"]
        allow_local_firewall_rules state["allow_local_firewall_rules"]
        allow_local_ipsec_rules state["allow_local_ipsec_rules"]
        allow_user_apps state["allow_user_apps"]
        allow_user_ports state["allow_user_ports"]
        allow_unicast_response state["allow_unicast_response"]
        display_notification state["display_notification"]
      end

      action :enable do
        converge_if_changed :default_inbound_action, :default_outbound_action, :allow_inbound_rules, :allow_local_firewall_rules,
          :allow_local_ipsec_rules, :allow_user_apps, :allow_user_ports, :allow_unicast_response, :display_notification do
            fw_cmd = firewall_command(new_resource.profile)
            powershell_exec!(fw_cmd)
          end
        unless firewall_enabled?(new_resource.profile)
          converge_by "Enable the #{new_resource.profile} Firewall Profile" do
            cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} -Enabled \"True\""
            powershell_exec!(cmd)
          end
        end
      end

      action :disable do
        if firewall_enabled?(new_resource.profile)
          converge_by "Disable the #{new_resource.profile} Firewall Profile" do
            cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} -Enabled \"False\""
            powershell_exec(cmd)
          end
        end
      end

      action_class do
        def firewall_command(fw_profile)
          cmd = "Set-NetFirewallProfile -Profile \"#{fw_profile}\""
          cmd << " -DefaultInboundAction \"#{new_resource.default_inbound_action}\"" unless new_resource.default_inbound_action.nil?
          cmd << " -DefaultOutboundAction \"#{new_resource.default_outbound_action}\"" unless new_resource.default_outbound_action.nil?
          cmd << " -AllowInboundRules \"#{new_resource.allow_inbound_rules}\"" unless new_resource.allow_inbound_rules.nil?
          cmd << " -AllowLocalFirewallRules \"#{new_resource.allow_local_firewall_rules}\""
          cmd << " -AllowLocalIPsecRules \"#{new_resource.allow_local_ipsec_rules}\"" unless new_resource.allow_local_ipsec_rules.nil?
          cmd << " -AllowUserApps \"#{new_resource.allow_user_apps}\"" unless new_resource.allow_user_apps.nil?
          cmd << " -AllowUserPorts \"#{new_resource.allow_user_ports}\"" unless new_resource.allow_user_ports.nil?
          cmd << " -AllowUnicastResponseToMulticast \"#{new_resource.allow_unicast_response}\"" unless new_resource.allow_unicast_response.nil?
          cmd << " -NotifyOnListen \"#{new_resource.display_notification}\"" unless new_resource.display_notification.nil?
          cmd
        end

        def load_firewall_state(profile_name)
          <<-EOH
            Remove-TypeData System.Array # workaround for PS bug here: https://bit.ly/2SRMQ8M
            $#{profile_name} = Get-NetFirewallProfile -Profile #{profile_name}
            ([PSCustomObject]@{
              default_inbound_action = $#{profile_name}.DefaultInboundAction.ToString()
              default_outbound_action = $#{profile_name}.DefaultOutboundAction.ToString()
              allow_inbound_rules = $#{profile_name}.AllowInboundRules.ToString()
              allow_local_firewall_rules = $#{profile_name}.AllowLocalFirewallRules.ToString()
              allow_local_ipsec_rules = $#{profile_name}.AllowLocalIPsecRules.ToString()
              allow_user_apps = $#{profile_name}.AllowUserApps.ToString()
              allow_user_ports = $#{profile_name}.AllowUserPorts.ToString()
              allow_unicast_response = $#{profile_name}.AllowUnicastResponseToMulticast.ToString()
              display_notification = $#{profile_name}.NotifyOnListen.ToString()
            }) | ConvertTo-Json
          EOH
        end

        def firewall_enabled?(profile_name)
          powershell_exec(<<-CODE).result
            $#{profile_name} = Get-NetFirewallProfile -Profile #{profile_name}
            if ($#{profile_name}.Enabled) {
                return $true
            } else {return $false}
          CODE
        end
      end
    end
  end
end
