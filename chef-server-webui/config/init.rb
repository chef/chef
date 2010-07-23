#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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


require "merb-core" 
require "merb-haml"
require "merb-assets"
require "merb-helpers"

require 'coderay'

require 'chef'
require 'chef/solr'

require 'chef/role'
require 'chef/webui_user'


use_template_engine :haml

Merb::Config.use do |c|
  c[:name] = "chef-server-webui"
  c[:fork_for_class_load] = false
  c[:session_id_key]     = '_chef_server_session_id'
  c[:session_secret_key] = Chef::Config.manage_secret_key
  c[:session_store]      = 'cookie'
  
  c[:log_level] = Chef::Config[:log_level]
  if Chef::Config[:log_location].kind_of?(String)
    c[:log_file] = Chef::Config[:log_location]
  end
end

Chef::Config[:node_name] = Chef::Config[:web_ui_client_name]
Chef::Config[:client_key] = Chef::Config[:web_ui_key]

# Create the default admin user "admin" if no admin user exists  
unless Chef::WebUIUser.admin_exist
  user = Chef::WebUIUser.new
  user.name = Chef::Config[:web_ui_admin_user_name]
  user.set_password(Chef::Config[:web_ui_admin_default_password])
  user.admin = true
  user.save
end
