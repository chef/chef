#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

require File.join(File.dirname(__FILE__), "mixin", "from_file")

class Chef
  class Recipe
    
    include Chef::Mixin::FromFile
        
    attr_accessor :cookbook_name, :recipe_name, :recipe, :node, :collection, 
                  :definitions, :config, :params
    
    def initialize(cookbook_name, recipe_name, node, collection=nil, definitions=nil, config=nil)
      @cookbook_name = cookbook_name
      @recipe_name = recipe_name
      @node = node
      if collection
        @collection = collection
      else
        @collection = Chef::ResourceCollection.new()
      end
      if config
        @config = config
      else
        @config = Chef::Config.new()
      end
      if definitions
        @definitions = definitions
      else
        @definitions = Hash.new
      end
      @params = Hash.new
    end
    
    def resources(*args)
      @collection.resources(*args)
    end
        
    def method_missing(method_symbol, *args, &block)
      resource = nil
      # If we have a definition that matches, we want to use that instead.  This should
      # let you do some really crazy over-riding of "native" types, if you really want
      # to.
      if @definitions.has_key?(method_symbol)
        new_def = @definitions[method_symbol].dup
        new_def.instance_eval(&block)
        new_recipe = Chef::Recipe.new(@cookbook_name, @recipe_name, @node, @collection, @definitions, @config)
        new_recipe.params = new_def.params
        new_recipe.instance_eval(&new_def.recipe)
      else
        method_name = method_symbol.to_s
      # Otherwise, we're rocking the regular resource call route.
        rname = nil
        case method_name
        when /^(.+)_(.+)$/
          rname = "Chef::Resource::#{$1.capitalize}#{$2.capitalize}"
        when /^(.+)$/
          rname = "Chef::Resource::#{$1.capitalize}"
        end
        begin
          args << @collection
          args << @config
          resource = eval(rname).new(*args)
          resource.params = @params
          resource.instance_eval(&block)
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