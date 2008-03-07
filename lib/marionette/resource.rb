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

require 'yaml'

class Marionette
  class Resource
    
    include Marionette::Mixin::GraphResources
    
    attr_accessor :before, :requires, :notifies, :subscribes, :tag
    attr_reader :name, :alias, :noop, :tag, :resource_name, :dg
    
    def initialize(name, dg=nil)
      @name = name
      if dg
        @dg = dg
      else
        @dg = RGL::DirectedAdjacencyGraph.new()
        @dg.add_vertex(:top)
      end
      @tag = Array.new
      @alias = nil
      @noop = nil
      @tag = nil
      @before = nil
      @tag = nil
    end
    
    def name=(name)
      raise ArgumentError, "name must be a string!" unless name.kind_of?(String)
      @name = name
    end
    
    def alias=(alias_name)
      raise ArgumentError, "alias must be a string!" unless alias_name.kind_of?(String)
      @alias = alias_name
    end
    
    def noop=(tf)      
      raise ArgumentError, "noop must be true or false!" unless tf == true || tf == false
      @noop = tf
    end
    
    def tag=(args)
      if args.kind_of?(Array)
        args.each do |t|
          @tag << t
        end
      else
        @tag << args
      end
      @tag
    end
    
    def run(ourblock)
      ourblock.call
    end
  
    def valid?()
      return false unless self.name
      true
    end
  end
end