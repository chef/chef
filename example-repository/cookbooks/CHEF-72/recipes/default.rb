#
# Cookbook Name:: CHEF-72
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

template "/tmp/chef-72.txt" do
  source "chef-72.txt.erb"
  variables({:sing => "what"})
end

define_template "jail" do
  sing "scarecrow"
end

remote_file "/tmp/chef-72-remote.txt" do
  source "chef-72.txt"
end

define_remote_file "jail" do
  source "chef-72.txt"
end

%w{/tmp/chef-72.txt /tmp/chef-72-jail.txt /tmp/chef-72-remote.txt /tmp/chef-72-remote-jail.txt}.each do |filename|
  execute "cat #{filename}" do
    command "cat #{filename}"
  end
  
  file filename do
    action :delete
  end
end