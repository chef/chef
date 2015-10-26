#
# Cookbook Name:: build-cookbook
# Recipe:: unit
#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

path = node['delivery']['workspace']['repo']
cache = node['delivery']['workspace']['cache']
# dbuild readable folder that is persistent between build runs that we created in the default recipe
gem_cache = File.join(node['delivery']['workspace']['root'], "../../../project_gem_cache")

ruby_execute 'bundle install' do
  version node['chef-delivery']['ruby-2-2-version']
  prefix '/opt/rubies'
  cwd path
  gem_home gem_cache
end


ruby_execute 'bundle exec rspec spec/unit' do
  version node['chef-delivery']['ruby-2-2-version']
  prefix '/opt/rubies'
  cwd path
  gem_home gem_cache
end
