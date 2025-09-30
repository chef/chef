#
# Cookbook:: end_to_end
# Recipe:: sysctl
#

# Fix for debian-13 not having sysctl.conf file out of the box
file "/etc/sysctl.conf" do
  mode 0644
  action :create_if_missing
end

sysctl "vm.swappiness" do
  value 19
end

sysctl "kernel.msgmax" do
  value 9000
end

sysctl "kernel.msgmax" do
  action :remove
end

sysctl_param "bogus.sysctl_val" do
  value 9000
  action :remove
end
