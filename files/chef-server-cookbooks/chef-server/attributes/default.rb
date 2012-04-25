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
# CouchDB 
####
default['chef_server']['couchdb']['enable'] = true 
default['chef_server']['couchdb']['ha'] = false 
default['chef_server']['couchdb']['dir'] = "/var/opt/chef-server/couchdb"
default['chef_server']['couchdb']['data_dir'] = "/var/opt/chef-server/couchdb/db"
default['chef_server']['couchdb']['log_directory'] = "/var/log/chef-server/couchdb"
default['chef_server']['couchdb']['port'] = 5984
default['chef_server']['couchdb']['bind_address'] = '127.0.0.1'
default['chef_server']['couchdb']['vip'] = "127.0.0.1"
default['chef_server']['couchdb']['max_document_size'] = '4294967296'
default['chef_server']['couchdb']['max_attachment_chunk_size'] = '4294967296'
default['chef_server']['couchdb']['os_process_timeout'] = '300000'
default['chef_server']['couchdb']['max_dbs_open'] = 10000
default['chef_server']['couchdb']['delayed_commits'] = 'true'
default['chef_server']['couchdb']['batch_save_size'] = 1000 
default['chef_server']['couchdb']['batch_save_interval'] = 1000 
default['chef_server']['couchdb']['log_level'] = 'error' 
default['chef_server']['couchdb']['reduce_limit'] = 'false' 

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
# Chef Server API
####
default['chef_server']['chef-server-api']['enable'] = true
default['chef_server']['chef-server-api']['ha'] = false
default['chef_server']['chef-server-api']['dir'] = "/var/opt/chef-server/chef-server-api"
default['chef_server']['chef-server-api']['log_directory'] = "/var/log/chef-server/chef-server-api"
default['chef_server']['chef-server-api']['sandbox_path'] = "/var/opt/chef-server/chef-server-api/sandbox"
default['chef_server']['chef-server-api']['checksum_path'] = "/var/opt/chef-server/chef-server-api/checksum"
default['chef_server']['chef-server-api']['proxy_user'] = "pivotal"
default['chef_server']['chef-server-api']['environment'] = 'privatechef'
default['chef_server']['chef-server-api']['url'] = "http://127.0.0.1:9460" 
default['chef_server']['chef-server-api']['upload_vip'] = "127.0.0.1" 
default['chef_server']['chef-server-api']['upload_port'] = 9460 
default['chef_server']['chef-server-api']['upload_proto'] = "http" 
default['chef_server']['chef-server-api']['upload_internal_vip'] = "127.0.0.1" 
default['chef_server']['chef-server-api']['upload_internal_port'] = 9460 
default['chef_server']['chef-server-api']['upload_internal_proto'] = "http" 
default['chef_server']['chef-server-api']['vip'] = "127.0.0.1" 
default['chef_server']['chef-server-api']['port'] = 9460
default['chef_server']['chef-server-api']['listen'] = '127.0.0.1:9460'
default['chef_server']['chef-server-api']['backlog'] = 1024
default['chef_server']['chef-server-api']['tcp_nodelay'] = true 
default['chef_server']['chef-server-api']['worker_timeout'] = 3600
default['chef_server']['chef-server-api']['validation_client_name'] = "chef-validator"
default['chef_server']['chef-server-api']['umask'] = "0022"
default['chef_server']['chef-server-api']['worker_processes'] = node["cpu"]["total"].to_i
default['chef_server']['chef-server-api']['web_ui_client_name'] = "chef-webui"
default['chef_server']['chef-server-api']['web_ui_admin_user_name'] = "admin"
default['chef_server']['chef-server-api']['web_ui_admin_default_password'] = "p@ssw0rd1"

####
# Chef Server WebUI
####
default['chef_server']['chef-server-webui']['enable'] = true
default['chef_server']['chef-server-webui']['ha'] = false
default['chef_server']['chef-server-webui']['dir'] = "/var/opt/chef-server/chef-server-webui"
default['chef_server']['chef-server-webui']['log_directory'] = "/var/log/chef-server/chef-server-webui"
default['chef_server']['chef-server-webui']['environment'] = 'privatechef'
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

###
# Load Balancer
###
default['chef_server']['lb']['enable'] = true
default['chef_server']['lb']['vip'] = "127.0.0.1"
default['chef_server']['lb']['api_fqdn'] = node['fqdn'] 
default['chef_server']['lb']['web_ui_fqdn'] = node['fqdn'] 
default['chef_server']['lb']['cache_cookbook_files'] = false
default['chef_server']['lb']['debug'] = false
default['chef_server']['lb']['upstream']['chef-server-api'] = [ "127.0.0.1" ]
default['chef_server']['lb']['upstream']['chef-server-webui'] = [ "127.0.0.1" ]

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

