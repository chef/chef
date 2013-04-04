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

nginx_dir = node['chef_server']['nginx']['dir']
nginx_etc_dir = File.join(nginx_dir, "etc")
nginx_cache_dir = File.join(nginx_dir, "cache")
nginx_cache_tmp_dir = File.join(nginx_dir, "cache-tmp")
nginx_html_dir = File.join(nginx_dir, "html")
nginx_ca_dir = File.join(nginx_dir, "ca")
nginx_log_dir = node['chef_server']['nginx']['log_directory']

[
  nginx_dir,
  nginx_etc_dir,
  nginx_cache_dir,
  nginx_cache_tmp_dir,
  nginx_html_dir,
  nginx_ca_dir,
  nginx_log_dir,
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username']
    mode '0700'
    recursive true
  end
end

ssl_keyfile = File.join(nginx_ca_dir, "#{node['chef_server']['nginx']['server_name']}.key")
ssl_crtfile = File.join(nginx_ca_dir, "#{node['chef_server']['nginx']['server_name']}.crt")
ssl_signing_conf = File.join(nginx_ca_dir, "#{node['chef_server']['nginx']['server_name']}-ssl.conf")

unless File.exists?(ssl_keyfile) && File.exists?(ssl_crtfile) && File.exists?(ssl_signing_conf)
  file ssl_keyfile do
    owner "root"
    group "root"
    mode "0644"
    content `/opt/chef-server/embedded/bin/openssl genrsa 2048`
    not_if { File.exists?(ssl_keyfile) }
  end

  file ssl_signing_conf do
    owner "root"
    group "root"
    mode "0644"
    not_if { File.exists?(ssl_signing_conf) }
    content <<-EOH
  [ req ]
  distinguished_name = req_distinguished_name
  prompt = no

  [ req_distinguished_name ]
  C                      = #{node['chef_server']['nginx']['ssl_country_name']}
  ST                     = #{node['chef_server']['nginx']['ssl_state_name']}
  L                      = #{node['chef_server']['nginx']['ssl_locality_name']}
  O                      = #{node['chef_server']['nginx']['ssl_company_name']}
  OU                     = #{node['chef_server']['nginx']['ssl_organizational_unit_name']}
  CN                     = #{node['chef_server']['nginx']['server_name']}
  emailAddress           = #{node['chef_server']['nginx']['ssl_email_address']}
  EOH
  end

  ruby_block "create crtfile" do
    block do
      r = Chef::Resource::File.new(ssl_crtfile, run_context)
      r.owner "root"
      r.group "root"
      r.mode "0644"
      r.content `/opt/chef-server/embedded/bin/openssl req -config '#{ssl_signing_conf}' -new -x509 -nodes -sha1 -days 3650 -key #{ssl_keyfile}`
      r.not_if { File.exists?(ssl_crtfile) }
      r.run_action(:create)
    end
  end
end

node.default['chef_server']['nginx']['ssl_certificate'] ||= ssl_crtfile
node.default['chef_server']['nginx']['ssl_certificate_key'] ||= ssl_keyfile

remote_directory nginx_html_dir do
  source "html"
  files_backup false
  files_owner "root"
  files_group "root"
  files_mode "0644"
  owner node['chef_server']['user']['username']
  mode "0700"
end

nginx_config = File.join(nginx_etc_dir, "nginx.conf")
nginx_vars = node['chef_server']['nginx'].to_hash.merge({
  :chef_https_config => File.join(nginx_etc_dir, "chef_https_lb.conf"),
  :chef_http_config => File.join(nginx_etc_dir, "chef_http_lb.conf")
})

# We will always render an HTTP and HTTPS config for the Chef API but the HTTP
# config file will only be active if the user set `nginx['enable_non_ssl']` to
# true. Default behavior is to redirect all HTTP requests to HTTPS.
["https", "http"].each do |server_proto|
  config_key = "chef_#{server_proto}_config".to_sym
  lb_config = nginx_vars[config_key]

  server_port = (server_proto == 'https') ?
                 nginx_vars['ssl_port'] :
                 nginx_vars['non_ssl_port']

  template lb_config do
    source "nginx_chef_api_lb.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(nginx_vars.merge({
      :server_proto => server_proto,
      :server_port => server_port
    }))
    notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
  end

end

template nginx_config do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables nginx_vars
  notifies :restart, 'service[nginx]' if OmnibusHelper.should_notify?("nginx")
end

runit_service "nginx" do
  down node['chef_server']['nginx']['ha']
  options({
    :log_directory => nginx_log_dir
  }.merge(params))
end

if node['chef_server']['nginx']['bootstrap']
	execute "/opt/chef-server/bin/chef-server-ctl start nginx" do
		retries 20
	end
end

