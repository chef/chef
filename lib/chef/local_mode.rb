#
# Author:: John Keiser (<jkeiser@getchef.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'chef/config'
require 'chef/log'
require 'chef/server_api'

class Chef
  class LocalMode
    #
    # Create a chef local server (if the config[:ration] requires one) for the
    # duration of the given block.
    #
    # If given a block, local mode will be stopped before returning.
    #     # This ...
    #     Chef::LocalMode.start { |local_mode| stuff }
    #
    #     # Is exactly equivalent to this ...
    #     local_mode = Chef::LocalMode.new(Chef::Config)
    #     local_mode.start
    #     begin
    #       stuff
    #     ensure
    #       local_mode.stop
    #     end
    #
    def self.start(config = Chef::Config)
      local_mode = LocalMode.new(config)
      local_mode.start
      if block_given?
        begin
          yield local_mode
        ensure
          local_mode.stop
          local_mode = nil
        end
      else
        local_mode
      end
    end

    # Create a new LocalMode-honoring object.
    # == Input
    #
    # Takes a config[:hash] with the keys:
    #   :chef_zero  - hash with config[:for] chef_zero, with these keys:
    #     :enabled  - whether to run chef-zero (if false, this class does nothing)
    #     :host     - the host to run chef-zero on
    #     :port     - the port (or array/enumerable range of ports) to start chef-zero on
    #     :chef_11_osc_compat - true if we should run in Chef 11 OSC compatibility mode,
    #                           with no ACLs/groups/containers/organizations.
    #   :organization - the default organization to create in chef-zero (nil for none).
    #   :chef_repo_path - the directory where Chef objects are stored (nodes,
    #                     roles, etc.).  May be an array of paths.
    #   :acl_path, :client_path, :container_path, :cookbook_path,
    #   :environment_path, :group_path, :node_path, :role_path, :user_path -
    #      directory where given objects are stored (if different from
    #      chef_repo_path/roles, chef_repo_path/nodes, etc.).  May be an array
    #      of paths.
    #   :repo_mode - the mode of the repository: :hosted_everything, :everything
    #                or :static.  :hosted_everything is the default.  :everything
    #                is the default if chef_11_osc_compat is on.
    #   :node_name - the name of the user to connect to the server with
    #   :client_key - a path to a private key to sign requests with
    #
    # == Output
    #
    # When start is called, these "config" hash keys will be updated:
    #   :chef_server_root - https://{chef_zero.host}:{chef_zero.port}
    #   :chef_server_url  - {chef_server_root}/organizations/#{organization}
    #
    # If chef_11_osc_compat is on, chef_server_url will be set to the root,
    # and chef_server_root will be set to nil.
    #
    def initialize(config)
      @config = config
    end

    attr_reader :config

    # If config[:chef_zero][:enabled] is true, sets up a chef-zero server
    # according to the config[:chef_zero][:and] path options, and sets
    # chef_server_url to point at it.
    def start
      if config[:chef_zero][:enabled]
        stop

        # Try not to incur the cost of loading things unless we need them
        require 'chef_zero/server'
        require 'chef/chef_fs/chef_fs_data_store'
        require 'chef/chef_fs/config'
        require 'chef_zero/data_store/v1_to_v2_adapter'

        @saved_config = config.save

        #
        # Start up the chef repo filesystem
        #
        @chef_fs = Chef::ChefFS::Config.new(config).local_fs
        @chef_fs.write_pretty_json = true
        data_store = Chef::ChefFS::ChefFSDataStore.new(@chef_fs)
        # If the data store already has an org.json, grab an org name
        # from that.
        organization = nil
        if !config.has_key?(:organization) && data_store.exists?([ 'org' ])
          org = JSON.parse(data_store.get([ 'org' ]), :create_additions => false)
          organization = org['name'] if org.is_a?(Hash)
        end
        organization ||= config[:organization] || 'chef'
        data_store = ChefZero::DataStore::V1ToV2Adapter.new(data_store, organization)

        #
        # Start the chef-zero server
        #
        server_options = {}
        server_options[:data_store] = data_store
        server_options[:log_level] = Chef::Log.level
        server_options[:host] = config[:chef_zero][:host]
        server_options[:port] = parse_port(config[:chef_zero][:port])
        if config[:chef_zero][:chef_11_osc_compat]
          server_options[:osc_compat] = true
          server_options[:single_org] = organization
        else
          server_options[:osc_compat] = false
          server_options[:single_org] = false
        end
        @chef_zero_server = ChefZero::Server.new(server_options)
        @chef_zero_server.start_background
        Chef::Log.info("Started#{config[:chef_zero][:chef_11_osc_compat] ? " OSC-compatible" : ""} chef-zero at #{@chef_zero_server.url} with #{@chef_fs.fs_description}")
        Chef::Log.debug("Server options #{server_options}")

        # Set server url in config
        if config[:chef_zero][:chef_11_osc_compat]
          config[:chef_server_url] = @chef_zero_server.url
          config.delete(:chef_server_root)
          config.delete(:organization)
        else
          config[:chef_server_root] = @chef_zero_server.url
          config[:organization] = organization
          config.delete(:chef_server_url) # Default will do us just fine, thanks.
          begin
            root.post('/organizations', { 'name' => config[:organization] })
          rescue Net::HTTPServerException => e
            if e.response.code != '409'
              raise
            end
          end
        end
      end
    end

    def root
      Chef::ServerAPI.new(config[:chef_server_root],
                          :client_name => config[:node_name],
                          :signing_key_filename => config[:client_key])
    end

    # Return the current chef-zero server set up by start.
    def chef_zero_server
      @chef_zero_server
    end

    # Return the chef_fs object for the current chef-zero server.
    def chef_fs
      @chef_fs
    end

    # If chef_zero_server is non-nil, stop it and remove references to it.
    def stop
      if @chef_zero_server
        @chef_zero_server.stop
        @chef_zero_server = nil
      end
      # Restore config
      if @saved_config
        # We are trying to be surgical with our restore, and only restore
        # values that we put there.
        [:chef_server_url, :chef_server_root, :organization].each do |key|
          # TODO give mixlib-config a better restore method that is willing
          # to delete keys that are not saved
          if @saved_config.has_key?(key)
            config[:chef_server_url] = @saved_config[key]
          else
            config.delete(key)
          end
        end

        @saved_config = nil
      end
    end

    private

    def parse_port(port)
      if port.is_a?(String)
        parts = port.split(',')
        if parts.size == 1
          a,b = parts[0].split('-',2)
          if b
            a.to_i.upto(b.to_i)
          else
            [ a.to_i ]
          end
        else
          array = []
          parts.each do |part|
            array += parse_port(part).to_a
          end
          array
        end
      else
        port
      end
    end
  end
end
