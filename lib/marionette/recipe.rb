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

class Marionette
  class Recipe
    
    include Marionette::Mixin::GraphResources
    
    attr_accessor :module_name, :recipe_name, :recipe, :node, :dg, :deps
    
    def initialize(module_name, recipe_name, node, dg=nil, deps=nil)
      @module_name = module_name
      @recipe_name = recipe_name
      @node = node
      if dg
        @dg = dg
      else
        @dg = RGL::DirectedAdjacencyGraph.new()
        @dg.add_vertex(:top)
      end
      if deps
        @deps = deps
      else
        @deps = RGL::DirectedAdjacencyGraph.new()
      end
      @last_resource = :top
      @in_order = Array.new
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
        args << @deps
        resource = eval(rname).new(*args)
        resource.instance_eval(&block)
      rescue Exception => e
        if e.kind_of?(NameError) && e.to_s =~ /Marionette::Resource/
          raise NameError, "Cannot find #{rname} for #{method_name}\nOriginal: #{e.to_s}"
        else
          raise e
        end
      end
      @dg.add_vertex(resource)
      @dg.add_edge(@last_resource, resource)
      @last_resource = resource
    end
  end
end