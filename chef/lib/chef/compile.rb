#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/cookbook_loader'
require 'chef/resource_collection'
require 'chef/node'
require 'chef/role'
require 'chef/log'
require 'chef/mixin/deep_merge'

class Chef
  class Compile
      
    attr_accessor :node, :cookbook_loader, :collection, :definitions
    
    # Creates a new Chef::Compile object.  This object gets used by the Chef Server to generate
    # a fully compiled recipe list for a node.
    #
    # === Returns
    # object<Chef::Compile>:: Duh. :)
    def initialize(node=nil)
      @node = node 
      @cookbook_loader = Chef::CookbookLoader.new
      @collection = Chef::ResourceCollection.new
      @definitions = Hash.new
      @recipes = Array.new
      @default_attributes = Array.new
      @override_attributes = Array.new
    end
    
    # Looks up the node via the "name" argument, first from CouchDB, then by calling
    # Chef::Node.find_file(name)
    #
    # The first step in compiling the catalog. Results available via the node accessor.
    #
    # === Returns
    # node<Chef::Node>:: The loaded Chef Node
    def load_node(name)
      Chef::Log.debug("Loading Chef Node #{name} from CouchDB")
      @node = Chef::Node.load(name)
      Chef::Log.debug("Loading Recipe for Chef Node #{name}")
      @node.find_file(name)
      @node
    end
    
    # Load all the attributes, from every cookbook
    #
    # === Returns
    # true:: Always returns true
    def load_attributes()
      recipes, default_attrs, override_attrs = expand_node
      # Merge the default attrs, using the nodes current as the winner 
      @node.attribute = Chef::Mixin::DeepMerge.merge(default_attrs, @node.attribute)
      @cookbook_loader.each do |cookbook|
        cookbook.load_attributes(@node)
      end
      # Merge the override attrs, using the nodes current as the winner
      @node.attribute = Chef::Mixin::DeepMerge.merge(@node.attribute, override_attrs)
      true
    end
    
    # Load all the definitions, from every cookbook, so they are available when we process
    # the recipes.
    #
    # Results available via the definitions accessor.
    #
    # === Returns
    # true:: Always returns true
    def load_definitions()
      @cookbook_loader.each do |cookbook|
        hash = cookbook.load_definitions
        @definitions.merge!(hash)
      end
      true
    end
    
    # Load all the libraries, from every cookbook, so they are available when we process
    # the recipes.
    #
    # === Returns
    # true:: Always returns true
    def load_libraries()
      @cookbook_loader.each do |cookbook|
        cookbook.load_libraries
      end
      true
    end
    
    # Load all the recipes specified in the node data (loaded via load_node, above.)
    # 
    # The results are available via the collection accessor (which returns a Chef::ResourceCollection 
    # object)
    #
    # === Returns
    # true:: Always returns true
    def load_recipes
      expand_node
      @recipes.each do |recipe|
        if @node.run_state[:seen_recipes].has_key?(recipe)
          Chef::Log.debug("I am not loading #{recipe}, because I have already seen it.")
          next
        end
        Chef::Log.debug("Loading Recipe #{recipe}")
        @node.run_state[:seen_recipes][recipe] = true

        rmatch = recipe.match(/(.+?)::(.+)/)
        if rmatch
         cookbook = @cookbook_loader[rmatch[1]]
         cookbook.load_recipe(rmatch[2], @node, @collection, @definitions, @cookbook_loader)
        else
         cookbook = @cookbook_loader[recipe]
         cookbook.load_recipe("default", @node, @collection, @definitions, @cookbook_loader)
        end
      end
      true
    end

    def expand_node
      if @recipes.empty? && @override_attributes.empty? && @default_attributes.empty?
        @recipes, @default_attributes, @override_attributes = @node.run_list.expand
      end
      return @recipes, @default_attributes, @override_attributes
    end
    
  end
end
