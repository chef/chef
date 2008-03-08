include_recipe "openldap"
include_recipe "openldap::client"
include_recipe "openldap::server"
include_recipe "resolver"
include_recipe "base"

service "apache2" do
  insure "running"
  has_restart true
end

file "/etc/nsswitch.conf" do 
  insure "present"
  owner  "root"
  group  "root" 
  mode   0644
  notify :restart, resources(:service => "openldap"), :immediately
end

file "/etc/ldap.conf" do
  insure   "present"
  owner    "root"
  group    "root"
  mode     0644
  requires resources(:file => "/etc/nsswitch.conf")
end

file "/srv/monkey" do
  insure   "present"
  owner    "root"
  group    "root"
  mode     0644
end

file "/srv/owl" do
  insure   "present"
  owner    "root"
  group    "root"
  mode     0644
end

file "/srv/zen" do
  insure   "absent"
end

# 
# file "/srv/monkey" do |f|
#   f.insure = "present"
#   f.owner = "adam"
#   f.group = "adam"
#   f.mode = 0644
#   f.before = resources(:file => "/etc/nsswitch.conf")
# end
# 
# file "/etc/ldap-nss.conf" do |f|
#   f.insure   = "present"
#   f.owner    = "root"
#   f.group    = "root"
#   f.mode     = 0644
#   f.notifies = :refresh, resources(:file => "/etc/ldap.conf")
# end
# 
# file "/etc/coffee.conf" do |f|
#   f.insure   = "present"
#   f.owner    = "root"
#   f.group    = "root"
#   f.mode     = 0644
#   f.subscribes = :polio, resources(:file => "/etc/nsswitch.conf")
# end