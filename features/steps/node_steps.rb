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
  client.register(ohai[:fqdn], :client_key => client_key )
  client.build_node
  client.node.run_list << "integration_setup"
end

Given /^a validated node in the '(\w+)' environment$/ do |env|
  # client should have cached ohai assigned to it
  client.register
  client.build_node
  client.node.chef_environment(env)
  client.node.run_list << "integration_setup"
end

Given /^a validated node with an empty runlist$/ do
  # client should have cached ohai assigned to it
  client.register
  client.build_node
end


Given /^it includes the recipe '([^\']+)'$/ do |recipe|
  self.recipe = recipe
  client.node.run_list << recipe
  client.node.save
end

Given /^it includes the recipe '([^\']+)' at version '([^\']+)'$/ do |recipe, version|
  self.recipe = "recipe[#{recipe},#{version}]"
  client.node.run_list << "recipe[#{recipe}@#{version}]"
  client.node.save
end

Given /^it includes no recipes$/ do
  self.recipe = ""
  client.node.run_list.reset!
  client.node.save
end

Given /^it includes the role '([^\']+)'$/ do |role|
  self.recipe = "role[#{role}]"
  client.node.run_list << "role[#{role}]"
  client.node.save
end

###
# When
###
When /^I remove '([^']*)' from the node's run list$/ do |run_list_item|
  client.node.run_list.remove(run_list_item)
  client.node.save
end

When /^I add '([^']*)' to the node's run list$/ do |run_list_item|
  client.node.run_list << run_list_item
  client.node.save
end


When /^the node is converged$/ do
  client.run
end

When /^the node is retrieved from the API$/ do
  self.inflated_response = Chef::Node.load(client.node.name)
end
