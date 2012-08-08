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

bookshelf_dir = node['chef_server']['bookshelf']['dir']
bookshelf_etc_dir = File.join(bookshelf_dir, "etc")
bookshelf_log_dir = node['chef_server']['bookshelf']['log_directory']
bookshelf_sasl_log_dir = File.join(bookshelf_log_dir, "sasl")
bookshelf_data_dir = node['chef_server']['bookshelf']['data_dir']
[
  bookshelf_dir,
  bookshelf_etc_dir,
  bookshelf_log_dir,
  bookshelf_sasl_log_dir,
  bookshelf_data_dir,
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

link "/opt/chef-server/embedded/service/bookshelf/log" do
  to bookshelf_log_dir
end

template "/opt/chef-server/embedded/service/bookshelf/bin/bookshelf" do
  source "bookshelf.erb"
  owner "root"
  group "root"
  mode "0755"
  variables(node['chef_server']['bookshelf'].to_hash)
  notifies :restart, 'service[bookshelf]' if OmnibusHelper.should_notify?("bookshelf")
end

bookshelf_config = File.join(bookshelf_etc_dir, "app.config")

template bookshelf_config do
  source "bookshelf.config.erb"
  mode "644"
  variables(node['chef_server']['bookshelf'].to_hash)
  notifies :restart, 'service[bookshelf]' if OmnibusHelper.should_notify?("bookshelf")
end

link "/opt/chef-server/embedded/service/bookshelf/etc/app.config" do
  to bookshelf_config
end

runit_service "bookshelf" do
  down node['chef_server']['bookshelf']['ha']
  options({
    :log_directory => bookshelf_log_dir,
    :svlogd_size => node['chef_server']['bookshelf']['svlogd_size'],
    :svlogd_num  => node['chef_server']['bookshelf']['svlogd_num']
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
  execute "/opt/chef-server/bin/chef-server-ctl start bookshelf" do
    retries 20
  end
end
