#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/resource'
Dir[File.join(File.dirname(__FILE__), 'resource/**/*.rb')].sort.each { |lib| require lib }
require 'chef/mixin/from_file'
require 'chef/mixin/language'
require 'chef/mixin/recipe_definition_dsl_core'
require 'chef/resource_collection'
require 'chef/cookbook_loader'
require 'chef/rest'
require 'chef/search/result'

class Chef
  class Recipe
    
    include Chef::Mixin::FromFile
    include Chef::Mixin::Language
    include Chef::Mixin::RecipeDefinitionDSLCore
    
    attr_accessor :cookbook_name, :recipe_name, :recipe, :node, :collection, 
                  :definitions, :params, :cookbook_loader
    
    def initialize(cookbook_name, recipe_name, node, collection=nil, definitions=nil, cookbook_loader=nil)
      @cookbook_name = cookbook_name
      @recipe_name = recipe_name
      @node = node
      @collection = collection || Chef::ResourceCollection.new
      @definitions = definitions || Hash.new
      @cookbook_loader = cookbook_loader || Chef::CookbookLoader.new
      @params = Hash.new      
    end
    
    def include_recipe(*args)
      args.flatten.each do |recipe|
        if @node.run_state[:seen_recipes].has_key?(recipe)
          Chef::Log.debug("I am not loading #{recipe}, because I have already seen it.")
          next
        end        

        Chef::Log.debug("Loading Recipe #{recipe} via include_recipe")
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
    end
    
    def require_recipe(*args)
      include_recipe(*args)
    end
    
    def resources(*args)
      @collection.resources(*args)
    end
    
    def search(type, query, attributes=[], &block)
      Chef::Log.debug("Searching #{type} index with #{query}")
      r = Chef::REST.new(Chef::Config[:search_url])

      results = r.get_rest("search/#{type}?q=#{query}&a=#{attributes.join(',')}")
      Chef::Log.debug("Searching #{type} index with #{query} returned #{results.length} entries")
      if block
        results.each do |sr|
          block.call(sr)
        end
      else
        results
      end
    end
    
    # Sets a tag, or list of tags, for this node.  Syntactic sugar for
    # @node[:tags].  
    #
    # With no arguments, returns the list of tags.
    #
    # === Parameters
    # tags<Array>:: A list of tags to add - can be a single string
    #
    # === Returns
    # tags<Array>:: The contents of @node[:tags]
    def tag(*args)
      if args.length > 0
        args.each do |tag|
          @node[:tags] << tag unless @node[:tags].include?(tag)
        end
        @node[:tags]
      else
        @node[:tags]
      end
    end
    
    # Returns true if the node is tagged with the supplied list of tags.
    #
    # === Parameters
    # tags<Array>:: A list of tags
    #
    # === Returns
    # true<TrueClass>:: If all the parameters are present
    # false<FalseClass>:: If any of the parameters are missing
    def tagged?(*args)
      args.each do |tag|
        return false unless @node[:tags].include?(tag)
      end
      true
    end
    
    # Removes the list of tags from the node.
    #
    # === Parameters
    # tags<Array>:: A list of tags
    #
    # === Returns
    # tags<Array>:: The current list of @node[:tags]
    def untag(*args)
      args.each do |tag|
        @node[:tags].delete(tag)
      end
    end
    
  end
end
