#
# Cookbook:: end_to_end
# Recipe:: _windows_printer
#
# Copyright:: Copyright (c) Chef Software Inc.
#

windows_printer_port "10.4.64.39" do
  port_name "My awesome port"
  snmp_enabled true
  port_protocol 2
end

# change the port above
windows_printer_port "10.4.64.39" do
  port_name "My awesome port"
  snmp_enabled false
  port_protocol 2
end

# delete a port that doesn't exist
windows_printer_port "10.4.64.37" do
  action :delete
end
