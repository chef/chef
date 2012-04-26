#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
#
# All Rights Reserved
#

expander_dir = node['chef_server']['chef-expander']['dir']
expander_etc_dir = File.join(expander_dir, "etc")
expander_log_dir = node['chef_server']['chef-expander']['log_directory']

[ expander_dir, expander_etc_dir, expander_log_dir ].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

expander_config = File.join(expander_etc_dir, "expander.rb")

template expander_config do
  source "expander.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  options = node['chef_server']['chef-expander'].to_hash
  options['reindexer'] = false
  variables(options)
  notifies :restart, 'service[chef-expander]' if OmnibusHelper.should_notify?("chef-expander")
end

runit_service "chef-expander" do
  down node['chef_server']['chef-expander']['ha'] 
  options({
    :log_directory => expander_log_dir
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
	execute "/opt/chef-server/bin/chef-server-ctl start chef-expander" do
		retries 20 
	end
end

