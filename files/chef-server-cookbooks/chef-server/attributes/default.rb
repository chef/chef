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

###
# High level options
###
default['chef_server']['notification_email'] = "info@example.com"
default['chef_server']['database_type'] = "postgresql"
default['chef_server']['bootstrap']['enable'] = true

####
# The Chef User that services run as
####
# The username for the chef services user
default['chef_server']['user']['username'] = "chef_server"
# The shell for the chef services user
default['chef_server']['user']['shell'] = "/bin/sh"
# The home directory for the chef services user
default['chef_server']['user']['home'] = "/opt/chef-server/embedded"

####
# RabbitMQ
####
default['chef_server']['rabbitmq']['enable'] = true
default['chef_server']['rabbitmq']['ha'] = false
default['chef_server']['rabbitmq']['dir'] = "/var/opt/chef-server/rabbitmq"
default['chef_server']['rabbitmq']['data_dir'] = "/var/opt/chef-server/rabbitmq/db"
default['chef_server']['rabbitmq']['log_directory'] = "/var/log/chef-server/rabbitmq"
default['chef_server']['rabbitmq']['vhost'] = '/chef'
default['chef_server']['rabbitmq']['user'] = 'chef'
default['chef_server']['rabbitmq']['password'] = 'chefrocks'
default['chef_server']['rabbitmq']['node_ip_address'] = '127.0.0.1'
default['chef_server']['rabbitmq']['node_port'] = '5672'
default['chef_server']['rabbitmq']['nodename'] = 'rabbit@localhost'
default['chef_server']['rabbitmq']['vip'] = '127.0.0.1'
default['chef_server']['rabbitmq']['consumer_id'] = 'hotsauce'

####
# Chef Solr
####
default['chef_server']['chef-solr']['enable'] = true
default['chef_server']['chef-solr']['ha'] = false
default['chef_server']['chef-solr']['dir'] = "/var/opt/chef-server/chef-solr"
default['chef_server']['chef-solr']['data_dir'] = "/var/opt/chef-server/chef-solr/data"
default['chef_server']['chef-solr']['log_directory'] = "/var/log/chef-server/chef-solr"

# node[:memory][:total] =~ /^(\d+)kB/
# memory_total_in_kb = $1.to_i
# solr_mem = (memory_total_in_kb - 600000) / 1024
# # cap solr memory at 6G
# if solr_mem > 6144
#   solr_mem = 6144
# end
default['chef_server']['chef-solr']['heap_size'] = "256M"
default['chef_server']['chef-solr']['java_opts'] = ""
default['chef_server']['chef-solr']['url'] = "http://localhost:8983"
default['chef_server']['chef-solr']['ip_address'] = '127.0.0.1'
default['chef_server']['chef-solr']['vip'] = '127.0.0.1'
default['chef_server']['chef-solr']['port'] = 8983
default['chef_server']['chef-solr']['ram_buffer_size'] = 200
default['chef_server']['chef-solr']['merge_factor'] = 100
default['chef_server']['chef-solr']['max_merge_docs'] = 2147483647
default['chef_server']['chef-solr']['max_field_length'] = 100000
default['chef_server']['chef-solr']['max_commit_docs'] = 1000
default['chef_server']['chef-solr']['commit_interval'] = 60000 # in ms
default['chef_server']['chef-solr']['poll_seconds'] = 20 # slave -> master poll interval in seconds, max of 60 (see solrconfig.xml.erb)

####
# Chef Expander
####
default['chef_server']['chef-expander']['enable'] = true
default['chef_server']['chef-expander']['ha'] = false
default['chef_server']['chef-expander']['dir'] = "/var/opt/chef-server/chef-expander"
default['chef_server']['chef-expander']['log_directory'] = "/var/log/chef-server/chef-expander"
default['chef_server']['chef-expander']['reindexer_log_directory'] = "/var/log/chef-server/chef-expander-reindexer"
default['chef_server']['chef-expander']['consumer_id'] = "default"
default['chef_server']['chef-expander']['nodes'] = 2

####
# Bookshelf
####
default['chef_server']['bookshelf']['enable'] = true
default['chef_server']['bookshelf']['ha'] = false
default['chef_server']['bookshelf']['dir'] = "/var/opt/chef-server/bookshelf"
default['chef_server']['bookshelf']['data_dir'] = "/var/opt/chef-server/bookshelf/data"
default['chef_server']['bookshelf']['log_directory'] = "/var/log/chef-server/bookshelf"
default['chef_server']['bookshelf']['svlogd_size'] = 1000000
default['chef_server']['bookshelf']['svlogd_num'] = 10
default['chef_server']['bookshelf']['vip'] = '127.0.0.1'
default['chef_server']['bookshelf']['listen'] = '127.0.0.1'
default['chef_server']['bookshelf']['port'] = 4321
default['chef_server']['bookshelf']['stream_download'] = true
default['chef_server']['bookshelf']['access_key_id'] = "generated-by-default"
default['chef_server']['bookshelf']['secret_access_key'] = "generated-by-default"

