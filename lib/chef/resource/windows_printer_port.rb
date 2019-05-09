#
# Author:: Doug Ireton <doug@1strategy.com>
# Copyright:: 2012-2018, Nordstrom, Inc.
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
      require "resolv"

      resource_name :windows_printer_port
      provides(:windows_printer_port) { true }

      description "Use the windows_printer_port resource to create and delete TCP/IPv4 printer ports on Windows."
      introduced "14.0"

      property :ipv4_address, String,
               name_property: true,
               regex: Resolv::IPv4::Regex,
               validation_message: "The ipv4_address property must be in the format of WWW.XXX.YYY.ZZZ!",
               description: "An optional property for the IPv4 address of the printer if it differs from the resource block's name."

      property :port_name, String,
               description: "The port name."

      property :port_number, Integer,
               description: "The port number.",
               default: 9100

      property :port_description, String,
               description: "The description of the port."

      property :snmp_enabled, [TrueClass, FalseClass],
               description: "Determines if SNMP is enabled on the port.",
               default: false

      property :port_protocol, Integer,
               description: "The printer port protocol: 1 (RAW) or 2 (LPR).",
               validation_message: "port_protocol must be either 1 for RAW or 2 for LPR!",
               default: 1, equal_to: [1, 2]

      property :exists, [TrueClass, FalseClass],
               skip_docs: true

      PORTS_REG_KEY = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports\\'.freeze unless defined?(PORTS_REG_KEY)

      def port_exists?(name)
        port_reg_key = PORTS_REG_KEY + name

        logger.trace "Checking to see if this reg key exists: '#{port_reg_key}'"
        registry_key_exists?(port_reg_key)
      end

      # @todo Set @current_resource port properties from registry
      load_current_value do |desired|
        name desired.name
        ipv4_address desired.ipv4_address
        port_name desired.port_name || "IP_#{desired.ipv4_address}"
        exists port_exists?(desired.port_name || "IP_#{desired.ipv4_address}")
      end

      action :create do
        description "Create the new printer port if it does not already exist."

        if current_resource.exists
          Chef::Log.info "#{@new_resource} already exists - nothing to do."
        else
          converge_by("Create #{@new_resource}") do
            create_printer_port
          end
        end
      end

      action :delete do
        description "Delete an existing printer port."

        if current_resource.exists
          converge_by("Delete #{@new_resource}") do
            delete_printer_port
          end
        else
          Chef::Log.info "#{@current_resource} doesn't exist - can't delete."
        end
      end

      action_class do
        def create_printer_port
          port_name = new_resource.port_name || "IP_#{new_resource.ipv4_address}"

          # create the printer port using PowerShell
          declare_resource(:powershell_script, "Creating printer port #{new_resource.port_name}") do
            code <<-EOH

              Set-WmiInstance -class Win32_TCPIPPrinterPort `
                -EnableAllPrivileges `
                -Argument @{ HostAddress = "#{new_resource.ipv4_address}";
                            Name        = "#{port_name}";
                            Description = "#{new_resource.port_description}";
                            PortNumber  = "#{new_resource.port_number}";
                            Protocol    = "#{new_resource.port_protocol}";
                            SNMPEnabled = "$#{new_resource.snmp_enabled}";
                          }
            EOH
          end
        end

        def delete_printer_port
          port_name = new_resource.port_name || "IP_#{new_resource.ipv4_address}"

          declare_resource(:powershell_script, "Deleting printer port: #{new_resource.port_name}") do
            code <<-EOH
              $port = Get-WMIObject -class Win32_TCPIPPrinterPort -EnableAllPrivileges -Filter "name = '#{port_name}'"
              $port.Delete()
            EOH
          end
        end
      end
    end
  end
end
