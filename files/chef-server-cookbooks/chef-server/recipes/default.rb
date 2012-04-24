#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#

require 'openssl'

ENV['PATH'] = "/opt/chef-server/bin:/opt/chef-server/embedded/bin:#{ENV['PATH']}"

directory "/etc/chef-server" do
  owner "root"
  group "root"
  mode "0755"
  action :nothing
end.run_action(:create)

if File.exists?("/etc/chef-server/chef-server.json")
  Chef::Log.warn("Please move to /etc/chef-server/chef-server.rb for configuration - /etc/chef-server/chef-server.json is deprecated.")
else
  ChefServer[:node] = node
  if File.exists?("/etc/chef-server/chef-server.rb")
    ChefServer.from_file("/etc/chef-server/chef-server.rb")
  end
  node.consume_attributes(ChefServer.generate_config(node['fqdn']))
end

if File.exists?("/var/opt/chef-server/bootstrapped")
	node['chef_server']['bootstrap']['enable'] = false
end

# Create the Chef User
include_recipe "chef-server::users"

file "/etc/chef-server/dark_launch_features.json" do
  owner "opscode"
  group "root"
  mode "0644"
  content Chef::JSONCompat.to_json_pretty(node['chef_server']['dark_launch'].to_hash)
end

webui_key = OpenSSL::PKey::RSA.generate(2048) unless File.exists?('/etc/chef-server/webui_pub.pem')

file "/etc/chef-server/webui_pub.pem" do
  owner "root"
  group "root"
  mode "0644"
  content webui_key.public_key.to_s unless File.exists?('/etc/chef-server/webui_pub.pem')
end

file "/etc/chef-server/webui_priv.pem" do
  owner "opscode"
  group "root"
  mode "0600"
  content webui_key.to_pem.to_s unless File.exists?('/etc/chef-server/webui_pub.pem')
end

worker_key = OpenSSL::PKey::RSA.generate(2048) unless File.exists?('/etc/chef-server/worker-public.pem')

file "/etc/chef-server/worker-public.pem" do
  owner "root"
  group "root"
  mode "0644"
  content worker_key.public_key.to_s unless File.exists?('/etc/chef-server/worker-public.pem')
end

file "/etc/chef-server/worker-private.pem" do
  owner "opscode"
  group "root"
  mode "0600"
  content worker_key.to_pem.to_s unless File.exists?('/etc/chef-server/worker-public.pem')
end

unless File.exists?('/etc/chef-server/pivotal.pem')
  cert, key = OmnibusHelper.gen_certificate  
end

file "/etc/chef-server/pivotal.cert" do
  owner "root"
  group "root"
  mode "0644"
  content cert.to_s unless File.exists?('/etc/chef-server/pivotal.pem')
end

file "/etc/chef-server/pivotal.pem" do
  owner "opscode"
  group "root"
  mode "0600"
  content key.to_pem.to_s unless File.exists?('/etc/chef-server/pivotal.pem')
end

directory "/etc/chef" do
  owner "root"
  group node['chef_server']['user']['username'] 
  mode "0775"
  action :create
end

directory "/var/opt/chef-server" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

# Install our runit instance
include_recipe "runit"

# Configure Services
[ 
  "couchdb", 
  "rabbitmq", 
  "chef-solr",
  "chef-expander",
  "chef-server-api",
  "chef-server-webui",
  "nginx"
].each do |service|
  if node["chef_server"][service]["enable"]
    include_recipe "chef-server::#{service}"
  else
    include_recipe "chef-server::#{service}_disable"
  end
end

file "/etc/chef-server/chef-server-running.json" do
  owner "opscode"
  group "root"
  mode "0644"
  content Chef::JSONCompat.to_json_pretty({ "chef_server" => node['chef_server'].to_hash, "run_list" => node.run_list })
end

