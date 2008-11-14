#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require File.join(File.dirname(__FILE__), "mixin", "from_file")

class Chef
  class Recipe
    
    include Chef::Mixin::FromFile
        
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
      
      @@seen_recipes ||= Hash.new
    end
    
    def include_recipe(*args)
      args.flatten.each do |recipe|
        if @@seen_recipes.has_key?(recipe)
          Chef::Log.debug("I am not loading #{recipe}, because I have already seen it.")
          next
        end
        Chef::Log.debug("#{@@seen_recipes.inspect}")
        @@seen_recipes[recipe] = true
        
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
    
    # Given a hash similar to the one we use for Platforms, select a value from the hash.  Supports
    # per platform defaults, along with a single base default.
    #
    # === Parameters
    # platform_hash:: A platform-style hash.
    #
    # === Returns
    # value:: Whatever the most specific value of the hash is.
    def value_for_platform(platform_hash)
      result = nil
      if platform_hash.has_key?(@node[:platform])
        if platform_hash[@node[:platform]].has_key?(@node[:platform_version])
          result = platform_hash[@node[:platform]][@node[:platform_version]]
        elsif platform_hash[@node[:platform]].has_key?("default")
          result = platform_hash[@node[:platform]]["default"]
        end
      end
      
      unless result
        if platform_hash.has_key?("default")
          result = platform_hash["default"]
        end
      end  
      
      result
    end
    
    # Given a list of platforms, returns true if the current recipe is being run on a node with
    # that platform, false otherwise.
    #
    # === Parameters
    # args:: A list of platforms
    #
    # === Returns
    # true:: If the current platform is in the list
    # false:: If the current platform is not in the list
    def platform?(*args)
      has_platform = false
      
      args.flatten.each do |platform|
        has_platform = true if platform == @node[:platform]
      end
      
      has_platform
    end
    
    def search(type, query, &block)
      Chef::Log.debug("Searching #{type} index with #{query}")
      r = Chef::REST.new(Chef::Config[:search_url])
      results = r.get_rest("search/#{type}?q=#{query}")
      Chef::Log.debug("Searching #{type} index with #{query} returned #{results.length} entries")
      results.each do |sr|
        block.call(sr)
      end
    end
        
    def method_missing(method_symbol, *args, &block)
      resource = nil
      # If we have a definition that matches, we want to use that instead.  This should
      # let you do some really crazy over-riding of "native" types, if you really want
      # to. 
      if @definitions.has_key?(method_symbol)
        new_def = @definitions[method_symbol].dup
        new_def.instance_eval(&block) if block
        new_recipe = Chef::Recipe.new(@cookbook_name, @recipe_name, @node, @collection, @definitions, @cookbook_loader)
        new_recipe.params = new_def.params
        new_recipe.params[:name] = args[0]
        new_recipe.instance_eval(&new_def.recipe)
      else
        method_name = method_symbol.to_s
      # Otherwise, we're rocking the regular resource call route.
        rname = nil
        mn = method_name.match(/^(.+)_(.+)$/)
        if mn
          rname = "Chef::Resource::#{mn[1].capitalize}#{mn[2].capitalize}"
        else
          short_match = method_name.match(/^(.+)$/)
          if short_match
            rname = "Chef::Resource::#{short_match[1].capitalize}"
          end
        end
        begin
          args << @collection
          args << @node
          resource = eval(rname).new(*args)
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