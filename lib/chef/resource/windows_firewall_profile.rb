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
      introduced "16.2"

      examples <<~DOC
      **Enable and Configure the Private Profile of the Windows Profile**:

      ```ruby
      windows_firewall_profile 'Configure and Enable Windows Firewall Private Profile' do
        profiles 'Private'
        profile_enabled true
        default_inbound_block true
        default_outbound_allow true
        allow_inbound_rules true
        display_notification false
      end
      ```

      **Enable and Configure the Public Profile of the Windows Firewall**:

      ```ruby
      windows_firewall_profile 'Configure and Enable Windows Firewall Public Profile' do
        profile 'Public'
        profile_enabled true
        default_inbound_block true
        default_outbound_allow true
        allow_inbound_rules false
        display_notification false
        action :configure
      end
      ```
      **Disable the Domain Profile of the Windows Firewall**:

      ```ruby
      windows_firewall_profile 'Disable the Domain Profile of the Windows Firewall' do
        profile 'Domain'
        profile_enabled false
        action :configure
      end
      ```
      DOC

      unified_mode true

      property :profile, String, required: true, equal_to: %w{ Domain Public Private }, description: "Set the Windows Profile being configured"
      property :profile_enabled, [true, false], default: true, description: "Set the status of the firewall profile to Enabled or Disabled"
      property :default_inbound_block, [true, false, nil], default: true, description: "Set the default policy for inbound network traffic to blocked"
      property :default_outbound_allow, [true, false, nil], default: true, description: "Set the default policy for outbound network traffic to blocked"
      property :allow_inbound_rules, [true, false, nil], description: "Allow users to set inbound firewall rules"
      property :allow_local_firewall_rules, [true, false, nil], description: "Merges inbound firewall rules into the policy"
      property :allow_local_ipsec_rules, [true, false, nil], description: "Allow users to manage local connection security rules"
      property :allow_user_apps, [true, false, nil], description: "Allow user applications to manage firewall"
      property :allow_user_ports, [true, false, nil], description: "Allow users to manage firewall port rules"
      property :allow_unicast_response, [true, false, nil], description: "Allow unicast responses to multicast and broadcast messages"
      property :display_notification, [true, false, nil], description: "Display a notification when firewall blocks certain activity"

      load_current_value do |desired|
        ps_results = powershell_exec(<<-CODE).result
          $#{desired.profile} = Get-NetFirewallProfile -Profile #{desired.profile}
          $#{desired.profile}.Enabled
          $#{desired.profile}.DefaultInboundAction
          $#{desired.profile}.DefaultOutboundAction
          $#{desired.profile}.AllowInboundRules
          $#{desired.profile}.AllowLocalFirewallRules
          $#{desired.profile}.AllowLocalIPsecRules
          $#{desired.profile}.AllowUserApps
          $#{desired.profile}.AllowUserPorts
          $#{desired.profile}.AllowUnicastResponseToMulticast
          $#{desired.profile}.NotifyOnListen
        CODE
        profile_enabled case ps_results[0]; when 0 then false; when 1 then true; end
        default_inbound_block case ps_results[1]; when 4 then true; when 2 then false; when 0 then nil; end
        default_outbound_allow case ps_results[2]; when 4 then false; when 2 then true; when 0 then nil; end
        allow_inbound_rules case ps_results[3]; when 0 then false; when 1 then true; when 2 then nil; end
        allow_local_firewall_rules case ps_results[4]; when 0 then false; when 1 then true; when 2 then nil; end
        allow_local_ipsec_rules case ps_results[5]; when 0 then false; when 1 then true; when 2 then nil; end
        allow_user_apps case ps_results[6]; when 0 then false; when 1 then true; when 2 then nil; end
        allow_user_ports case ps_results[7]; when 0 then false; when 1 then true; when 2 then nil; end
        allow_unicast_response case ps_results[8]; when 0 then false; when 1 then true; when 2 then nil; end
        display_notification case ps_results[9]; when 0 then false; when 1 then true; when 2 then nil; end
      end

      action :configure do
        converge_if_changed :profile_enabled do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-Enabled #{new_resource.profile_enabled ? "True" : "False"} "
          powershell_exec(cmd)
        end
        converge_if_changed :default_inbound_block do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-DefaultInboundAction NotConfigured " if new_resource.default_inbound_block.nil?
          cmd += "-DefaultInboundAction #{new_resource.default_inbound_block ? "Block" : "Allow"} " unless new_resource.default_inbound_block.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :default_outbound_allow do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-DefaultOutboundAction NotConfigured " if new_resource.default_outbound_allow.nil?
          cmd += "-DefaultOutboundAction #{new_resource.default_outbound_allow ? "Allow" : "Block"} " unless new_resource.default_outbound_allow.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :allow_inbound_rules do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-AllowInboundRules NotConfigured " if new_resource.allow_inbound_rules.nil?
          cmd += "-AllowInboundRules #{new_resource.allow_inbound_rules ? "True" : "False"} " unless new_resource.allow_inbound_rules.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :allow_local_firewall_rules do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-AllowLocalFirewallRules NotConfigured " if new_resource.allow_local_firewall_rules.nil?
          cmd += "-AllowLocalFirewallRules #{new_resource.allow_local_firewall_rules ? "True" : "False"} " unless new_resource.allow_local_firewall_rules.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :allow_local_ipsec_rules do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-AllowLocalIPsecRules NotConfigured " if new_resource.allow_local_ipsec_rules.nil?
          cmd += "-AllowLocalIPsecRules #{new_resource.allow_local_ipsec_rules ? "True" : "False"} " unless new_resource.allow_local_ipsec_rules.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :allow_user_apps do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-AllowUserApps NotConfigured " if new_resource.allow_user_apps.nil?
          cmd += "-AllowUserApps #{new_resource.allow_user_apps ? "True" : "False"} " unless new_resource.allow_user_apps.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :allow_user_ports do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-AllowUserPorts NotConfigured " if new_resource.allow_user_ports.nil?
          cmd += "-AllowUserPorts #{new_resource.allow_user_ports ? "True" : "False"} " unless new_resource.allow_user_ports.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :allow_unicast_response do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-AllowUnicastResponseToMulticast NotConfigured " if new_resource.allow_unicast_response.nil?
          cmd += "-AllowUnicastResponseToMulticast #{new_resource.allow_unicast_response ? "True" : "False"} " unless new_resource.allow_unicast_response.nil?
          powershell_exec(cmd)
        end
        converge_if_changed :display_notification do
          cmd = "Set-NetFirewallProfile -Profile #{new_resource.profile} "
          cmd += "-NotifyOnListen NotConfigured " if new_resource.display_notification.nil?
          cmd += "-NotifyOnListen #{new_resource.display_notification ? "True" : "False"} " unless new_resource.display_notification.nil?
          powershell_exec(cmd)
        end
      end
    end
  end
end
