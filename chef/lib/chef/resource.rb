#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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
#

require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require File.join(File.dirname(__FILE__), "mixin", "check_helper")

class Chef
  class Resource
        
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::ParamsValidate
    
    attr_accessor :actions, :params, :provider, :updated, :allowed_actions, :collection, :cookbook_name, :recipe_name
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
      @supports = {}
      @ignore_failure = false
      sline = caller(4).shift
      if sline
        @source_line = sline.gsub!(/^(.+):(.+):.+$/, '\1 line \2')
        @source_line = ::File.expand_path(@source_line) if @source_line
      end
    end
    
    def supports(args={})
      if args.any?
        @supports = args
      else
        @supports
      end
    end
    
    def provider(arg=nil)
      set_or_return(
        :provider,
        arg,
        :kind_of => [ Class ]
      )
    end
    
    def action(arg=nil)
      if arg
        action_list = arg.kind_of?(Array) ? arg : [ arg ]
        action_list = action_list.collect { |a| a.to_sym }
        action_list.each do |action|
          validate(
            {
              :action => action,
            },
            {
              :action => { :kind_of => Symbol, :equal_to => @allowed_actions },
            }
          )
        end
        @action = action_list
      else
        @action
      end
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
    
    def ignore_failure(arg=nil)
      set_or_return(
        :ignore_failure,
        arg,
        :kind_of => [ TrueClass, FalseClass ]
      )
    end
    
    def epic_fail(arg=nil)
      ignore_failure(arg)
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
