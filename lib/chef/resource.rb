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

require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require File.join(File.dirname(__FILE__), "mixin", "check_helper")
require 'yaml'

class Chef
  class Resource
        
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::ParamsValidate
    
    attr_accessor :actions, :params, :provider, :updated, :allowed_actions, :collection
    attr_reader :resource_name, :source_line, :node
    
    def initialize(name, collection=nil, node=nil)
      @name = name
      if collection
        @collection = collection
      else
        @collection = Chef::ResourceCollection.new()
      end
      @node = node ? node : Chef::Node.new
      @noop = nil
      @before = nil
      @actions = Hash.new
      @params = Hash.new
      @provider = nil
      @allowed_actions = [ :nothing ]
      @action = :nothing
      @updated = false
      @source_line = caller(4).shift.gsub!(/^(.+):(.+):.+$/, '\1 line \2')
    end
    
    def action(arg=nil)
      arg = arg.to_sym if arg
      set_or_return(
        :action,
        arg,
        :equal_to => @allowed_actions
      )
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
    
    def notifies(action, resources, timing=:delayed)
      timing = check_timing(timing)
      rarray = resources.kind_of?(Array) ? resources : [ resources ]
      rarray.each do |resource|
        action_sym = action.to_sym
        if @actions.has_key?(action_sym)
          @actions[action_sym][timing] << resource
        else
          @actions[action_sym] = Hash.new
          @actions[action_sym][:delayed] = Array.new
          @actions[action_sym][:immediate] = Array.new   
          @actions[action_sym][timing] << resource
        end
      end
      true
    end
    
    def resources(*args)
      @collection.resources(*args)
    end
    
    def subscribes(action, resources, timing=:delayed)
      timing = check_timing(timing)
      rarray = resources.kind_of?(Array) ? resources : [ resources ]
      rarray.each do |resource|
        action_sym = action.to_sym
        if resource.actions.has_key?(action_sym)
          resource.actions[action_sym][timing] << self
        else       
          resource.actions[action_sym] = Hash.new
          resource.actions[action_sym][:delayed] = Array.new
          resource.actions[action_sym][:immediate] = Array.new   
          resource.actions[action_sym][timing] << self
        end
      end
      true
    end
    
    def is(*args)
      return *args
    end
    
    def to_s
      "#{@resource_name}[#{@name}]"
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      instance_vars = Hash.new
      self.instance_variables.each do |iv|
        instance_vars[iv] = self.instance_variable_get(iv) unless iv == "@collection"
      end
      results = {
        'json_class' => self.class.name,
        'instance_vars' => instance_vars
      }
      results.to_json(*a)
    end
    
    def self.json_create(o)
      resource = self.new(o["instance_vars"]["@name"])
      o["instance_vars"].each do |k,v|
        resource.instance_variable_set(k.to_sym, v)
      end
      resource
    end
    
    private
      
      def check_timing(timing)
        unless timing == :delayed || timing == :immediate || timing == :immediately
          raise ArgumentError, "Timing must be :delayed or :immediate(ly), you said #{timing}"
        end
        if timing == :immediately
          timing = :immediate
        end
        timing
      end
  end
end