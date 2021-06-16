#
# Author:: Doug Ireton <doug@1strategy.com>
# Copyright:: 2012-2018, Nordstrom, Inc.
# Copyright:: Chef Software, Inc.
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
# See here for more info:
# http://msdn.microsoft.com/en-us/library/windows/desktop/aa394492(v=vs.85).aspx

require_relative "../resource"

class Chef
  class Resource
    class WindowsPrinterPort < Chef::Resource
      unified_mode true

      autoload :Resolv, "resolv"

      provides(:windows_printer_port) { true }

      description "Use the **windows_printer_port** resource to create and delete TCP/IPv4 printer ports on Windows."
      introduced "14.0"
      examples <<~DOC
      **Delete a printer port**

      ```ruby
      windows_printer_port '10.4.64.37' do
        action :delete
      end
      ```

      **Delete a port with a custom port_name**

      ```ruby
      windows_printer_port '10.4.64.38' do
        port_name 'My awesome port'
        action :delete
      end
      ```

      **Create a port with more options**

      ```ruby
      windows_printer_port '10.4.64.39' do
        port_name 'My awesome port'
        snmp_enabled true
        port_protocol 2
      end
      ```
      DOC

      property :ipv4_address, String,
        name_property: true,
        description: "An optional property for the IPv4 address of the printer if it differs from the resource block's name.",
        callbacks: {
          "The ipv4_address property must be in the format of WWW.XXX.YYY.ZZZ!" =>
            proc { |v| v.match(Resolv::IPv4::Regex) },
        }

      property :port_name, String,
        description: "The port name.",
        default: lazy { |x| "IP_#{x.ipv4_address}" },
        default_description: "The resource block name or the ipv4_address prepended with IP_."

      property :port_number, Integer,
        description: "The TCP port number.",
        default: 9100

      property :port_description, String,
        desired_state: false,
        deprecated: true

      property :snmp_enabled, [TrueClass, FalseClass],
        description: "Determines if SNMP is enabled on the port.",
        default: false

      property :port_protocol, Integer,
        description: "The printer port protocol: 1 (RAW) or 2 (LPR).",
        validation_message: "port_protocol must be either 1 for RAW or 2 for LPR!",
        default: 1, equal_to: [1, 2]

      load_current_value do |new_resource|
        port_data = powershell_exec(%Q{Get-WmiObject -Class Win32_TCPIPPrinterPort -Filter "Name='#{new_resource.port_name}'"}).result

        if port_data.empty?
          current_value_does_not_exist!
        else
          ipv4_address port_data["HostAddress"]
          port_name port_data["Name"]
          snmp_enabled port_data["SNMPEnabled"]
          port_protocol port_data["Protocol"]
          port_number port_data["PortNumber"]
        end
      end

      action :create, description: "Create or update the printer port." do
        converge_if_changed do
          if current_resource
            # update the printer port using PowerShell
            powershell_exec! <<-EOH
            Get-WmiObject Win32_TCPIPPrinterPort -EnableAllPrivileges -filter "Name='#{new_resource.port_name}'" |
            ForEach-Object{
                 $_.HostAddress='#{new_resource.ipv4_address}'
                 $_.PortNumber='#{new_resource.port_number}'
                 $_.Protocol='#{new_resource.port_protocol}'
                 $_.SNMPEnabled='$#{new_resource.snmp_enabled}'
                 $_.Put()
            }
            EOH
          else
            # create the printer port using PowerShell
            powershell_exec! <<-EOH
            Set-WmiInstance -class Win32_TCPIPPrinterPort `
              -EnableAllPrivileges `
              -Argument @{ HostAddress = "#{new_resource.ipv4_address}";
                          Name        = "#{new_resource.port_name}";
                          PortNumber  = "#{new_resource.port_number}";
                          Protocol    = "#{new_resource.port_protocol}";
                          SNMPEnabled = "$#{new_resource.snmp_enabled}";
                        }
            EOH
          end

        end
      end

      action :delete, description: "Delete an existing printer port." do
        if current_resource
          converge_by("delete port #{new_resource.port_name}") do
            powershell_exec!("Remove-PrinterPort -Name #{new_resource.port_name}")
          end
        else
          Chef::Log.info "#{new_resource.port_name} doesn't exist - can't delete."
        end
      end
    end
  end
end
