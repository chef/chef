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

chef_server_webui_dir = node['chef_server']['chef-server-webui']['dir']
chef_server_webui_etc_dir = File.join(chef_server_webui_dir, "etc")
chef_server_webui_cache_dir = File.join(chef_server_webui_dir, "cache")
chef_server_webui_sandbox_dir = File.join(chef_server_webui_dir, "sandbox")
chef_server_webui_checksum_dir = File.join(chef_server_webui_dir, "checksum")
chef_server_webui_cookbook_tarball_dir = File.join(chef_server_webui_dir, "cookbook-tarballs")
chef_server_webui_working_dir = File.join(chef_server_webui_dir, "working")
chef_server_webui_log_dir = node['chef_server']['chef-server-webui']['log_directory']

[
  chef_server_webui_dir,
  chef_server_webui_etc_dir,
  chef_server_webui_cache_dir,
  chef_server_webui_sandbox_dir,
  chef_server_webui_checksum_dir,
  chef_server_webui_cookbook_tarball_dir,
  chef_server_webui_working_dir,
  chef_server_webui_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

should_notify = OmnibusHelper.should_notify?("chef-server-webui")

chef_server_webui_config = File.join(chef_server_webui_etc_dir, "server.rb")
config_ru = File.join(chef_server_webui_etc_dir, "config.ru")

template chef_server_webui_config do
  source "server-webui.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['chef_server']['chef-server-webui'].to_hash)
  notifies :restart, 'service[chef-server-webui]' if should_notify
end

template config_ru do
  source "chef-server-webui.ru.erb"
  mode "0644"
  owner "root"
  group "root"
  variables(node['chef_server']['chef-server-webui'].to_hash)
  notifies :restart, 'service[chef-server-webui]' if should_notify
end

file "/opt/chef-server/embedded/service/chef-server-webui/config.ru" do
  action :delete
  not_if "test -h /opt/chef-server/embedded/service/chef-server-webui/config.ru"
end

link "/opt/chef-server/embedded/service/chef-server-webui/config.ru" do
  to config_ru
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

runit_service "chef-server-webui" do
  down node['chef_server']['chef-server-webui']['ha']
  options({
    :log_directory => chef_server_webui_log_dir
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
	execute "/opt/chef-server/bin/chef-server-ctl start chef-server-webui" do
		retries 20
	end
end

