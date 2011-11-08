#
# Cookbook Name:: files
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

file "#{node[:tmpdir]}/octal0111.txt" do
  owner 'nobody'
  mode 0111
  action :create
end

file "#{node[:tmpdir]}/octal0644.txt" do
  owner 'nobody'
  mode 0644
  action :create
end

file "#{node[:tmpdir]}/octal2644.txt" do
  owner 'nobody'
  mode 02644
  action :create
end

file "#{node[:tmpdir]}/decimal73.txt" do
  owner 'nobody'
  mode 73
  action :create
end

file "#{node[:tmpdir]}/decimal644.txt" do
  owner 'nobody'
  mode 644
  action :create
end

file "#{node[:tmpdir]}/decimal2644.txt" do
  owner 'nobody'
  mode 2644
  action :create
end

file "#{node[:tmpdir]}/string111.txt" do
  owner 'nobody'
  mode "111"
  action :create
end

file "#{node[:tmpdir]}/string644.txt" do
  owner 'nobody'
  mode "644"
  action :create
end

file "#{node[:tmpdir]}/string0644.txt" do
  owner 'nobody'
  mode "0644"
  action :create
end

file "#{node[:tmpdir]}/string2644.txt" do
  owner 'nobody'
  mode "2644"
  action :create
end

