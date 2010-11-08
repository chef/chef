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
 
%w{ log pids system config sqlite deploy}.each do |dir|
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
 
template "#{node[:tmpdir]}/deploy/shared/deploy/before_migrate.rb" do
  source "sneaky_before_migrate_hook.rb.erb"
  mode "0644"
end
 
template "#{node[:tmpdir]}/deploy/shared/deploy/before_symlink.rb" do
  source "sneaky_before_symlink_hook.rb.erb"
  mode "0644"
end
 
template "#{node[:tmpdir]}/deploy/shared/deploy/before_restart.rb" do
  source "sneaky_before_restart_hook.rb.erb"
  mode "0644"
end
 
template "#{node[:tmpdir]}/deploy/shared/deploy/after_restart.rb" do
  source "sneaky_after_restart_hook.rb.erb"
  mode "0644"
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
  create_dirs_before_symlink  %w{tmp public config deploy}
  symlink_before_migrate  "config/database.yml" => "config/database.yml"
                        
  symlinks  "system" => "public/system", "pids" => "tmp/pids", "log" => "log",
            "deploy/before_migrate.rb" => "deploy/before_migrate.rb",
            "deploy/before_symlink.rb" => "deploy/before_symlink.rb",
            "deploy/before_restart.rb" => "deploy/before_restart.rb",
            "deploy/after_restart.rb" => "deploy/after_restart.rb"
end
