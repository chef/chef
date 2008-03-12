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
    
    def initialize()
      @name = nil
      @attribute = Hash.new
      @recipe_list = Array.new
    end
    
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
    
    def [](attrib)
      if @attribute.has_key?(attrib)        
        @attribute[attrib]
      elsif @attribute.has_key?(attrib.to_s)        
        @attribute[attrib.to_s]
      else
        nil
      end
    end
    
    def attribute?(attrib)
      result = false
      result = @attribute.has_key?(attrib)
      return result if result
      return @attribute.has_key?(attrib.to_sym)
    end
    
    def recipe?(recipe_name)
      @recipe_list.detect { |r| r == recipe_name } ? true : false
    end
    
    def recipes(*args)
      if args.length > 0
        @recipe_list = args.flatten
      else
        @recipe_list
      end
    end
    
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