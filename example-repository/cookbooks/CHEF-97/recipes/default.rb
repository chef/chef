#
# Cookbook Name:: CHEF-97
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

# Should not execute
execute "echo onlyif" do
  only_if "test -d /tmp/CHEF-97"
end

directory "/tmp/CHEF-97"

# Should execute
execute "echo onlyif"

# Should not execute
execute "echo notif" do
  not_if "test -d /tmp/CHEF-97"
end

directory "/tmp/CHEF-97" do
  action :delete
end

# Should execute
execute "echo notif"

