#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "story_helper"))

steps_for(:chef_client) do
  # Given the node 'latte'
  Given("the node '$node'") do |node|
    @client = Chef::Client.new
    @client.build_node(node)
  end
  
  # Given it has not registered before
  Given("it has not registered before") do
    Chef::FileStore.load("registration", @client.safe_name)
  end

  # When it runs the chef-client
  
  # Then it should register with the Chef Server
  
  # Then CouchDB should have a 'openid_registration_latte' document
  
  # Then the registration validation should be 'false'
  
end

with_steps_for(:chef_client) do
  create_couchdb_database
  run File.join(File.dirname(__FILE__), "chef-client")
end