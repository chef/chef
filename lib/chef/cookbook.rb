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

class Chef
  class Cookbook
    
    attr_accessor :attribute_files, :definition_files, :name
    attr_reader :recipe_files
    
    def initialize(name)
      @name = name
      @attribute_files = Array.new
      @definition_files = Array.new
      @recipe_files = Array.new
      @recipe_names = Hash.new
      @loaded_attributes = false
    end
    
    def load_attributes(node)
      unless node.kind_of?(Chef::Node)
        raise ArgumentError, "You must pass a Chef::Node to load_attributes!"
      end
      @attribute_files.each do |file|
        node.from_file(file)
      end
      @loaded_atributes = true
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
      unless @loaded_attributes
        load_attributes(node)
      end
      recipe = Chef::Recipe.new(cookbook_name, recipe_name, node, 
                                collection, definitions, cookbook_loader)
      recipe.from_file(@recipe_files[@recipe_names[recipe_name]])
      recipe
    end
    
  end
end