#
# Cookbook Name:: deploy
# Recipe:: embedded_recipe_callbacks
#
# Copyright 2009, Daniel DeLeo
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

file "#{node[:tmpdir]}/deploy/shared/sqlite/production.sqlite3" do
  mode "0664"
end

timestamped_deploy "#{node[:tmpdir]}/deploy" do
  repo "#{node[:tmpdir]}/gitrepo/myapp/"
  environment "RAILS_ENV" => "production"
  revision "HEAD"
  action :deploy
  migration_command "rake db:migrate --trace"
  migrate true

  # Callback awesomeness:
  before_migrate do
    current_release = release_path

    directory "#{current_release}/deploy" do
      mode "0755"
    end

    # creates a callback for before_symlink
    template "#{current_release}/deploy/before_symlink_callback.rb" do
      source "embedded_recipe_before_symlink.rb.erb"
      mode "0644"
    end

  end

  before_symlink "deploy/before_symlink_callback.rb"

  restart do
    current_release = release_path
    file "#{release_path}/tmp/restart.txt" do
      mode "0644"
    end
  end

end
