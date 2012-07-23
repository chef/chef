#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
#
# All Rights Reserved

opscode_erchef_dir = node['chef_server']['erchef']['dir']
opscode_erchef_etc_dir = File.join(opscode_erchef_dir, "etc")
opscode_erchef_log_dir = node['chef_server']['erchef']['log_directory']
opscode_erchef_sasl_log_dir = File.join(opscode_erchef_log_dir, "sasl")
[
  opscode_erchef_dir,
  opscode_erchef_etc_dir,
  opscode_erchef_log_dir,
  opscode_erchef_sasl_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

link "/opt/chef-server/embedded/service/erchef/log" do
  to opscode_erchef_log_dir
end

template "/opt/chef-server/embedded/service/erchef/bin/erchef" do
  source "erchef.erb"
  owner "root"
  group "root"
  mode "0755"
  variables(node['chef_server']['erchef'].to_hash)
  notifies :restart, 'service[erchef]' if OmnibusHelper.should_notify?("erchef")
end

erchef_config = File.join(opscode_erchef_etc_dir, "app.config")

template erchef_config do
  source "erchef.config.erb"
  mode "644"
  variables(node['chef_server']['erchef'].to_hash)
  notifies :restart, 'service[erchef]' if OmnibusHelper.should_notify?("erchef")
end

link "/opt/chef-server/embedded/service/erchef/etc/app.config" do
  to erchef_config
end

runit_service "erchef" do
  down node['chef_server']['erchef']['ha']
  options({
    :log_directory => opscode_erchef_log_dir,
    :svlogd_size => node['chef_server']['erchef']['svlogd_size'],
    :svlogd_num  => node['chef_server']['erchef']['svlogd_num']
  }.merge(params))
end

# if node['chef_server']['bootstrap']['enable']
# 	execute "/opt/chef-server/bin/chef-server-ctl erchef start" do
# 		retries 20
# 	end
# end
