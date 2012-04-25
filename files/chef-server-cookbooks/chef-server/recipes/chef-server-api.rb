#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
#
# All Rights Reserved
#

chef_server_api_dir = node['chef_server']['chef-server-api']['dir']
chef_server_api_etc_dir = File.join(chef_server_api_dir, "etc")
chef_server_api_working_dir = File.join(chef_server_api_dir, "working")
chef_server_api_cache_dir = File.join(chef_server_api_dir, "cache")
chef_server_api_sandbox_dir = node['chef_server']['chef-server-api']['sandbox_path']
chef_server_api_checksum_dir = node['chef_server']['chef-server-api']['checksum_path']
chef_server_api_cookbook_cache_dir = File.join(chef_server_api_dir, "cookbooks_cache")
chef_server_api_log_dir = node['chef_server']['chef-server-api']['log_directory']

[ 
  chef_server_api_dir,
  chef_server_api_etc_dir,
  chef_server_api_working_dir,
  chef_server_api_cache_dir,
  chef_server_api_sandbox_dir,
  chef_server_api_checksum_dir,
  chef_server_api_cookbook_cache_dir,
  chef_server_api_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

chef_config = File.join(chef_server_api_etc_dir, "chef-server-api.conf")
env_config = File.join(chef_server_api_etc_dir, "#{node['chef_server']['chef-server-api']['environment']}.rb")

should_notify = OmnibusHelper.should_notify?("chef-server-api")

template chef_config do
  source "server.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['chef_server']['chef-server-api'].to_hash)
  notifies :restart, 'service[chef-server-api]' if should_notify
end

template "/opt/chef-server/embedded/lib/ruby/gems/1.9.1/gems/chef-server-api-#{Chef::VERSION}/config.ru" do
  source "chef-server-api.ru.erb" 
  mode "0644"
  owner "root"
  group "root"
  notifies :restart, 'service[chef-server-api]' if should_notify
end

unicorn_config File.join(chef_server_api_etc_dir, "unicorn.rb") do
  listen node['chef_server']['chef-server-api']['listen'] => { 
    :backlog => node['chef_server']['chef-server-api']['backlog'],
    :tcp_nodelay => node['chef_server']['chef-server-api']['tcp_nodelay']
  }
  worker_timeout node['chef_server']['chef-server-api']['worker_timeout']
  working_directory chef_server_api_working_dir 
  worker_processes node['chef_server']['chef-server-api']['worker_processes']  
  owner "root"
  group "root"
  mode "0644"
  log_listener true
  notifies :restart, 'service[chef-server-api]' if should_notify
end

runit_service "chef-server-api" do
  down node['chef_server']['chef-server-api']['ha']
  options({
    :log_directory => chef_server_api_log_dir
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
	execute "/opt/chef-server/bin/chef-server-ctl chef-server-api start" do
		retries 20 
	end
end

