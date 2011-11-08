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

require 'merb-assets'
require 'merb-helpers'
require 'merb-param-protection'

require 'bunny'
require 'uuidtools'
require 'ohai'
require 'openssl'

require 'chef'
require 'chef/role'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/api_client'
require 'chef/webui_user'
require 'chef/certificate'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/cookbook_version'
require 'chef/sandbox'
require 'chef/checksum'
require 'chef/environment'
require 'chef/monkey_patches/regexp'


require 'mixlib/authentication'

Mixlib::Authentication::Log.logger = Ohai::Log.logger = Chef::Log.logger

# Only used for the error page when visiting with a browser...
use_template_engine :haml

Merb::Config.use do |c|
  c[:name] = "chef-server (api)"
  c[:fork_for_class_load] = false
  c[:session_id_key] = '_chef_server_session_id'
  c[:session_secret_key]  = Chef::Config.manage_secret_key
  c[:session_store] = 'cookie'
  c[:exception_details] = true
  c[:reload_classes] = false
  c[:log_level] = Chef::Config[:log_level]
  if Chef::Config[:log_location].kind_of?(String)
    c[:log_file] = Chef::Config[:log_location]
  end
end

unless Merb::Config.environment == "test"
  # create the couch design docs for nodes, roles, and databags
  Chef::CouchDB.new.create_db
  Chef::CouchDB.new.create_id_map
  Chef::Node.create_design_document
  Chef::Role.create_design_document
  Chef::DataBag.create_design_document
  Chef::ApiClient.create_design_document
  Chef::WebUIUser.create_design_document
  Chef::CookbookVersion.create_design_document
  Chef::Sandbox.create_design_document
  Chef::Checksum.create_design_document
  Chef::Environment.create_design_document

  # Create the signing key and certificate
  Chef::Certificate.generate_signing_ca

  # Generate the validation key
  Chef::Certificate.gen_validation_key

  # Generate the Web UI Key
  Chef::Certificate.gen_validation_key(Chef::Config[:web_ui_client_name], Chef::Config[:web_ui_key], true)

  # Create the '_default' Environment
  Chef::Environment.create_default_environment

  Chef::Log.info('Loading roles')
  Chef::Role.sync_from_disk_to_couchdb
end
