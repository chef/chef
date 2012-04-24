#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
#
# All Rights Reserved
#

chef_server_webui_dir = node['chef_server']['chef-server-webui']['dir']
chef_server_webui_etc_dir = File.join(chef_server_webui_dir, "etc")
chef_server_webui_working_dir = File.join(chef_server_webui_dir, "working")
chef_server_webui_tmp_dir = File.join(chef_server_webui_dir, "tmp")
chef_server_webui_log_dir = node['chef_server']['chef-server-webui']['log_directory']

[ 
  chef_server_webui_dir,
  chef_server_webui_etc_dir,
  chef_server_webui_working_dir,
  chef_server_webui_tmp_dir,
  chef_server_webui_log_dir,

].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

should_notify = OmnibusHelper.should_notify?("chef-server-webui")

env_config = File.join(chef_server_webui_etc_dir, "#{node['chef_server']['chef-server-webui']['environment']}.rb")
session_store_config = File.join(chef_server_webui_etc_dir, "session_store.rb")
secret_token_config = File.join(chef_server_webui_etc_dir, "secret_token.rb")

template env_config do
  source "chef-server-webui-config.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['chef_server']['chef-server-webui'].to_hash)
  notifies :restart, 'service[chef-server-webui]' if should_notify
end

link "/opt/chef-server/embedded/service/chef-server-webui/config/environments/#{node['chef_server']['chef-server-webui']['environment']}.rb" do
  to env_config
end

template session_store_config do
  source "session_store.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['chef_server']['chef-server-webui'].to_hash)
  notifies :restart, 'service[chef-server-webui]' if should_notify
end

link "/opt/chef-server/embedded/service/chef-server-webui/config/initializers/session_store.rb" do
  to session_store_config
end

template secret_token_config do
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['chef_server']['chef-server-webui'].to_hash)
  notifies :restart, 'service[chef-server-webui]' if should_notify
end

link "/opt/chef-server/embedded/service/chef-server-webui/config/initializers/secret_token.rb" do
  to secret_token_config
end

unicorn_config File.join(chef_server_webui_etc_dir, "unicorn.rb") do
  listen node['chef_server']['chef-server-webui']['listen'] => { 
    :backlog => node['chef_server']['chef-server-webui']['backlog'],
    :tcp_nodelay => node['chef_server']['chef-server-webui']['tcp_nodelay']
  }
  worker_timeout node['chef_server']['chef-server-webui']['worker_timeout']
  working_directory chef_server_webui_working_dir 
  worker_processes node['chef_server']['chef-server-webui']['worker_processes']  
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[chef-server-webui]' if should_notify
end

link "/opt/chef-server/embedded/service/chef-server-webui/tmp" do
  to chef_server_webui_tmp_dir 
end

execute "chown -R #{node['chef_server']['user']['username']} /opt/chef-server/embedded/service/chef-server-webui/public" 

runit_service "chef-server-webui" do
  down node['chef_server']['chef-server-webui']['ha']
  options({
    :log_directory => chef_server_webui_log_dir
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
	execute "/opt/chef-server/bin/chef-server-ctl chef-server-webui start" do
		retries 20 
	end
end

