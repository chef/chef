#
# Cookbook Name:: deploy
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

%w{ log pids system config sqlite}.each do |dir|
  directory "#{node[:tmpdir]}/deploy/shared/#{dir}" do
    recursive true
    mode "0775"
  end
end


template "#{node[:tmpdir]}/deploy/shared/config/database.yml" do
  source "database.yml.erb"
  mode "0664"
end

template "#{node[:tmpdir]}/deploy/shared/config/app_config.yml" do
  source "app_config.yml.erb"
  mode "0664"
end

file "#{node[:tmpdir]}/deploy/shared/sqlite/production.sqlite3" do
  mode "0664"
end

deploy "#{node[:tmpdir]}/deploy" do
  repo "#{node[:tmpdir]}/gitrepo/myapp/"
  environment "RAILS_ENV" => "production"
  revision "HEAD"
  action :deploy
  migration_command "rake db:migrate --trace"
  migrate true
  restart_command "touch tmp/restart.txt"
end

