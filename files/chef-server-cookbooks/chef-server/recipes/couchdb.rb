#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

couchdb_dir = node['chef_server']['couchdb']['dir']
couchdb_etc_dir =  File.join(node['chef_server']['couchdb']['dir'], "etc")
couchdb_data_dir = node['chef_server']['couchdb']['data_dir']
couchdb_data_dir_symlink = File.join(node['chef_server']['couchdb']['dir'], "db")
couchdb_log_dir = node['chef_server']['couchdb']['log_directory']

# Create the CouchDB directories
[ couchdb_dir, couchdb_etc_dir, couchdb_data_dir, couchdb_log_dir ].each do |dir_name|
  directory dir_name do
    mode "0700"
    recursive true
    owner node['chef_server']['user']['username']
  end
end

link couchdb_data_dir_symlink do
  to couchdb_data_dir
  not_if { couchdb_data_dir_symlink == couchdb_data_dir }
end

# Drop off the CouchDB configuration file
template File.join(couchdb_etc_dir, "local.ini") do
  source "local.ini.erb"
  owner node['chef_server']['user']['username'] 
  mode "0600"
  variables(node['chef_server']['couchdb'].to_hash)
  notifies :restart, "service[couchdb]" if OmnibusHelper.should_notify?("couchdb")
end

# Start and enable the service
runit_service "couchdb" do
  down node['chef_server']['couchdb']['ha']
  options({
    :log_directory => couchdb_log_dir
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
	execute "/opt/chef-server/bin/chef-server-ctl start couchdb" do
		retries 20 
	end
end

compact_script_command = File.join(couchdb_etc_dir, "compact_couch.rb")

# Drop off the CouchDB compaction script
template compact_script_command do
  source "compact_couchdb_and_views.rb.erb"
  mode "0755"
end

# Add it to cron
cron_email = node['chef_server']['notification_email']
cron_cmd = "if `test -d #{couchdb_data_dir}` ; then #{compact_script_command}; fi"

template "/etc/cron.d/couchdb_compact" do
  source "compact-cron-entry.erb"
  mode "0600"
  variables(
            :cron_email => cron_email,
            :cron_name => "compact couchdb",
            :cron_shell => "/bin/bash",
            :cron_home => couchdb_dir,
            :cron_schedule => "17 1,9,17 * * *",
            :cron_user => node['chef_server']['user']['username'],
            :cron_command => cron_cmd
            )
end

template "/etc/cron.d/couchdb_bounce" do
  source "couchdb-bounce-cron.erb"
  mode "0600"
end

