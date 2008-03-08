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
require 'yaml'

class Marionette
  class Resource
    
    include Marionette::Mixin::GraphResources
    
    attr_accessor :tag, :actions
    attr_reader :name, :noop, :tag, :resource_name, :dg, :deps, :notifies, :subscribes
    
    def initialize(name, dg=nil, deps=nil)
      @name = name
      if dg
        @dg = dg
      else
        @dg = RGL::DirectedAdjacencyGraph.new()
      end
      if deps
        @deps = deps
      else
        @deps = RGL::DirectedAdjacencyGraph.new()
      end
      @tag = [ name.to_s ]
      @noop = nil
      @tag = nil
      @before = nil
      @actions = Hash.new
    end
    
    def name(name=nil)
      set_if_args(@name, name) do
        raise ArgumentError, "name must be a string!" unless name.kind_of?(String)
        @name = name
      end
    end
    
    def noop(tf=nil)
      set_if_args(@noop, tf) do 
        raise ArgumentError, "noop must be true or false!" unless tf == true || tf == false
        @noop = tf
      end
    end
    
    def requires(resources=nil)
      rarray = resources.kind_of?(Array) ? resources : [ resources ]
      rarray.each do |resource|
        @deps.add_vertex(self)
        @deps.add_vertex(resource)
        @deps.add_edge(resource, self)
      end
      true
    end
    
    def before(resources)
      rarray = resources.kind_of?(Array) ? resources : [ resources ]
      rarray.each do |resource|
        @deps.add_vertex(self)
        @deps.add_vertex(resource)
        @deps.add_edge(self, resource)
      end
      true
    end
    
    def notifies(*notify_actions)
      resources = notify_actions.pop
      rarray = resources.kind_of?(Array) ? resources : [ resources ]
      rarray.each do |resource|
        @deps.add_vertex(self)
        @deps.add_vertex(resource)
        @deps.add_edge(self, resource)
        notify_actions.each do |action|
          action_sym = action.to_sym
          if @actions.has_key?(action_sym)
            @actions[action_sym] << resource
          else            
            @actions[action_sym] = [ resource ]
          end
        end
      end
      true
    end
    
    def subscribes(*subscribe_actions)
      resources = subscribe_actions.pop
      rarray = resources.kind_of?(Array) ? resources : [ resources ]
      rarray.each do |resource|
        @deps.add_vertex(self)
        @deps.add_vertex(resource)
        @deps.add_edge(resource, self)
        subscribe_actions.each do |action|
          action_sym = action.to_sym
          if @actions.has_key?(action_sym)
            resource.actions[action_sym] << self
          else            
            resource.actions[action_sym] = [ self ]
          end
        end
      end
      true
    end
    
    def tag(args=nil)
      set_if_args(@tag, args) do       
        if args.kind_of?(Array)
          args.each do |t|
            @tag << t
          end
        else
          @tag << args
        end
        @tag
      end
    end
    
    def to_s
      "#{@resource_name} #{@name}"
    end
  
    def valid?()
      return false unless self.name
      true
    end
    
    private
      def set_if_args(thing, arguments)
        raise ArgumentError, "Must call set_if_args with a block!" unless Kernel.block_given?
        if arguments != nil
          yield(arguments)
        else
          thing
        end
      end
  end
end