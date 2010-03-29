#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

require 'chef/log'
require 'chef/node'
require 'chef/resource_definition_list'
require 'chef/recipe'
require 'chef/mixin/convert_to_class_name'

class Chef
  class Cookbook
    include Chef::Mixin::ConvertToClassName
    
    attr_accessor :definition_files, :template_files, :remote_files, 
                  :lib_files, :resource_files, :provider_files, :name
    attr_reader :recipe_files, :attribute_files
    
    # Creates a new Chef::Cookbook object.  
    #
    # === Returns
    # object<Chef::Cookbook>:: Duh. :)
    def initialize(name)
      @name = name
      @attribute_files = Array.new
      @attribute_names = Hash.new
      @definition_files = Array.new
      @template_files = Array.new
      @remote_files = Array.new
      @recipe_files = Array.new
      @recipe_names = Hash.new
      @lib_files = Array.new
      @resource_files = Array.new
      @provider_files = Array.new
    end
    
    # Loads all the library files in this cookbook via require.
    #
    # === Returns
    # true:: Always returns true
    def load_libraries
      @lib_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name} library file: #{file}")
        require file
      end
      true
    end
    
    # Loads all the attribute files in this cookbook within a particular <Chef::Node>.
    #
    # === Parameters
    # node<Chef::Node>:: The Chef::Node to apply the attributes to
    #
    # === Returns
    # node<Chef::Node>:: The updated Chef::Node object
    #
    # === Raises
    # <ArgumentError>:: If the argument is not a kind_of? <Chef::Node>
    def load_attributes(node)
      @attribute_files.each do |file|
        load_attribute_file(file, node)
      end
      node
    end

    def load_attribute_file(file, node)
      Chef::Log.debug("Loading attributes from #{file}")
      node.from_file(file)
    end

    def load_attribute(name, node)
      attr_name = shorten_name(name)
      file = @attribute_files[@attribute_names[attr_name]]
      load_attribute_file(file, node)
      node
    end
    
    # Loads all the resource definitions in this cookbook.
    #
    # === Returns
    # definitions<Hash>: A hash of <Chef::ResourceDefinition> objects, keyed by name.
    def load_definitions
      results = Hash.new
      @definition_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s definitions from #{file}")
        resourcelist = Chef::ResourceDefinitionList.new
        resourcelist.from_file(file)
        results.merge!(resourcelist.defines) do |key, oldval, newval|
          Chef::Log.info("Overriding duplicate definition #{key}, new found in #{file}")
          newval
        end
      end
      results
    end

    # Loads all the resources in this cookbook.
    #
    # === Returns
    # true:: Always returns true
    def load_resources
      @resource_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s resources from #{file}")
        Chef::Resource.build_from_file(name, file)
      end
    end
    
    # Loads all the providers in this cookbook.
    #
    # === Returns
    # true:: Always returns true
    def load_providers
      @provider_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s providers from #{file}")
        Chef::Provider.build_from_file(name, file)
      end
    end
    
    def recipe_files=(*args)
      @recipe_files, @recipe_names = set_with_names(args.flatten)
      @recipe_files
    end

    def attribute_files=(*args)
      @attribute_files, @attribute_names = set_with_names(args.flatten)
      @attribute_files
    end
    
    def recipe?(name)
      lookup_name = name
      if name =~ /(.+)::(.+)/
        cookbook_name = $1
        lookup_name = $2
        return false unless cookbook_name == @name
      end
      @recipe_names.has_key?(lookup_name)
    end
    
    def recipes
      results = Array.new
      @recipe_names.each_key do |rname|
        results << "#{@name}::#{rname}"
      end
      results
    end
    
    def load_recipe(name, node, collection=nil, definitions=nil, cookbook_loader=nil)
      cookbook_name = @name
      recipe_name = shorten_name(name) 
      
      unless @recipe_names.has_key?(recipe_name)
        raise ArgumentError, "Cannot find a recipe matching #{recipe_name} in cookbook #{@name}"
      end
      Chef::Log.debug("Found recipe #{recipe_name} in cookbook #{cookbook_name}") if Chef::Log.debug?
      recipe = Chef::Recipe.new(cookbook_name, recipe_name, node, 
                                collection, definitions, cookbook_loader)
      recipe.from_file(@recipe_files[@recipe_names[recipe_name]])
      recipe
    end

    private

      def shorten_name(name)
        short_name = nil
        nmatch = name.match(/^(.+?)::(.+)$/)
        short_name = nmatch ? nmatch[2] : name
      end

      def set_with_names(file_list)
        files = file_list
        names = Hash.new
        files.each_index do |i|
          file = files[i]
          case file
          when /(.+\/)(.+).rb$/
            names[$2] = i
          when /(.+).rb$/
            names[$1] = i
          else  
            names[file] = i
          end
        end
        [ files, names ]
      end
    
  end
end
