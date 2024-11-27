package "snapd" do
  action :upgrade
end

service "snapd" do
  action :start
end

snap_package "hello" do
  # there was originally a 5 second sleep before this
  action :install
  channel "stable"
  retries 2
  retry_delay 15
end

snap_package "hello" do
  action :upgrade
  channel "edge"
end

snap_package "hello" do
  action :remove
end

snap_package "hello"

snap_package "hello" do
  action :purge
end

snap_package "hello" do
  options ["devmode"]
end

snap_package "hello" do
  action :remove
end

snap_package %w{hello expect} do
  # this action seems to be finicky after the removal
  # action
  retries 2
  retry_delay 60
end
