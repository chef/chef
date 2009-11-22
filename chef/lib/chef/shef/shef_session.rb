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
    
    attr_accessor :node, :compile, :recipe
    attr_reader :node_attributes
    
    def node_attributes=(attrs)
      @node_attributes = attrs
      @node.consume_attributes(@node_attributes)
    end
    
    def initialize
      @node_built = false
    end
    
    def node_built?
      !!@node_built
    end
    
    def reset!
      loading

      rebuild_node
      
      @node = @client.node
      def @node.inspect
        "<Chef::Node:0x#{self.object_id.to_s(16)} @name=\"#{self.name}\">"
      end
      
      @recipe = Chef::Recipe.new(nil, nil, @node)
      @node_built = true
      loading_complete
    end
    
    def collection
      @collection || rebuild_collection
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
    
    def rebuild_collection
      raise "Not Implemented! :rebuild_collection should be implemented by subclasses"
    end
    
    private
    
    def loading
      @loading = true
      @dot_printer = Thread.new do
        print "Loading"
        while @loading
          print "."
          sleep 0.5
        end
        print "done.\n\n"
      end
    end
    
    def loading_complete
      @loading = false
      @dot_printer && @dot_printer.join
    end
    
    def rebuild_node
      raise "Not Implemented! :rebuild_node should be implemented by subclasses"
    end
 
  end
  
  class StandAloneSession < ShefSession
    
    def rebuild_collection
      @collection = @recipe.collection
    end
    
    private
    
    def rebuild_node
      @client = Chef::Client.new
      @client.determine_node_name
      @client.build_node(@client.node_name, true)
    end
    
  end
  
  class SoloSession < ShefSession
    
    def definitions
      @compile.definitions
    end
    
    def cookbook_loader
      @compile.cookbook_loader
    end
    
    def rebuild_collection
      @compile = Chef::Compile.new(@client.node)
      
      @collection = @compile.collection
      @collection << @recipe.collection.all_resources
      @collection
    end
    
    private
    
    def rebuild_node
      @client = Chef::Client.new
      @client.determine_node_name
      @client.build_node(@client.node_name, true)
    end
    
  end
  
  class ClientSession < SoloSession
    
    def save_node
      @client.save_node
    end
    
    private

    def rebuild_node
      @client = Chef::Client.new
      @client.determine_node_name
      @client.build_node(@client.node_name, true)
      
      @client.sync_cookbooks
    end

  end
end