#
# Chef::Node
#
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
require File.join(File.dirname(__FILE__), "mixin", "from_file")

class Chef
  class Node
    
    attr_accessor :attribute, :recipe_list
    
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::FromFile
    
    # Create a new Chef::Node object.
    def initialize()
      @name = nil
      @attribute = Hash.new
      @recipe_list = Array.new
    end
    
    # Set the name of this Node, or return the current name.
    def name(arg=nil)
      set_if_args(@name, arg) do |a|
        case a
        when String
          @name = a
        else
          raise ArgumentError, "The nodes name must be a string"
        end
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
    
  end
end