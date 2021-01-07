package "snapd" do
  action :upgrade
end

service "snapd" do
  action :start
end

execute "sleep 5"

snap_package "black" do
  action :upgrade
  channel "beta"
end
