# Author:: Matt Clifton (spartacus003@hotmail.com)
# Author:: Matt Stratton (matt.stratton@gmail.com)
# Author:: Tor Magnus Rakvåg (tor.magnus@outlook.com)
# Author:: Tim Smith (tsmith@chef.io)
# Copyright:: 2013-2015 Matt Clifton
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: 2018, Intility AS
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
    class WindowsFirewallRule < Chef::Resource
      unified_mode true

      provides :windows_firewall_rule

      description "Use the **windows_firewall_rule** resource to create, change or remove Windows firewall rules."
      introduced "14.7"
      examples <<~DOC
      **Allowing port 80 access**:

      ```ruby
      windows_firewall_rule 'IIS' do
        local_port '80'
        protocol 'TCP'
        firewall_action :allow
      end
      ```

      **Configuring multiple remote-address ports on a rule**:

      ```ruby
      windows_firewall_rule 'MyRule' do
        description          'Testing out remote address arrays'
        enabled              false
        local_port           1434
        remote_address       %w(10.17.3.101 172.7.7.53)
        protocol             'TCP'
        action               :create
      end
      ```

      **Allow protocol ICMPv6 with ICMP Type**:

      ```ruby
      windows_firewall_rule 'CoreNet-Rule' do
        rule_name 'CoreNet-ICMP6-LR2-In'
        display_name 'Core Networking - Multicast Listener Report v2 (ICMPv6-In)'
        local_port 'RPC'
        protocol 'ICMPv6'
        icmp_type '8'
      end
      ```

      **Blocking WinRM over HTTP on a particular IP**:

      ```ruby
      windows_firewall_rule 'Disable WinRM over HTTP' do
        local_port '5985'
        protocol 'TCP'
        firewall_action :block
        local_address '192.168.1.1'
      end
      ```

      **Deleting an existing rule**

      ```ruby
      windows_firewall_rule 'Remove the SSH rule' do
        rule_name 'ssh'
        action :delete
      end
      ```
      DOC

      property :rule_name, String,
        name_property: true,
        description: "An optional property to set the name of the firewall rule to assign if it differs from the resource block's name."

      property :description, String,
        description: "The description to assign to the firewall rule."

      property :displayname, String,
        description: "The displayname to assign to the firewall rule.",
        default: lazy { rule_name },
        default_description: "The rule_name property value.",
        introduced: "16.0"

      property :group, String,
        description: "Specifies that only matching firewall rules of the indicated group association are copied.",
        introduced: "16.0"

      property :local_address, String,
        description: "The local address the firewall rule applies to."

      property :local_port, [String, Integer, Array],
        # split various formats of comma separated lists and provide a sorted array of strings to match PS output
        coerce: proc { |d| d.is_a?(String) ? d.split(/\s*,\s*/).sort : Array(d).sort.map(&:to_s) },
        description: "The local port the firewall rule applies to."

      property :remote_address, [String, Array],
        coerce: proc { |d| d.is_a?(String) ? d.split(/\s*,\s*/).sort : Array(d).sort.map(&:to_s) },
        description: "The remote address(es) the firewall rule applies to."

      property :remote_port, [String, Integer, Array],
        # split various formats of comma separated lists and provide a sorted array of strings to match PS output
        coerce: proc { |d| d.is_a?(String) ? d.split(/\s*,\s*/).sort : Array(d).sort.map(&:to_s) },
        description: "The remote port the firewall rule applies to."

      property :direction, [Symbol, String],
        default: :inbound, equal_to: %i{inbound outbound},
        description: "The direction of the firewall rule. Direction means either inbound or outbound traffic.",
        coerce: proc { |d| d.is_a?(String) ? d.downcase.to_sym : d }

      property :protocol, String,
        default: "TCP",
        description: "The protocol the firewall rule applies to."

      property :icmp_type, [String, Integer],
        description: "Specifies the ICMP Type parameter for using a protocol starting with ICMP",
        default: "Any",
        introduced: "16.0"

      property :firewall_action, [Symbol, String],
        default: :allow, equal_to: %i{allow block notconfigured},
        description: "The action of the firewall rule.",
        coerce: proc { |f| f.is_a?(String) ? f.downcase.to_sym : f }

      property :profile, [Symbol, String, Array],
        default: :any,
        description: "The profile the firewall rule applies to.",
        coerce: proc { |p| Array(p).map(&:downcase).map(&:to_sym).sort },
        callbacks: {
          "contains values not in :public, :private, :domain, :any or :notapplicable" => lambda { |p|
            p.all? { |e| %i{public private domain any notapplicable}.include?(e) }
          },
        }

      property :program, String,
        description: "The program the firewall rule applies to."

      property :service, String,
        description: "The service the firewall rule applies to."

      property :interface_type, [Symbol, String],
        default: :any, equal_to: %i{any wireless wired remoteaccess},
        description: "The interface type the firewall rule applies to.",
        coerce: proc { |i| i.is_a?(String) ? i.downcase.to_sym : i }

      property :enabled, [TrueClass, FalseClass],
        default: true,
        description: "Whether or not to enable the firewall rule."

      alias_method :localip, :local_address
      alias_method :remoteip, :remote_address
      alias_method :localport, :local_port
      alias_method :remoteport, :remote_port
      alias_method :interfacetype, :interface_type

      load_current_value do
        load_state_cmd = load_firewall_state(rule_name)
        output = powershell_exec(load_state_cmd)
        if output.result.empty?
          current_value_does_not_exist!
        else
          state = output.result
        end

        # Need to reverse `$rule.Profile.ToString()` in powershell command
        current_profiles = state["profile"].split(", ").map(&:to_sym)

        description state["description"]
        displayname state["displayname"]
        group state["group"]
        local_address state["local_address"]
        local_port Array(state["local_port"]).sort
        remote_address Array(state["remote_address"]).sort
        remote_port Array(state["remote_port"]).sort
        direction state["direction"]
        protocol state["protocol"]
        icmp_type state["icmp_type"]
        firewall_action state["firewall_action"]
        profile current_profiles
        program state["program"]
        service state["service"]
        interface_type state["interface_type"]
        enabled state["enabled"]
      end

      action :create, description: "Create a Windows firewall entry." do
        if current_resource
          converge_if_changed :rule_name, :description, :displayname, :local_address, :local_port, :remote_address,
            :remote_port, :direction, :protocol, :icmp_type, :firewall_action, :profile, :program, :service,
            :interface_type, :enabled do
              cmd = firewall_command("Set")
              powershell_exec!(cmd)
            end
          converge_if_changed :group do
            powershell_exec!("Remove-NetFirewallRule -Name '#{new_resource.rule_name}'")
            cmd = firewall_command("New")
            powershell_exec!(cmd)
          end
        else
          converge_by("create firewall rule #{new_resource.rule_name}") do
            cmd = firewall_command("New")
            powershell_exec!(cmd)
          end
        end
      end

      action :delete, description: "Delete an existing Windows firewall entry." do
        if current_resource
          converge_by("delete firewall rule #{new_resource.rule_name}") do
            powershell_exec!("Remove-NetFirewallRule -Name '#{new_resource.rule_name}'")
          end
        else
          Chef::Log.info("Firewall rule \"#{new_resource.rule_name}\" doesn't exist. Skipping.")
        end
      end

      action_class do
        # build the command to create a firewall rule based on new_resource values
        # @return [String] firewall create command
        def firewall_command(cmdlet_type)
          cmd = "#{cmdlet_type}-NetFirewallRule -Name '#{new_resource.rule_name}'"
          cmd << " -DisplayName '#{new_resource.displayname}'" if new_resource.displayname && cmdlet_type == "New"
          cmd << " -NewDisplayName '#{new_resource.displayname}'" if new_resource.displayname && cmdlet_type == "Set"
          cmd << " -Group '#{new_resource.group}'" if new_resource.group && cmdlet_type == "New"
          cmd << " -Description '#{new_resource.description}'" if new_resource.description
          cmd << " -LocalAddress '#{new_resource.local_address}'" if new_resource.local_address
          cmd << " -LocalPort '#{new_resource.local_port.join("', '")}'" if new_resource.local_port
          cmd << " -RemoteAddress '#{new_resource.remote_address.join("', '")}'" if new_resource.remote_address
          cmd << " -RemotePort '#{new_resource.remote_port.join("', '")}'" if new_resource.remote_port
          cmd << " -Direction '#{new_resource.direction}'" if new_resource.direction
          cmd << " -Protocol '#{new_resource.protocol}'" if new_resource.protocol
          cmd << " -IcmpType '#{new_resource.icmp_type}'"
          cmd << " -Action '#{new_resource.firewall_action}'" if new_resource.firewall_action
          cmd << " -Profile '#{new_resource.profile.join("', '")}'" if new_resource.profile
          cmd << " -Program '#{new_resource.program}'" if new_resource.program
          cmd << " -Service '#{new_resource.service}'" if new_resource.service
          cmd << " -InterfaceType '#{new_resource.interface_type}'" if new_resource.interface_type
          cmd << " -Enabled '#{new_resource.enabled}'"

          cmd
        end

        def define_resource_requirements
          requirements.assert(:create) do |a|
            a.assertion do
              if new_resource.icmp_type.is_a?(String)
                !new_resource.icmp_type.empty?
              elsif new_resource.icmp_type.is_a?(Integer)
                !new_resource.icmp_type.nil?
              end
            end
            a.failure_message("The :icmp_type property can not be empty in #{new_resource.rule_name}")
          end

          requirements.assert(:create) do |a|
            a.assertion do
              if new_resource.icmp_type.is_a?(Integer)
                new_resource.protocol.start_with?("ICMP")
              elsif new_resource.icmp_type.is_a?(String) && !new_resource.protocol.start_with?("ICMP")
                new_resource.icmp_type == "Any"
              else
                true
              end
            end
            a.failure_message("The :icmp_type property has a value of #{new_resource.icmp_type} set, but is not allowed for :protocol #{new_resource.protocol} in #{new_resource.rule_name}")
          end

          requirements.assert(:create) do |a|
            a.assertion do
              if new_resource.icmp_type.is_a?(Integer)
                (0..255).cover?(new_resource.icmp_type)
              elsif new_resource.icmp_type.is_a?(String) && !new_resource.icmp_type.include?(":") && new_resource.protocol.start_with?("ICMP")
                (0..255).cover?(new_resource.icmp_type.to_i)
              elsif new_resource.icmp_type.is_a?(String) && new_resource.icmp_type.include?(":") && new_resource.protocol.start_with?("ICMP")
                new_resource.icmp_type.split(":").all? { |type| (0..255).cover?(type.to_i) }
              else
                true
              end
            end
            a.failure_message("Can not set :icmp_type to #{new_resource.icmp_type} as one value is out of range (0 to 255) in #{new_resource.rule_name}")
          end
        end
      end

      private

      # build the command to load the current resource
      # @return [String] current firewall state
      def load_firewall_state(rule_name)
        <<-EOH
          Remove-TypeData System.Array # workaround for PS bug here: https://bit.ly/2SRMQ8M
          $rule = Get-NetFirewallRule -Name '#{rule_name}'
          $addressFilter = $rule | Get-NetFirewallAddressFilter
          $portFilter = $rule | Get-NetFirewallPortFilter
          $applicationFilter = $rule | Get-NetFirewallApplicationFilter
          $serviceFilter = $rule | Get-NetFirewallServiceFilter
          $interfaceTypeFilter = $rule | Get-NetFirewallInterfaceTypeFilter
          ([PSCustomObject]@{
            rule_name = $rule.Name
            description = $rule.Description
            displayname = $rule.DisplayName
            group = $rule.Group
            local_address = $addressFilter.LocalAddress
            local_port = $portFilter.LocalPort
            remote_address = $addressFilter.RemoteAddress
            remote_port = $portFilter.RemotePort
            direction = $rule.Direction.ToString()
            protocol = $portFilter.Protocol
            icmp_type = $portFilter.IcmpType
            firewall_action = $rule.Action.ToString()
            profile = $rule.Profile.ToString()
            program = $applicationFilter.Program
            service = $serviceFilter.Service
            interface_type = $interfaceTypeFilter.InterfaceType.ToString()
            enabled = [bool]::Parse($rule.Enabled.ToString())
          })
        EOH
      end
    end
  end
end
