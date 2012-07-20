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

