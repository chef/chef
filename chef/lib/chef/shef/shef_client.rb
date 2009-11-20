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
  class ShefClient < Hash
    include Singleton
    
    def initialize
      @node_built = false
    end
    
    def node_built?
      !!@node_built
    end
    
    def reset!
      loading = true
      dots = Thread.new do
        print "Loading"
        while loading
          print "."
          sleep 0.5
        end
        print "done.\n\n"
      end

      rebuild_node
      
      node = self[:node] = self[:client].node
      def node.inspect
        "<Chef::Node:0x#{self.object_id.to_s(16)} @name=\"#{self.name}\">"
      end
      
      self[:recipe] = Chef::Recipe.new(nil, nil, self[:node])
      @node_built = true
      loading = false
      dots.join
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
    
    def rebuild_node
      raise "Not Implemented! :rebuild_node should be implemented by subclasses"
    end
 
  end
  
  class StandAloneClient < ShefClient
    
    def rebuild_collection
      @collection = self[:recipe].collection
    end
    
    private
    
    def rebuild_node
      self[:client] = Chef::Client.new
      self[:client].determine_node_name
      self[:client].build_node(self[:client].node_name, true)
    end
    
  end
  
  class SoloClient < ShefClient
    
    def definitions
      self[:compile].definitions
    end
    
    def cookbook_loader
      self[:compile].cookbook_loader
    end
    
    def rebuild_collection
      @collection = self[:compile].collection
      @collection << self[:recipe].collection.all_resources
      @collection
    end
    
    private
    
    def rebuild_node
      self[:client] = Chef::Client.new
      self[:client].determine_node_name
      self[:client].build_node(self[:client].node_name, true)
      
      self[:compile] = Chef::Compile.new(self[:client].node)
      
    end
    
  end
  
  class ServerClient < SoloClient
    
    def save_node
      self[:client].save_node
    end
    
    private

    def rebuild_node
      self[:client] = Chef::Client.new
      self[:client].determine_node_name
      self[:client].build_node(self[:client].node_name, true)
      
      self[:client].sync_cookbooks
      
      self[:compile] = Chef::Compile.new(self[:client].node)
    end

  end
end