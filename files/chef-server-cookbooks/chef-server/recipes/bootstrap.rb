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

bootstrap_status_file = "/var/opt/chef-server/bootstrapped"
erchef_dir = "/opt/chef-server/embedded/service/erchef"

execute "verify-system-status" do
  command "curl -sf http://localhost:8000/_status"
  retries 20
  not_if { File.exists?(bootstrap_status_file) }
end

execute "boostrap-chef-server" do
  command "bin/bootstrap-chef-server"
  cwd erchef_dir
  not_if { File.exists?(bootstrap_status_file) }
  environment ( { 'CHEF_ADMIN_USER' => node['chef_server']['chef-server-webui']['web_ui_admin_user_name'],
                  'CHEF_ADMIN_PASS' => node['chef_server']['chef-server-webui']['web_ui_admin_default_password'] } )
end

file bootstrap_status_file do
  owner "root"
  group "root"
  mode "0600"
  content "All your bootstraps are belong to Chef"
end
