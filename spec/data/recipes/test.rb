
file "/etc/nsswitch.conf" do 
  insure "present"
  owner  "root"
  group  "root" 
  mode   0644
end
