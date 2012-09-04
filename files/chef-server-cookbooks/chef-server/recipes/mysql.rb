#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

#
# Enable MySQL support by adding the following to '/etc/chef-server/chef-server.rb':
#
#   database_type = 'mysql'
#   postgresql['enable'] = false
#   mysql['enable'] = true
#   mysql['destructive_migrate'] = true
#
# Then run 'chef-server-ctl reconfigure'
#

if node['chef_server']['mysql']['install_libs']
  case node["platform"]
  when "ubuntu"
    package "libmysqlclient-dev"
  when "centos","redhat","scientific"
    package "libmysql-devel"
  end
end

bundles = {
  "chef-expander" => false,
  # "chef-server-webui" => "integration_test dev" # FIXME: uncomment when we are ready to tackle the webui
}

node['chef_server']['mysql']['mysql2_versions'].each do |mysql2_version|
  execute "/opt/chef-server/embedded/bin/gem unpack /opt/chef-server/embedded/service/gem/ruby/1.9.1/cache/mysql2-#{mysql2_version}.gem" do
    cwd "/opt/chef-server/embedded/service/gem/ruby/1.9.1/gems"
    not_if { File.directory?("/opt/chef-server/embedded/service/gem/ruby/1.9.1/gems/mysql2-#{mysql2_version}") }
  end
  mysql2_base = "/opt/chef-server/embedded/service/gem/ruby/1.9.1/gems/mysql2-#{mysql2_version}"
  mysql2_base_safe = mysql2_base.gsub('/', '\/')
  execute "sed -i -e 's/s.files = `git ls-files`/s.files = `find #{mysql2_base_safe} -type f`/' #{mysql2_base}/mysql2.gemspec"
  execute "sed -i -e 's/s.test_files = `git ls-files spec examples`/s.test_files = `find #{mysql2_base_safe}\\/spec examples -type f`/' #{mysql2_base}/mysql2.gemspec"

  execute "compile mysql2 #{mysql2_version}" do
    command "/opt/chef-server/embedded/bin/rake compile"
    cwd mysql2_base
    not_if { File.directory?("#{mysql2_base}/lib/mysql2/mysql2.so") }
  end

  ruby_block "create mysql2 gemspec #{mysql2_version}" do
    block do
      gemspec = Gem::Specification.load("#{mysql2_base}/mysql2.gemspec").to_ruby_for_cache
      File.open("/opt/chef-server/embedded/service/gem/ruby/1.9.1/specifications/mysql2-#{mysql2_version}.gemspec", "w") do |spec_file|
        spec_file.print gemspec
      end
    end
    not_if { File.exists?("/opt/chef-server/embedded/service/gem/ruby/1.9.1/specifications/mysql2-#{mysql2_version}.gemspec") }
  end
end

bundles.each do |name, without_list|
  execute "sed -i -e 's/mysql://g' /opt/chef-server/embedded/service/#{name}/.bundle/config"
  execute "sed -i -e 's/:mysql//g' /opt/chef-server/embedded/service/#{name}/.bundle/config"
  execute "sed -i -e 's/mysql//g' /opt/chef-server/embedded/service/#{name}/.bundle/config"
end

if !File.exists?("/var/opt/chef-server/mysql-bootstrap")
  if node["chef_server"]["mysql"]["destructive_migrate"] && node['chef_server']['bootstrap']['enable']
    execute "migrate_database" do
      command "mysql -h #{node['chef_server']['mysql']['vip']} -u #{node['chef_server']['mysql']['sql_user']} -p#{node['chef_server']['mysql']['sql_password']} opscode_chef < mysql_schema.sql"
      cwd "/opt/chef-server/embedded/service/chef_db/priv"
    end
  end

  file "/var/opt/chef-server/mysql-bootstrap"
end
