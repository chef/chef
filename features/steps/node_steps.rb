#
# Author:: Adam Jacob (<adam@opscode.com>)
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
#

###
# Given
###
Given /^a validated node$/ do
  # client should have cached ohai assigned to it
  client.determine_node_name
  client.register
  client.build_node
  client.node.run_list << "integration_setup"
end

Given /^a validated node with an empty runlist$/ do
  # client should have cached ohai assigned to it
  client.determine_node_name
  client.register
  client.build_node
end


Given /^it includes the recipe '(.+)'$/ do |recipe|
  self.recipe = recipe
  client.node.run_list << recipe
  client.save_node
end

Given /^it includes no recipes$/ do 
  self.recipe = "" 
  client.node.run_list.reset!
  client.save_node
end

Given /^it includes the role '(.+)'$/ do |role|
  self.recipe = "role[#{role}]"
  client.node.run_list << "role[#{role}]" 
  client.save_node
end

###
# When
###
When /^the node is converged$/ do
  client.run
end

When /^the node is retrieved from the API$/ do
  self.inflated_response = Chef::Node.load(client.node.name)
end