####
# Erlang Chef Server API
####
default['chef_server']['erchef']['enable'] = true
default['chef_server']['erchef']['enable'] = true
default['chef_server']['erchef']['ha'] = false
default['chef_server']['erchef']['dir'] = "/var/opt/chef-server/erchef"
default['chef_server']['erchef']['log_directory'] = "/var/log/chef-server/erchef"
default['chef_server']['erchef']['svlogd_size'] = 1000000
default['chef_server']['erchef']['svlogd_num'] = 10
default['chef_server']['erchef']['vip'] = '127.0.0.1'
default['chef_server']['erchef']['listen'] = '127.0.0.1'
default['chef_server']['erchef']['port'] = 8000
default['chef_server']['erchef']['auth_skew'] = '900'
default['chef_server']['erchef']['bulk_fetch_batch_size'] = '5'
default['chef_server']['erchef']['max_cache_size'] = '10000'
default['chef_server']['erchef']['cache_ttl'] = '3600'
default['chef_server']['erchef']['db_pool_size'] = '20'
default['chef_server']['erchef']['couchdb_max_conn'] = '100'
default['chef_server']['erchef']['ibrowse_max_sessions'] = 256
default['chef_server']['erchef']['ibrowse_max_pipeline_size'] = 1
default['chef_server']['erchef']['s3_bucket'] = 'bookshelf'
default['chef_server']['erchef']['proxy_user'] = "pivotal"
default['chef_server']['erchef']['url'] = "http://127.0.0.1:8000"
default['chef_server']['erchef']['validation_client_name'] = "chef-validator"
default['chef_server']['erchef']['umask'] = "0022"
default['chef_server']['erchef']['web_ui_client_name'] = "chef-webui"

####
# Chef Server WebUI
####
default['chef_server']['chef-server-webui']['enable'] = true
default['chef_server']['chef-server-webui']['ha'] = false
default['chef_server']['chef-server-webui']['dir'] = "/var/opt/chef-server/chef-server-webui"
default['chef_server']['chef-server-webui']['log_directory'] = "/var/log/chef-server/chef-server-webui"
default['chef_server']['chef-server-webui']['environment'] = 'chefserver'
default['chef_server']['chef-server-webui']['url'] = "http://127.0.0.1:9462"
default['chef_server']['chef-server-webui']['listen'] = '127.0.0.1:9462'
default['chef_server']['chef-server-webui']['vip'] = '127.0.0.1'
default['chef_server']['chef-server-webui']['port'] = 9462
default['chef_server']['chef-server-webui']['backlog'] = 1024
default['chef_server']['chef-server-webui']['tcp_nodelay'] = true
default['chef_server']['chef-server-webui']['worker_timeout'] = 3600
default['chef_server']['chef-server-webui']['validation_client_name'] = "chef"
default['chef_server']['chef-server-webui']['umask'] = "0022"
default['chef_server']['chef-server-webui']['worker_processes'] = 2
default['chef_server']['chef-server-webui']['session_key'] = "_sandbox_session"
default['chef_server']['chef-server-webui']['cookie_domain'] = "all"
default['chef_server']['chef-server-webui']['cookie_secret'] = "47b3b8d95dea455baf32155e95d1e64e"
default['chef_server']['chef-server-webui']['web_ui_client_name'] = "chef-webui"
default['chef_server']['chef-server-webui']['web_ui_admin_user_name'] = "admin"
default['chef_server']['chef-server-webui']['web_ui_admin_default_password'] = "p@ssw0rd1"

####
# Chef Pedant
####
default['chef_server']['chef-pedant']['dir'] = "/var/opt/chef-server/chef-pedant"
default['chef_server']['chef-pedant']['log_directory'] = "/var/log/chef-server/chef-pedant"
default['chef_server']['chef-pedant']['log_http_requests'] = true

###
# Load Balancer
###
default['chef_server']['lb']['enable'] = true
default['chef_server']['lb']['vip'] = "127.0.0.1"
default['chef_server']['lb']['api_fqdn'] = node['fqdn']
default['chef_server']['lb']['web_ui_fqdn'] = node['fqdn']
default['chef_server']['lb']['cache_cookbook_files'] = false
default['chef_server']['lb']['debug'] = false
default['chef_server']['lb']['upstream']['erchef'] = [ "127.0.0.1" ]
default['chef_server']['lb']['upstream']['chef-server-webui'] = [ "127.0.0.1" ]
default['chef_server']['lb']['upstream']['bookshelf'] = [ "127.0.0.1" ]

