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

solr_dir = node['chef_server']['chef-solr']['dir']
solr_etc_dir = File.join(solr_dir, "etc")
solr_jetty_dir = File.join(solr_dir, "jetty")
solr_data_dir = node['chef_server']['chef-solr']['data_dir']
solr_data_dir_symlink = File.join(solr_dir, "data")
solr_home_dir = File.join(solr_dir, "home")
solr_log_dir = node['chef_server']['chef-solr']['log_directory']

[ solr_dir, solr_etc_dir, solr_data_dir, solr_home_dir, solr_jetty_dir, solr_log_dir ].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

link solr_data_dir_symlink do
  to solr_data_dir
  not_if { solr_data_dir == solr_data_dir_symlink }
end

solr_config = File.join(solr_etc_dir, "solr.rb")

template File.join(solr_etc_dir, "solr.rb") do
  source "solr.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['chef_server']['chef-solr'].to_hash)
end

should_notify = OmnibusHelper.should_notify?("chef-solr")

solr_installed_file = File.join(solr_dir, "installed")

execute "cp -R /opt/chef-server/embedded/service/chef-solr/home/conf #{File.join(solr_home_dir, 'conf')}" do
  not_if { File.exists?(solr_installed_file) }
  notifies(:restart, "service[chef-solr]") if should_notify
end

execute "cp -R /opt/chef-server/embedded/service/chef-solr/jetty #{File.dirname(solr_jetty_dir)}" do
  not_if { File.exists?(solr_installed_file) }
  notifies(:restart, "service[chef-solr]") if should_notify
end

execute "chown -R #{node['chef_server']['user']['username']} #{solr_dir}" do
  not_if { File.exists?(solr_installed_file) }
end

file solr_installed_file do
  owner "root"
  group "root"
  mode "0644"
  content "Delete me to force re-install solr - dangerous"
  action :create
end

template File.join(solr_jetty_dir, "etc", "jetty.xml") do
  owner node['chef_server']['user']['username']
  mode "0644"
  source "jetty.xml.erb"
  variables(node['chef_server']['chef-solr'].to_hash)
  notifies :restart, 'service[chef-solr]' if should_notify
end

template File.join(solr_home_dir, "conf", "solrconfig.xml") do
  owner node['chef_server']['user']['username']
  mode "0644"
  source "solrconfig.xml.erb"
  variables(node['chef_server']['chef-solr'].to_hash)
  notifies :restart, 'service[chef-solr]' if should_notify
end

# Compute some sane JVM tunings. The user can still override these computed
# defaults using /etc/chef-server/chef-server.rb
solr_mem = if node['chef_server']['chef-solr']['heap_size']
              node['chef_server']['chef-solr']['heap_size']
           else
             node[:memory][:total] =~ /^(\d+)kB/
             memory_total_in_kb = $1.to_i
             solr_mem = (memory_total_in_kb - 600000) / 1024
             # cap default solr memory at 6G
             if solr_mem > 6144
               solr_mem = 6144
             end
             solr_mem
           end
new_size = node['chef_server']['chef-solr']['new_size'] || (solr_mem / 10)

java_opts = node['chef_server']['chef-solr']['java_opts']
java_opts << " -XX:NewSize=#{new_size}M" unless java_opts =~ /NewSize/
java_opts << " -XX:+UseConcMarkSweepGC" unless java_opts =~ /UseConcMarkSweepGC/
java_opts << " -XX:+UseParNewGC" unless java_opts =~ /UseParNewGC/

# Save the values back onto the node attributes
node.default['chef_server']['chef-solr']['heap_size'] = solr_mem
node.default['chef_server']['chef-solr']['new_size'] = new_size

node.default['chef_server']['chef-solr']['command'] =  "java -Xmx#{solr_mem}M -Xms#{solr_mem}M"
node.default['chef_server']['chef-solr']['command'] << "#{java_opts}"
node.default['chef_server']['chef-solr']['command'] << " -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8086 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
node.default['chef_server']['chef-solr']['command'] << " -Dsolr.data.dir=#{solr_data_dir}"
node.default['chef_server']['chef-solr']['command'] << " -Dsolr.solr.home=#{solr_home_dir}"
node.default['chef_server']['chef-solr']['command'] << " -server"
node.default['chef_server']['chef-solr']['command'] << " -jar '#{solr_jetty_dir}/start.jar'"

runit_service "chef-solr" do
  down node['chef_server']['chef-solr']['ha']
  options({
    :log_directory => solr_log_dir
  }.merge(params))
end

if node['chef_server']['bootstrap']['enable']
	execute "/opt/chef-server/bin/chef-server-ctl start chef-solr" do
		retries 20
	end
end

