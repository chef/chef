#
# Cookbook Name:: CHEF-89
# Recipe:: default
#
# Copyright 2009, Opscode
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

remote_file "/tmp/seattle.txt" do
  source "seattle.txt"
  action :create
end

remote_file "/tmp/chef-wiki-homepage.txt" do
  source "http://wiki.opscode.com/display/chef/Home"
  action :create
end
