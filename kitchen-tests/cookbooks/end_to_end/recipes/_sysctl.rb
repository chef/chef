#
# Cookbook:: end_to_end
# Recipe:: sysctl
#

sysctl "vm.swappiness" do
  value 19
end

sysctl "kernel.msgmax" do
  action :remove
end