require 'tempfile'
require 'chef_zero/server'
require 'chef_zero/rest_request'

# This is a copy of chef_zero/rspec, modified to implement contextual
# helpers as instance_methods rather than class methods. This makes it
# possible to use them with let bindings and other RSpec code reuse
# mechanisms.
#
# Unfortunately, at the time of this writing, chef-zero master doesn't
# work for our rspec tests, so in the interests of making forward
# progress, we're using a modified version of the chef_zero/rspec code
# here.
#
# This file should be entirely replaced by chef_zero/rspec once these
# issues are fixed.
module ChefZeroSupport
  module Server

    def self.server
      @server
    end
    def self.server=(value)
      @server = value
    end
    def self.client_key
      @client_key
    end
    def self.client_key=(value)
      @client_key = value
    end
    def self.request_log
      @request_log ||= []
    end
    def self.clear_request_log
      @request_log = []
    end

  end

  def client(name, client)
    ChefZeroSupport::Server.server.load_data({ 'clients' => { name => client }})
  end

  def cookbook(name, version, cookbook = {}, options = {})

    auto_metadata = "name '#{name}'; version '#{version}'"

    cookbook["metadata.rb"] ||= auto_metadata

    ChefZeroSupport::Server.server.load_data({ 'cookbooks' => { "#{name}-#{version}" => cookbook.merge(options) }})
  end

  def data_bag(name, data_bag)
    ChefZeroSupport::Server.server.load_data({ 'data' => { name => data_bag }})
  end

  def environment(name, environment)
    ChefZeroSupport::Server.server.load_data({ 'environments' => { name => environment }})
  end

  def node(name, node)
    ChefZeroSupport::Server.server.load_data({ 'nodes' => { name => node }})
  end

  def role(name, role)
    ChefZeroSupport::Server.server.load_data({ 'roles' => { name => role }})
  end

  def user(name, user)
    ChefZeroSupport::Server.server.load_data({ 'users' => { name => user }})
  end

  RSpec.shared_context "With chef-zero running" do
    before :each do

      default_opts = {:port => 8900, :signals => false, :log_requests => true}
      server_opts = if self.respond_to?(:chef_zero_opts)
        default_opts.merge(chef_zero_opts)
      else
        default_opts
      end

      if ChefZeroSupport::Server.server && server_opts.any? { |opt, value| ChefZeroSupport::Server.server.options[opt] != value }
        ChefZeroSupport::Server.server.stop
        ChefZeroSupport::Server.server = nil
      end

      unless ChefZeroSupport::Server.server
        # TODO: can this be logged easily?
        # pp :zero_opts => server_opts

        # Set up configuration so that clients will point to the server
        ChefZeroSupport::Server.server = ChefZero::Server.new(server_opts)
        ChefZeroSupport::Server.client_key = Tempfile.new(['chef_zero_client_key', '.pem'])
        ChefZeroSupport::Server.client_key.write(ChefZero::PRIVATE_KEY)
        ChefZeroSupport::Server.client_key.close
        # Start the server
        ChefZeroSupport::Server.server.start_background
        ChefZeroSupport::Server.server.on_response do |request, response|
          ChefZeroSupport::Server.request_log << [ request, response ]
        end
      else
        ChefZeroSupport::Server.server.clear_data
      end
      ChefZeroSupport::Server.clear_request_log

      if defined?(Chef::Config)
        @old_chef_server_url = Chef::Config.chef_server_url
        @old_node_name = Chef::Config.node_name
        @old_client_key = Chef::Config.client_key
        Chef::Config.chef_server_url = ChefZeroSupport::Server.server.url
        Chef::Config.node_name = 'admin'
        Chef::Config.client_key = ChefZeroSupport::Server.client_key.path
        Chef::Config.http_retry_count = 0
      end
    end

    if defined?(Chef::Config)
      after :each do
        Chef::Config.chef_server_url = @old_chef_server_url
        Chef::Config.node_name = @old_node_name
        Chef::Config.client_key = @old_client_key
      end
    end

  end

end

