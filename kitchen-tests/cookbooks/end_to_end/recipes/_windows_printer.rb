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

# create a printer that will also create the port
windows_printer "HP LaserJet 6th Floor" do
  ipv4_address "10.4.64.40"
  driver_name "Generic / Text Only"
end

# create a printer that uses an existing port
windows_printer "HP LaserJet 5th Floor" do
  ipv4_address "10.4.64.41"
  driver_name "Generic / Text Only"
  port_name "My awesome port"
  create_port false
end
