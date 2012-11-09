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

pedant_dir = node['chef_server']['chef-pedant']['dir']
pedant_etc_dir = File.join(pedant_dir, "etc")
pedant_log_dir = node['chef_server']['chef-pedant']['log_directory']
[
  pedant_dir,
  pedant_etc_dir,
  pedant_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

pedant_config = File.join(pedant_etc_dir, "pedant_config.rb")

superuser_name = node['chef_server']['chef-server-webui']['web_ui_admin_user_name']
superuser_key = "/etc/chef-server/#{node['chef_server']['chef-server-webui']['web_ui_admin_user_name']}.pem"

template pedant_config do
  owner "root"
  group "root"
  mode  "0755"
  variables :api_url  => node['chef_server']['nginx']['url'],
            :solr_url => node['chef_server']['chef-solr']['url'],
            :superuser_name => superuser_name,
            :superuser_key => superuser_key
end
