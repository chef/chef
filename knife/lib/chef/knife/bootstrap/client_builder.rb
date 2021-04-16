#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/node" unless defined?(Chef::Node)
require "chef/server_api" unless defined?(Chef::ServerAPI)
require "chef/api_client" unless defined?(Chef::APIClient)
require "chef/api_client/registration" unless defined?(Chef::APIClient::Registration)
require "tmpdir" unless defined?(Dir.mktmpdir)

class Chef
  class Knife
    class Bootstrap < Knife
      class ClientBuilder

        # @return [Hash] knife merged config, typically @config
        attr_accessor :config
        # @return [Hash] chef config object
        attr_accessor :chef_config
        # @return [Chef::Knife::UI] ui object for output
        attr_accessor :ui
        # @return [Chef::ApiClient] client saved on run
        attr_reader :client

        # @param config [Hash] Hash of knife config settings
        # @param chef_config [Hash] Hash of chef config settings
        # @param ui [Chef::Knife::UI] UI object for output
        def initialize(config: {}, knife_config: nil, chef_config: {}, ui: nil)
          @config = config
          unless knife_config.nil?
            @config = knife_config
            Chef.deprecated(:knife_bootstrap_apis, "The knife_config option to the Bootstrap::ClientBuilder object is deprecated and has been renamed to just 'config'")
          end
          @chef_config = chef_config
          @ui = ui
        end

        # Main entry.  Prompt the user to clean up any old client or node objects.  Then create
        # the new client, then create the new node.
        def run
          sanity_check

          ui.info("Creating new client for #{node_name}")

          @client = create_client!

          ui.info("Creating new node for #{node_name}")

          create_node!
        end

        # Tempfile to use to write newly created client credentials to.
        #
        # This method is public so that the knife bootstrapper can read then and pass the value into
        # the handler for chef vault which needs the client cert we create here.
        #
        # We hang onto the tmpdir as an ivar as well so that it will not get GC'd and removed
        #
        # @return [String] path to the generated client.pem
        def client_path
          @client_path ||=
            begin
              @tmpdir = Dir.mktmpdir
              File.join(@tmpdir, "#{node_name}.pem")
            end
        end

        private

        # @return [String] node name from the config
        def node_name
          config[:chef_node_name]
        end

        # @return [String] environment from the config
        def environment
          config[:environment]
        end

        # @return [String] run_list from the config
        def run_list
          config[:run_list]
        end

        # @return [String] policy_name from the config
        def policy_name
          config[:policy_name]
        end

        # @return [String] policy_group from the config
        def policy_group
          config[:policy_group]
        end

        # @return [Hash,Array] Object representation of json first-boot attributes from the config
        def first_boot_attributes
          config[:first_boot_attributes]
        end

        # @return [String] chef server url from the Chef::Config
        def chef_server_url
          chef_config[:chef_server_url]
        end

        # Accesses the run_list and coerces it into an Array, changing nils into
        # the empty Array, and splitting strings representations of run_lists into
        # Arrays.
        #
        # @return [Array] run_list coerced into an array
        def normalized_run_list
          case run_list
          when nil
            []
          when String
            run_list.split(/\s*,\s*/)
          when Array
            run_list
          end
        end

        # Create the client object and save it to the Chef API
        def create_client!
          Chef::ApiClient::Registration.new(node_name, client_path, http_api: rest).run
        end

        # Create the node object (via the lazy accessor) and save it to the Chef API
        def create_node!
          node.save
        end

        # Create a new Chef::Node.  Supports creating the node with its name, run_list, attributes
        # and environment.  This injects a rest object into the Chef::Node which uses the client key
        # for authentication so that the client creates the node and therefore we get the acls setup
        # correctly.
        #
        # @return [Chef::Node] new chef node to create
        def node
          @node ||=
            begin
              node = Chef::Node.new(chef_server_rest: client_rest)
              node.name(node_name)
              node.run_list(normalized_run_list)
              node.normal_attrs = first_boot_attributes if first_boot_attributes
              node.environment(environment) if environment
              node.policy_name = policy_name if policy_name
              node.policy_group = policy_group if policy_group
              (config[:tags] || []).each do |tag|
                node.tags << tag
              end
              node
            end
        end

        # Check for the existence of a node and/or client already on the server.  If the node
        # already exists, we must delete it in order to proceed so that we can create a new node
        # object with the permissions of the new client.  There is a use case for creating a new
        # client and wiring it up to a precreated node object, but we do currently support that.
        #
        # We prompt the user about what to do and will fail hard if we do not get confirmation to
        # delete any prior node/client objects.
        def sanity_check
          if resource_exists?("nodes/#{node_name}")
            ui.confirm("Node #{node_name} exists, overwrite it")
            rest.delete("nodes/#{node_name}")
          end
          if resource_exists?("clients/#{node_name}")
            ui.confirm("Client #{node_name} exists, overwrite it")
            rest.delete("clients/#{node_name}")
          end
        end

        # Check if an relative path exists on the chef server
        #
        # @param relative_path [String] URI path relative to the chef organization
        # @return [Boolean] if the relative path exists or returns a 404
        def resource_exists?(relative_path)
          rest.get(relative_path)
          true
        rescue Net::HTTPClientException => e
          raise unless e.response.code == "404"

          false
        end

        # @return [Chef::ServerAPI] REST client using the client credentials
        def client_rest
          @client_rest ||= Chef::ServerAPI.new(chef_server_url, client_name: node_name, signing_key_filename: client_path)
        end

        # @return [Chef::ServerAPI] REST client using the cli user's knife credentials
        # this uses the users's credentials
        def rest
          @rest ||= Chef::ServerAPI.new(chef_server_url)
        end
      end
    end
  end
end
