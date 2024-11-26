package "snapd" do
  action :upgrade
end

service "snapd" do
  action :start
end

execute "sleep 10"

snap_package "hello" do
  action :install
  channel "stable"
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

snap_package %w{hello expect}
