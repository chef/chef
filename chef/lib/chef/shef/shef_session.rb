# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

module Shef
  class ShefSession
    include Singleton
    
    attr_accessor :node, :compile, :recipe, :run_context
    attr_reader :node_attributes, :client
    def initialize
      @node_built = false
    end
    
    def node_built?
      !!@node_built
    end
    
    def reset!
      loading do 
        rebuild_node
        @node = client.node
        rebuild_context
        node.consume_attributes(node_attributes) if node_attributes
        shorten_node_inspect
        @recipe = Chef::Recipe.new(nil, nil, run_context)
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
      @run_context || rebuild_context
    end
    
    def definitions
      nil
    end
    
    def cookbook_loader
      nil
    end
    
    def save_node
      raise "Not Supported! #{self.class.name} doesn't support #save_node, maybe you need to run shef in client mode?"
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
  
  class StandAloneSession < ShefSession
    
    def rebuild_context
      @run_context = Chef::RunContext.new(@node, {}) # no recipes
    end
    
    private
    
    def rebuild_node
      Chef::Config[:solo] = true
      @client = Chef::Client.new
      @client.run_ohai
      @client.determine_node_name
      @client.build_node #(@client.node_name, true)
    end
    
  end
  
  class SoloSession < ShefSession
    
    def definitions
      @run_context.definitions
    end
    
    def rebuild_context
      @run_context = Chef::RunContext.new(@node, Chef::CookbookCollection.new(Chef::CookbookLoader.new))
    end
    
    private
    
    def rebuild_node
      # Tell the client we're chef solo so it won't try to contact the server
      Chef::Config[:solo] = true
      @client = Chef::Client.new
      @client.run_ohai
      @client.determine_node_name
      @client.build_node #(@client.node_name, true)
    end
    
  end
  
  class ClientSession < SoloSession
    
    def save_node
      @client.save_node
    end
    
    private

    def rebuild_node
      # Make sure the client knows this is not chef solo
      Chef::Config[:solo] = false
      @client = Chef::Client.new
      @client.run_ohai
      @client.determine_node_name
      @client.register
      @client.build_node #(@client.node_name, false)
      
      @client.sync_cookbooks({})
    end

  end
end
