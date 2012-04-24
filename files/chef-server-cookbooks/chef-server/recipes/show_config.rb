#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

if File.exists?("/etc/chef-server/chef-server.rb")
	ChefServer[:node] = node
	ChefServer.from_file("/etc/chef-server/chef-server.rb")
end
config = ChefServer.generate_config(node['fqdn'])

puts Chef::JSONCompat.to_json_pretty(config)
exit 0

