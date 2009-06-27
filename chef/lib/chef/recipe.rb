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
#

require 'chef/resource'
Dir[File.join(File.dirname(__FILE__), 'resource/**/*.rb')].sort.each { |lib| require lib }
require 'chef/mixin/from_file'
require 'chef/mixin/language'
require 'chef/resource_collection'
require 'chef/cookbook_loader'
require 'chef/rest'
require 'chef/search/result'

class Chef
  class Recipe
    
    include Chef::Mixin::FromFile
    include Chef::Mixin::Language
        
    attr_accessor :cookbook_name, :recipe_name, :recipe, :node, :collection, 
                  :definitions, :params, :cookbook_loader
    
    def initialize(cookbook_name, recipe_name, node, collection=nil, definitions=nil, cookbook_loader=nil)
      @cookbook_name = cookbook_name
      @recipe_name = recipe_name
      @node = node
      
      if collection
        @collection = collection
      else
        @collection = Chef::ResourceCollection.new()
      end
      
      if definitions
        @definitions = definitions
      else
        @definitions = Hash.new
      end
      
      if cookbook_loader
        @cookbook_loader = cookbook_loader
      else
        @cookbook_loader = Chef::CookbookLoader.new()
      end
      
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
        
    def method_missing(method_symbol, *args, &block)
      resource = nil
      # If we have a definition that matches, we want to use that instead.  This should
      # let you do some really crazy over-riding of "native" types, if you really want
      # to. 
      if @definitions.has_key?(method_symbol)
        # This dupes the high level object, but we still need to dup the params
        new_def = @definitions[method_symbol].dup
        new_def.params = new_def.params.dup
        new_def.node = @node
        # This sets up the parameter overrides
        new_def.instance_eval(&block) if block
        new_recipe = Chef::Recipe.new(@cookbook_name, @recipe_name, @node, @collection, @definitions, @cookbook_loader)
        new_recipe.params = new_def.params
        new_recipe.params[:name] = args[0]
        new_recipe.instance_eval(&new_def.recipe)
      else
        method_name = method_symbol.to_s
        # Otherwise, we're rocking the regular resource call route.
        rname = nil
        regexp = %r{^(.+?)(_(.+))?$}

        mn = method_name.match(regexp)
        if mn
          rname = "Chef::Resource::#{mn[1].capitalize}"

          while mn && mn[3]
            mn = mn[3].match(regexp)          
            rname << mn[1].capitalize if mn
          end
        end

        begin
          args << @collection
          args << @node
          resource = eval(rname).new(*args)
          # If we have a resource like this one, we want to steal it's state
          resource.load_prior_resource
          resource.cookbook_name = @cookbook_name
          resource.recipe_name = @recipe_name
          resource.params = @params
          resource.instance_eval(&block) if block
        rescue Exception => e
          if e.kind_of?(NameError) && e.to_s =~ /Chef::Resource/
            raise NameError, "Cannot find #{rname} for #{method_name}\nOriginal: #{e.to_s}"
          else
            raise e
          end
        end
        @collection << resource
        resource
      end
    end
  end
end
