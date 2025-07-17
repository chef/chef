package "snapd" do
  action :upgrade
end

service "snapd" do
  action :start
end

snap_package "core" do
  # this is an attempt to keep Ubuntu 18.04 from failing
  action :install
  channel "stable"
  retries 2
  retry_delay 15
  notifies :run, "execute[wait_for_snapd]", :immediately
end

# Add a sleep to ensure snapd is fully ready
execute "wait_for_snapd" do
  command "sleep 10"
  action :nothing
  notifies :install, "snap_package[hello-install]", :immediately
end

snap_package "hello-install" do
  package_name "hello"
  action :nothing
  channel "stable"
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_after_install]", :immediately
end

# Wait between operations to avoid conflicts
execute "wait_after_install" do
  command "sleep 5"
  action :nothing
  notifies :upgrade, "snap_package[hello-upgrade]", :immediately
end

snap_package "hello-upgrade" do
  package_name "hello"
  action :nothing
  channel "edge"
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_after_upgrade]", :immediately
end

# Wait between operations
execute "wait_after_upgrade" do
  command "sleep 5"
  action :nothing
  notifies :remove, "snap_package[hello-remove]", :immediately
end

snap_package "hello-remove" do
  package_name "hello"
  action :nothing
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_after_remove]", :immediately
end

# Wait before reinstall
execute "wait_after_remove" do
  command "sleep 5"
  action :nothing
  notifies :install, "snap_package[hello-reinstall]", :immediately
end

snap_package "hello-reinstall" do
  package_name "hello"
  action :nothing
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_before_purge]", :immediately
end

# Wait before purge
execute "wait_before_purge" do
  command "sleep 5"
  action :nothing
  notifies :purge, "snap_package[hello-purge]", :immediately
end

snap_package "hello-purge" do
  package_name "hello"
  action :nothing
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_before_devmode]", :immediately
end

# Wait before devmode install
execute "wait_before_devmode" do
  command "sleep 5"
  action :nothing
  notifies :install, "snap_package[hello-devmode]", :immediately
end

snap_package "hello-devmode" do
  package_name "hello"
  action :nothing
  options ["devmode"]
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_before_final_remove]", :immediately
end

# Wait before final remove
execute "wait_before_final_remove" do
  command "sleep 5"
  action :nothing
  notifies :remove, "snap_package[hello-final-remove]", :immediately
end

snap_package "hello-final-remove" do
  package_name "hello"
  action :nothing
  retries 3
  retry_delay 30
  notifies :run, "execute[wait_before_multi_install]", :immediately
end

# Wait before multi-package install
execute "wait_before_multi_install" do
  command "sleep 10"
  action :nothing
  notifies :install, "snap_package[multi-package]", :immediately
end

snap_package "multi-package" do
  package_name %w{hello expect}
  action :nothing
  # this action seems to be finicky after the removal
  # action
  retries 3
  retry_delay 60
end
