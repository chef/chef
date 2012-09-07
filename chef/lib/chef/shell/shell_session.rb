#--
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/recipe'
require 'chef/run_context'
require 'chef/config'
require 'chef/client'
require 'chef/cookbook/cookbook_collection'
require 'chef/cookbook_loader'
require 'chef/run_list/run_list_expansion'
require 'chef/formatters/base'
require 'chef/formatters/doc'
require 'chef/formatters/minimal'

module Shell
  class ShellSession
    include Singleton

    def self.session_type(type=nil)
      @session_type = type if type
      @session_type
    end

    attr_accessor :node, :compile, :recipe, :run_context
    attr_reader :node_attributes, :client
    def initialize
      @node_built = false
      formatter = Chef::Formatters.new(Chef::Config.formatter, STDOUT, STDERR)
      @events = Chef::EventDispatch::Dispatcher.new(formatter)
    end

    def node_built?
      !!@node_built
    end

    def reset!
      loading do
        rebuild_node
        @node = client.node
        shorten_node_inspect
        Shell::Extensions.extend_context_node(@node)
        rebuild_context
        node.consume_attributes(node_attributes) if node_attributes
        @recipe = Chef::Recipe.new(nil, nil, run_context)
        Shell::Extensions.extend_context_recipe(@recipe)
        @node_built = true
      end
    end

    def node_attributes=(attrs)
      @node_attributes = attrs
      @node.consume_attributes(@node_attributes)
    end

    def resource_collection
      run_context.resource_collection
    end

    def run_context
      @run_context ||= rebuild_context
    end

    def definitions
      nil
    end

    def cookbook_loader
      nil
    end

    def save_node
      raise "Not Supported! #{self.class.name} doesn't support #save_node, maybe you need to run chef-shell in client mode?"
    end

    def rebuild_context
      raise "Not Implemented! :rebuild_collection should be implemented by subclasses"
    end

    private

    def loading
      show_loading_progress
      begin
        yield
      rescue => e
        loading_complete(false)
        raise e
      else
        loading_complete(true)
      end
    end

    def show_loading_progress
      print "Loading"
      @loading = true
      @dot_printer = Thread.new do
        while @loading
          print "."
          sleep 0.5
        end
      end
    end

    def loading_complete(success)
      @loading = false
      @dot_printer.join
      msg = success ? "done.\n\n" : "epic fail!\n\n"
      print msg
    end

    def shorten_node_inspect
      def @node.inspect
        "<Chef::Node:0x#{self.object_id.to_s(16)} @name=\"#{self.name}\">"
      end
    end

    def rebuild_node
      raise "Not Implemented! :rebuild_node should be implemented by subclasses"
    end

  end

  class StandAloneSession < ShellSession

    session_type :standalone

    def rebuild_context
      cookbook_collection = Chef::CookbookCollection.new({})
      @run_context = Chef::RunContext.new(@node, cookbook_collection, @events) # no recipes
      @run_context.load(Chef::RunList::RunListExpansionFromDisk.new("_default", [])) # empty recipe list
    end

    private

    def rebuild_node
      Chef::Config[:solo] = true
      @client = Chef::Client.new
      @client.run_ohai
      @client.load_node
      @client.build_node
    end

  end

  class SoloSession < ShellSession

    session_type :solo

    def definitions
      @run_context.definitions
    end

    def rebuild_context
      @run_status = Chef::RunStatus.new(@node, @events)
      Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, Chef::Config[:cookbook_path]) }
      cl = Chef::CookbookLoader.new(Chef::Config[:cookbook_path])
      cl.load_cookbooks
      cookbook_collection = Chef::CookbookCollection.new(cl)
      @run_context = Chef::RunContext.new(node, cookbook_collection, @events) 
      @run_context.load(Chef::RunList::RunListExpansionFromDisk.new("_default", []))
      @run_status.run_context = run_context
    end

    private

    def rebuild_node
      # Tell the client we're chef solo so it won't try to contact the server
      Chef::Config[:solo] = true
      @client = Chef::Client.new
      @client.run_ohai
      @client.load_node
      @client.build_node
    end

  end

  class ClientSession < SoloSession

    session_type :client

    def save_node
      @client.save_node
    end

    def rebuild_context
      @run_status = Chef::RunStatus.new(@node, @events)
      Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::RemoteFileVendor.new(manifest, Chef::REST.new(Chef::Config[:server_url])) }
      cookbook_hash = @client.sync_cookbooks
      cookbook_collection = Chef::CookbookCollection.new(cookbook_hash)
      @run_context = Chef::RunContext.new(node, cookbook_collection, @events) 
      @run_context.load(Chef::RunList::RunListExpansionFromAPI.new("_default", []))
      @run_status.run_context = run_context
    end

    private

    def rebuild_node
      # Make sure the client knows this is not chef solo
      Chef::Config[:solo] = false
      @client = Chef::Client.new
      @client.run_ohai
      @client.register
      @client.load_node
      @client.build_node
    end

  end

  class DoppelGangerClient < Chef::Client

    attr_reader :node_name

    def initialize(node_name)
      @node_name = node_name
      @ohai = Ohai::System.new
    end

    # Run the very smallest amount of ohai we can get away with and still
    # hope to have things work. Otherwise we're not very good doppelgangers
    def run_ohai
      @ohai.require_plugin('os')
    end

    # DoppelGanger implementation of build_node. preserves as many of the node's
    # attributes, and does not save updates to the server
    def build_node
      Chef::Log.debug("Building node object for #{@node_name}")
      @node = Chef::Node.find_or_create(node_name)
      ohai_data = @ohai.data.merge(@node.automatic_attrs)
      @node.consume_external_attrs(ohai_data,nil)
      @run_list_expansion = @node.expand!('server')
      @expanded_run_list_with_versions = @run_list_expansion.recipes.with_version_constraints_strings
      Chef::Log.info("Run List is [#{@node.run_list}]")
      Chef::Log.info("Run List expands to [#{@expanded_run_list_with_versions.join(', ')}]")
      @node
    end

    def register
      @rest = Chef::REST.new(Chef::Config[:chef_server_url], Chef::Config[:node_name], Chef::Config[:client_key])
    end

  end

  class DoppelGangerSession < ClientSession

    session_type "doppelganger client"

    def save_node
      puts "A doppelganger should think twice before saving the node"
    end

    def assume_identity(node_name)
      Chef::Config[:doppelganger] = @node_name = node_name
      reset!
    rescue Exception => e
      puts "#{e.class.name}: #{e.message}"
      puts Array(e.backtrace).join("\n")
      puts
      puts "* " * 40
      puts "failed to assume the identity of node '#{node_name}', resetting"
      puts "* " * 40
      puts
      Chef::Config[:doppelganger] = false
      @node_built = false
      Shell.session
    end

    def rebuild_node
      # Make sure the client knows this is not chef solo
      Chef::Config[:solo] = false
      @client = DoppelGangerClient.new(@node_name)
      @client.run_ohai
      @client.register
      @client.load_node
      @client.build_node
      @client.sync_cookbooks
    end

  end

end
