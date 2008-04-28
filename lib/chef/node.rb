#
# Chef::Node
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

require File.join(File.dirname(__FILE__), "mixin", "check_helper")
require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require File.join(File.dirname(__FILE__), "mixin", "from_file")

require 'rubygems'
require 'json'

class Chef
  class Node
    
    attr_accessor :attribute, :recipe_list
    
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    
    # Create a new Chef::Node object.
    def initialize()
      @name = nil
      @attribute = Hash.new
      @recipe_list = Array.new
    end
    
    # Find a Chef::Node by fqdn.  Will search first for Chef::Config["node_path"]/fqdn.rb, then
    # hostname.rb, then default.rb.
    # 
    # Returns a new Chef::Node object.
    #
    # Raises an ArgumentError if it cannot find the node. 
    def self.find(fqdn)
      node_file = nil
      host_parts = fqdn.split(".")
      hostname = host_parts[0]

      if File.exists?(File.join(Chef::Config[:node_path], "#{fqdn}.rb"))
        node_file = File.join(Chef::Config[:node_path], "#{fqdn}.rb")
      elsif File.exists?(File.join(Chef::Config[:node_path], "#{hostname}.rb"))
        node_file = File.join(Chef::Config[:node_path], "#{hostname}.rb")
      elsif File.exists?(File.join(Chef::Config[:node_path], "default.rb"))
        node_file = File.join(Chef::Config[:node_path], "default.rb")
      else
        raise ArgumentError, "Cannot find a node matching #{fqdn}, not even with default.rb!"
      end
      chef_node = Chef::Node.new()
      chef_node.from_file(node_file)
      chef_node
    end

    # Returns an array of nodes available, based on the list of files present.
    def self.list
      results = Array.new
      Dir[File.join(Chef::Config[:node_path], "*.rb")].sort.each do |file|
        mr = file.match(/^.+\/(.+)\.rb$/)
        node_name = mr[1]
        results << node_name
      end
      results
    end
    
    # Set the name of this Node, or return the current name.
    def name(arg=nil)
      if arg != nil
        validate(
          { :name => arg }, 
          {
            :name => {
              :kind_of => String
            }
          }
        )
        @name = arg
      else
        @name
      end
    end
    
    # Return an attribute of this node.  Returns nil if the attribute is not found.
    def [](attrib)
      if @attribute.has_key?(attrib)        
        @attribute[attrib]
      elsif @attribute.has_key?(attrib.to_s)        
        @attribute[attrib.to_s]
      else
        nil
      end
    end
    
    # Set an attribute of this node
    def []=(attrib, value)
      @attribute[attrib] = value
    end
    
    # Iterates over each attribute, passing the attribute and value to the block.
    def each_attribute(&block)
      @attribute.each do |k,v|
        yield(k, v)
      end
    end
    
    # Return true if this Node has a given attribute, false if not.  Takes either a symbol or
    # a string.
    def attribute?(attrib)
      result = false
      result = @attribute.has_key?(attrib)
      return result if result
      return @attribute.has_key?(attrib.to_sym)
    end
    
    # Returns true if this Node expects a given recipe, false if not.
    def recipe?(recipe_name)
      @recipe_list.detect { |r| r == recipe_name } ? true : false
    end
    
    # Returns an Array of recipes.  If you call it with arguments, they will become the new
    # list of recipes.
    def recipes(*args)
      if args.length > 0
        @recipe_list = args.flatten
      else
        @recipe_list
      end
    end
    
    # Set an attribute based on the missing method.  If you pass an argument, we'll use that
    # to set the attribute values.  Otherwise, we'll wind up just returning the attributes
    # value.
    def method_missing(symbol, *args)
      if args.length != 0
        @attribute[symbol] = args.length == 1 ? args[0] : args
      else
        if @attribute.has_key?(symbol)
          @attribute[symbol]
        else
          raise ArgumentError, "Attribute #{symbol.to_s} is not defined!"
        end
      end
    end
    
    # Serialize this Node as json
    def to_json()
      result_object = {
        "name" => @name,
        "type" => "Chef::Node",
        "attributes" => Hash.new,
        "recipes" => Array.new
      }
      each_attribute do |a,v|
        result_object["attributes"][a] = v
      end
      recipes.each do |r|
        result_object["recipes"] << r
      end
      result_object.to_json
    end
    
    # As a string
    def to_s
      "node[#{@name}]"
    end
    
  end
end