####
# Nginx
####
default['chef_server']['nginx']['enable'] = true
default['chef_server']['nginx']['ha'] = false
default['chef_server']['nginx']['dir'] = "/var/opt/chef-server/nginx"
default['chef_server']['nginx']['log_directory'] = "/var/log/chef-server/nginx"
default['chef_server']['nginx']['ssl_port'] = 443
default['chef_server']['nginx']['enable_non_ssl'] = false
default['chef_server']['nginx']['non_ssl_port'] = 80
default['chef_server']['nginx']['server_name'] = node['fqdn']
default['chef_server']['nginx']['url'] = "https://#{node['fqdn']}"
# These options provide the current best security with TSLv1
#default['chef_server']['nginx']['ssl_protocols'] = "-ALL +TLSv1"
#default['chef_server']['nginx']['ssl_ciphers'] = "RC4:!MD5"
# This might be necessary for auditors that want no MEDIUM security ciphers and don't understand BEAST attacks
#default['chef_server']['nginx']['ssl_protocols'] = "-ALL +SSLv3 +TLSv1"
#default['chef_server']['nginx']['ssl_ciphers'] = "HIGH:!MEDIUM:!LOW:!ADH:!kEDH:!aNULL:!eNULL:!EXP:!SSLv2:!SEED:!CAMELLIA:!PSK"
# The following favors performance and compatibility, addresses BEAST, and should pass a PCI audit
default['chef_server']['nginx']['ssl_protocols'] = "SSLv3 TLSv1"
default['chef_server']['nginx']['ssl_ciphers'] = "RC4-SHA:RC4-MD5:RC4:RSA:HIGH:MEDIUM:!LOW:!kEDH:!aNULL:!ADH:!eNULL:!EXP:!SSLv2:!SEED:!CAMELLIA:!PSK"
default['chef_server']['nginx']['ssl_certificate'] = nil
default['chef_server']['nginx']['ssl_certificate_key'] = nil
default['chef_server']['nginx']['ssl_country_name'] = "US"
default['chef_server']['nginx']['ssl_state_name'] = "WA"
default['chef_server']['nginx']['ssl_locality_name'] = "Seattle"
default['chef_server']['nginx']['ssl_company_name'] = "YouCorp"
default['chef_server']['nginx']['ssl_organizational_unit_name'] = "Operations"
default['chef_server']['nginx']['ssl_email_address'] = "you@example.com"
default['chef_server']['nginx']['worker_processes'] = node['cpu']['total'].to_i
default['chef_server']['nginx']['worker_connections'] = 10240
default['chef_server']['nginx']['sendfile'] = 'on'
default['chef_server']['nginx']['tcp_nopush'] = 'on'
default['chef_server']['nginx']['tcp_nodelay'] = 'on'
default['chef_server']['nginx']['gzip'] = "on"
default['chef_server']['nginx']['gzip_http_version'] = "1.0"
default['chef_server']['nginx']['gzip_comp_level'] = "2"
default['chef_server']['nginx']['gzip_proxied'] = "any"
default['chef_server']['nginx']['gzip_types'] = [ "text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json" ]
default['chef_server']['nginx']['keepalive_timeout'] = 65
default['chef_server']['nginx']['client_max_body_size'] = '250m'
default['chef_server']['nginx']['cache_max_size'] = '5000m'

###
# MySQL
###
default['chef_server']['mysql']['enable'] = false
default['chef_server']['mysql']['sql_user'] = "opscode_chef"
default['chef_server']['mysql']['sql_password'] = "snakepliskin"
default['chef_server']['mysql']['vip'] = "127.0.0.1"
default['chef_server']['mysql']['destructive_migrate'] = false
default['chef_server']['mysql']['install_libs'] = true
default['chef_server']['mysql']['mysql2_versions'] = IO.readlines("/opt/chef-server/version-manifest.txt").detect { |l| l =~ /^mysql2/ }.gsub(/^mysql2:\s+(\d.+)$/, '\1').chomp.split("-")

###
# PostgreSQL
###
default['chef_server']['postgresql']['enable'] = true
default['chef_server']['postgresql']['ha'] = false
default['chef_server']['postgresql']['dir'] = "/var/opt/chef-server/postgresql"
default['chef_server']['postgresql']['data_dir'] = "/var/opt/chef-server/postgresql/data"
default['chef_server']['postgresql']['log_directory'] = "/var/log/chef-server/postgresql"
default['chef_server']['postgresql']['svlogd_size'] = 1000000
default['chef_server']['postgresql']['svlogd_num'] = 10
default['chef_server']['postgresql']['username'] = "opscode-pgsql"
default['chef_server']['postgresql']['shell'] = "/bin/sh"
default['chef_server']['postgresql']['home'] = "/opt/chef-server/embedded"
default['chef_server']['postgresql']['sql_user'] = "opscode_chef"
default['chef_server']['postgresql']['sql_password'] = "snakepliskin"
default['chef_server']['postgresql']['sql_ro_user'] = "opscode_chef_ro"
default['chef_server']['postgresql']['sql_ro_password'] = "shmunzeltazzen"
default['chef_server']['postgresql']['vip'] = "127.0.0.1"
default['chef_server']['postgresql']['port'] = 5432
default['chef_server']['postgresql']['listen_address'] = 'localhost'
default['chef_server']['postgresql']['max_connections'] = 200
default['chef_server']['postgresql']['md5_auth_cidr_addresses'] = [ ]
default['chef_server']['postgresql']['trust_auth_cidr_addresses'] = [ '127.0.0.1/32', '::1/128' ]
default['chef_server']['postgresql']['shmmax'] = kernel['machine'] =~ /x86_64/ ? 17179869184 : 4294967295
default['chef_server']['postgresql']['shmall'] = kernel['machine'] =~ /x86_64/ ? 4194304 : 1048575
