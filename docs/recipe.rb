#namespace :openldap do
#  recipe :auth do |n|

include_recipe 'openldap::client'
include_recipe 'openssh'
include_recipe 'nscd'

remote_file "nsswitch.conf" do 
  path   "/etc/nsswitch.conf"
  source "nsswitch.conf"
  module "openldap"
  mode   0644
  owner  "root"
  group  "root"
  requires :file => "nsswitch-ldap-file", :exec => [ "one", "two" ]
  requires = resource(:file => "nsswitch-ldap-file")
  notifies = resource(:service => "nscd", :exec => [ "nscd-clear-passwd", "nscd-clear-group" ] )
  subscribes = 
  provider = 'File::Rsync'
end

service "nscd" do |s|
  s.ensure = "running"
end

case node[:lsbdistid]
when "CentOS"
  template_file "ldap.conf" do |f|
    f.path = "/etc/ldap.conf"
    f.content = "openldap/ldap.conf.erb"
    f.mode = 644
    f.owner = "root"
    f.group = "root"
    f.alias = "nsswitch-ldap-file"
    f.notify = resource(:exec => [ "nscd-clear-passwd", "nscd-clear-group"] )
    f.require = resource(:package => "nss_ldap")
  end
  package "nss_ldap" do |p|
    p.ensure = "latest"
  end
end
    
#  end
#end

definition "rails_app" do |n, args|
  check_arguments(args, {
      :port_number => 8000,
      :mongrel_servers => 2,
      :rails_environment => "production",
      :rails_path => nil,
      :rails_user => nil,
      :rails_group => nil,
      :canonical_hostname => false,
      :template => 'rails/rails.conf.erb'
    }
  )
  file "sites-#{@name}" do |f|
    
  end
end

