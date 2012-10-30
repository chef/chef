
file "/etc/nsswitch.conf" do 
  action :create
  owner  "root"
  group  "root" 
  mode   0644
end
