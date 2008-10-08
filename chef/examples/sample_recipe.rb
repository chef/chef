require_recipe "openldap"
require_recipe "openldap::client"
require_recipe "openldap::server"
require_recipe "resolver"
require_recipe "base"

exec "restart-apache" do
  path "/usr/bin:/usr/local/bin"
  command "/etc/init.d/apache2 restart"
  action :nothing
end

service "apache2" do
  insure "running"
  has_restart true
end

file "/etc/nsswitch.conf" do 
  owner  "root"
  group  "root" 
  mode   0644
  notifies :restart, resources("service[openldap]"), :immediately
end

service "apache2" do
  action "enabled"
  subscribes :restart, resources("/etc/nsswitch.conf"), :immediately
end

file "/etc/ldap.conf" do
  owner    "root"
  group    "root"
  mode     0644
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