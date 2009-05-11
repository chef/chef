#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'mixlib/config'

class Chef::Config
  extend(Mixlib::Config)

  daemonize nil
  user nil
  group nil
  pid_file nil
  delay 0
  interval 1800
  splay nil
  solo  false
  json_attribs nil
  cookbook_path [ "/var/chef/site-cookbooks", "/var/chef/cookbooks" ]
  validation_token nil
  node_path "/var/chef/node"
  file_store_path "/var/chef/store"
  search_index_path "/var/chef/search_index"
  log_level :info
  log_location STDOUT
  openid_providers nil
  ssl_verify_mode :verify_none
  ssl_client_cert ""
  ssl_client_key ""
  rest_timeout 60
  couchdb_url "http://localhost:5984"
  registration_url "http://localhost:4000"
  openid_url "http://localhost:4001"
  template_url "http://localhost:4000"
  remotefile_url "http://localhost:4000"
  search_url "http://localhost:4000"
  couchdb_version nil
  couchdb_database "chef"
  openid_store_couchdb false
  openid_cstore_couchdb false
  openid_store_path "/var/chef/openid/db"
  openid_cstore_path "/var/chef/openid/cstore"
  file_cache_path "/var/chef/cache"
  node_name nil
  executable_path ENV['PATH'] ? ENV['PATH'].split(File::PATH_SEPARATOR) : []
  http_retry_delay 5
  http_retry_count 5
  queue_retry_delay 5
  queue_retry_count 5
  queue_retry_delay 5
  queue_retry_count 5
  queue_user ""
  queue_password ""
  queue_host "localhost"
  queue_port 61613
  run_command_stdout_timeout 120
  run_command_stderr_timeout 120
  authorized_openid_identifiers nil
end
