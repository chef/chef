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

require 'rubygems'
require 'rgl/adjacency'
require 'rgl/topsort'

class Marionette
  class Recipe
    
    include Marionette::Mixin::GraphResources
    
    attr_accessor :module_name, :recipe_name, :recipe, :node, :dg
    
    def initialize(module_name, recipe_name, node, dg=nil)
      @module_name = module_name
      @recipe_name = recipe_name
      @node = node
      if dg
        @dg = dg
      else
        @dg = RGL::DirectedAdjacencyGraph.new()
        @dg.add_vertex(:top)
      end
      @last_resource = :top
    end
        
    def method_missing(method_symbol, *args, &block)
      method_name = method_symbol.to_s
      resource = nil
      rname = nil
      case method_name
      when /^(.+)_(.+)$/
        rname = "Marionette::Resource::#{$1.capitalize}#{$2.capitalize}"
      when /^(.+)$/
        rname = "Marionette::Resource::#{$1.capitalize}"
      end
      begin
        args << @dg
        resource = eval(rname).new(*args)
        resource.run(block) if Kernel.block_given?
      rescue Exception => e
        raise NameError, "Cannot find #{rname} for #{method_name}\nOriginal: #{e.to_s}" if e.kind_of?(NameError)
        raise e
      end
      @dg.add_vertex(resource)
      @dg.add_edge(@last_resource, resource)
      @last_resource = resource
    end
      
    private
      def check_symbol_or_string(to_check, field_name)
        case to_check
        when Symbol, String
          true
        else
          raise ArgumentError, "you must pass a symbol or string to #{field_name}!"
        end
      end
  end
end