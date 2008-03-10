#namespace :openldap do
#  recipe :auth do |n|

include_recipe 'openldap::client'
include_recipe 'openssh'
include_recipe 'nscd'

file "/etc/nsswitch.conf" {
  insure = "present"
  owner  = "root"
  group  = "root" 
  mode   = 0644
}

file "/etc/ldap.conf" {
  insure   = "present"
  owner    = "root"
  group    = "root"
  mode     = 0644
  requires = resources(:file => "/etc/nsswitch.conf")
}

file "/etc/ldap.conf" do
  insure   = "present"
  owner    = "root"
  group    = "root"
  mode     = 0644
  requires = resources()
end

remote_file "nsswitch.conf" {
  path     "/etc/nsswitch.conf"
  source   "nsswitch.conf"
  module   "openldap"
  mode     0644
  owner    "root"
  group    "root"
  requires :file => "nsswitch-ldap-file", :exec => [ "one", "two" ]
  notifies :service => "nscd", :exec => [ "nscd-clear-passwd", "nscd-clear-group" ]
  provider 'File::Rsync'
}

remote_file "nsswitch.conf" {
  path     = "/etc/nsswitch.conf"
  source   = "nsswitch.conf"
  module   = "openldap"
  mode     = 0644
  owner    = "root"
  group    = "root"
  requires = resources :file => "nsswitch-ldap-file", 
                       :exec => [ "one", "two" ]
  notifies = resources :service => "nscd",
                       :exec => [ "nscd-clear-passwd", "nscd-clear-group" ]
  provider = 'File::Rsync'
}

service "nscd" do |s|
  s.insure = "running"
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
    p.insure = "latest"
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

