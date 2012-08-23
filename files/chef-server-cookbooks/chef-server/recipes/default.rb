#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'

ENV['PATH'] = "/opt/chef-server/bin:/opt/chef-server/embedded/bin:#{ENV['PATH']}"

directory "/etc/chef-server" do
  owner "root"
  group "root"
  mode "0775"
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

webui_key = OpenSSL::PKey::RSA.generate(2048) unless File.exists?('/etc/chef-server/webui_pub.pem')

file "/etc/chef-server/webui_pub.pem" do
  owner "root"
  group "root"
  mode "0644"
  content webui_key.public_key.to_s unless File.exists?('/etc/chef-server/webui_pub.pem')
end

file "/etc/chef-server/webui_priv.pem" do
  owner node['chef_server']['user']['username']
  group "root"
  mode "0600"
  content webui_key.to_pem.to_s unless File.exists?('/etc/chef-server/webui_pub.pem')
end

validator_key = OpenSSL::PKey::RSA.generate(2048) unless File.exists?('/etc/chef-server/validator.pem')

file "/etc/chef-server/validator.pem" do
  owner node['chef_server']['user']['username']
  group "root"
  mode "0600"
  content validator_key.to_pem.to_s unless File.exists?('/etc/chef-server/validator.pem')
end

file "/etc/chef-server/validator_pub.pem" do
  owner node['chef_server']['user']['username']
  group "root"
  mode "0600"
  content validator_key.public_key.to_pem.to_s unless File.exists?('/etc/chef-server/validator.pem')
end

unless File.exists?('/etc/chef-server/admin.pem')
  cert, key = OmnibusHelper.gen_certificate
end

file "/etc/chef-server/admin.cert" do
  owner "root"
  group "root"
  mode "0644"
  content cert.to_s unless File.exists?('/etc/chef-server/admin.pem')
end

file "/etc/chef-server/admin.pem" do
  owner node['chef_server']['user']['username']
  group "root"
  mode "0600"
  content key.to_pem.to_s unless File.exists?('/etc/chef-server/admin.pem')
end

file "/etc/chef-server/admin_pub.pem" do
  owner node['chef_server']['user']['username']
  group "root"
  mode "0600"
  content key.public_key.to_pem.to_s unless File.exists?('/etc/chef-server/admin.pem')
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
  "rabbitmq",
  "postgresql",
  "chef-solr",
  "chef-expander",
  "bookshelf",
  "erchef",
  "bootstrap",
 # FIXME: uncomment when we are ready to tackle the webui
 # "chef-server-webui",
  "nginx"
].each do |service|
  if node["chef_server"][service]["enable"]
    include_recipe "chef-server::#{service}"
  else
    include_recipe "chef-server::#{service}_disable"
  end
end

include_recipe "chef-server::chef-pedant"

file "/etc/chef-server/chef-server-running.json" do
  owner node['chef_server']['user']['username']
  group "root"
  mode "0644"
  content Chef::JSONCompat.to_json_pretty({ "chef_server" => node['chef_server'].to_hash, "run_list" => node.run_list })
end
