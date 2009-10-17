#
# Cookbook Name:: deploy
# Recipe:: rollback
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

%w{ log tmp/pids public/system config sqlite}.each do |dir|
  directory "#{node[:tmpdir]}/deploy/shared/#{dir}" do
    recursive true
    mode "0775"
  end
end

# Use a template instead in real life
file "#{node[:tmpdir]}/deploy/shared/config/database.yml" do
  mode "0664"
end

file "#{node[:tmpdir]}/deploy/shared/sqlite/production.sqlite3" do
  mode "0664"
end

deploy "#{node[:tmpdir]}/deploy" do
  repo "file:///#{File.dirname(__FILE__) + "/../../../../../../../"}"
  revision "HEAD"
  action :deploy
  restart_command "touch tmp/restart.txt"
end

deploy "#{node[:tmpdir]}/deploy" do
  repo "file:///#{File.dirname(__FILE__) + "/../../../../../../../"}"
  revision "HEAD"
  action :deploy
  restart_command "touch tmp/restart.txt"
end

deploy "#{node[:tmpdir]}/deploy" do
  repo "file:///#{File.dirname(__FILE__) + "/../../../../../../../"}"
  revision "HEAD"
  action :rollback
  restart_command "touch tmp/restart.txt"
end

