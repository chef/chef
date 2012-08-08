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

require 'mixlib/config'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/mixin/deep_merge'
require 'securerandom'

module ChefServer
  extend(Mixlib::Config)

  rabbitmq Mash.new
  chef_solr Mash.new
  chef_expander Mash.new
  erchef Mash.new
  chef_server_webui Mash.new
  lb Mash.new
  postgresql Mash.new
  bookshelf Mash.new
  bootstrap Mash.new
  nginx Mash.new
  api_fqdn nil
  node nil
  notification_email nil

  class << self

    def server(name=nil, opts={})
      if name
        ChefServer["servers"] ||= Mash.new
        ChefServer["servers"][name] = Mash.new(opts)
      end
      ChefServer["servers"]
    end

    def servers
      ChefServer["servers"]
    end

    def backend_vip(name=nil, opts={})
      if name
        ChefServer['backend_vips'] ||= Mash.new
        ChefServer['backend_vips']["fqdn"] = name
        opts.each do |k,v|
          ChefServer['backend_vips'][k] = v
        end
      end
      ChefServer['backend_vips']
    end

    # guards against creating secrets on non-bootstrap node
    def generate_hex(chars)
      SecureRandom.hex(chars)
    end

    def generate_secrets(node_name)
      existing_secrets ||= Hash.new
      if File.exists?("/etc/chef-server/chef-server-secrets.json")
        existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/chef-server/chef-server-secrets.json"))
      end
      existing_secrets.each do |k, v|
        v.each do |pk, p|
          ChefServer[k][pk] = p
        end
      end

      ChefServer['rabbitmq']['password'] ||= generate_hex(50)
      ChefServer['chef_server_webui']['cookie_secret'] ||= generate_hex(50)
      ChefServer['postgresql']['sql_password'] ||= generate_hex(50)
      ChefServer['postgresql']['sql_ro_password'] ||= generate_hex(50)
      ChefServer['bookshelf']['access_key_id'] ||= generate_hex(20)
      ChefServer['bookshelf']['secret_access_key'] ||= generate_hex(40)

      if File.directory?("/etc/chef-server")
        File.open("/etc/chef-server/chef-server-secrets.json", "w") do |f|
          f.puts(
            Chef::JSONCompat.to_json_pretty({
              'rabbitmq' => {
                'password' => ChefServer['rabbitmq']['password'],
              },
              'chef_server_webui' => {
                'cookie_secret' => ChefServer['chef_server_webui']['cookie_secret'],
              },
              'postgresql' => {
                'sql_password' => ChefServer['postgresql']['sql_password'],
                'sql_ro_password' => ChefServer['postgresql']['sql_ro_password']
              },
              'bookshelf' => {
                'access_key_id' => ChefServer['bookshelf']['access_key_id'],
                'secret_access_key' => ChefServer['bookshelf']['secret_access_key']
              }
            })
          )
          system("chmod 0600 /etc/chef-server/chef-server-secrets.json")
        end
      end
    end

    def generate_hash
      results = { "chef_server" => {} }
      [
        "rabbitmq",
        "chef_solr",
        "chef_expander",
        "erchef",
        "chef_server_webui",
        "lb",
        "postgresql",
        "nginx",
        "bookshelf",
        "bootstrap"
      ].each do |key|
        rkey = key.gsub('_', '-')
        results['chef_server'][rkey] = ChefServer[key]
      end
      results['chef_server']['notification_email'] = ChefServer['notification_email']

      results
    end

    def gen_api_fqdn
      ChefServer["lb"]["api_fqdn"] ||= ChefServer['api_fqdn']
      ChefServer["lb"]["web_ui_fqdn"] ||= ChefServer['api_fqdn']
      ChefServer["nginx"]["server_name"] ||= ChefServer['api_fqdn']
      ChefServer["nginx"]["url"] ||= "https://#{ChefServer['api_fqdn']}"
    end

    def generate_config(node_name)
      generate_secrets(node_name)
      ChefServer[:api_fqdn] ||= node_name
      gen_api_fqdn
      generate_hash
    end
  end
end
