#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

class Chef
  class Cookbook
    
    attr_accessor :attribute_files, :definition_files, :template_files, :remote_files, 
                  :lib_files, :name
    attr_reader :recipe_files
    
    def initialize(name)
      @name = name
      @attribute_files = Array.new
      @definition_files = Array.new
      @template_files = Array.new
      @remote_files = Array.new
      @recipe_files = Array.new
      @recipe_names = Hash.new
      @lib_files = Array.new
    end
    
    def load_libraries
      @lib_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name} library file: #{file}")
        require file
      end
    end
    
    def load_attributes(node)
      unless node.kind_of?(Chef::Node)
        raise ArgumentError, "You must pass a Chef::Node to load_attributes!"
      end
      @attribute_files.each do |file|
        Chef::Log.debug("Loading attributes from #{file}")
        node.from_file(file)
      end
      node
    end
    
    def load_definitions
      results = Hash.new
      @definition_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s definitions from #{file}")
        resourcedef = Chef::ResourceDefinition.new
        resourcedef.from_file(file)
        results[resourcedef.name] = resourcedef
      end
      results
    end
    
    def recipe_files=(*args)
      @recipe_files = args.flatten
      @recipe_files.each_index do |i|
        file = @recipe_files[i]
        case file
        when /(.+\/)(.+).rb$/
          @recipe_names[$2] = i
        when /(.+).rb$/
          @recipe_names[$1] = i
        else  
          @recipe_names[file] = i
        end
      end
      @recipe_files
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
      recipe_name = nil
      nmatch = name.match(/^(.+?)::(.+)$/)
      recipe_name = nmatch ? nmatch[2] : name
      
      unless @recipe_names.has_key?(recipe_name)
        raise ArgumentError, "Cannot find a recipe matching #{recipe_name} in cookbook #{@name}"
      end
      Chef::Log.debug("Found recipe #{recipe_name} in cookbook #{cookbook_name}") if Chef::Log.debug?
      recipe = Chef::Recipe.new(cookbook_name, recipe_name, node, 
                                collection, definitions, cookbook_loader)
      recipe.from_file(@recipe_files[@recipe_names[recipe_name]])
      recipe
    end
    
  end
end