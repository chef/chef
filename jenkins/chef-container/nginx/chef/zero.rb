require 'chef-init'

cookbook_path   ["/etc/chef/cookbooks"]
ssl_verify_mode :verify_peer

#Ohai::Config[:directory] = "/etc/chef/ohai_plugins"
#Ohai::Config[:hints_path] = "/etc/chef/ohai/hints"
