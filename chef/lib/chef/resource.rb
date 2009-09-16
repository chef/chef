#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/mixin/params_validate'
require 'chef/mixin/check_helper'
require 'chef/mixin/language'
require 'chef/mixin/convert_to_class_name'
require 'chef/resource_collection'
require 'chef/node'

class Chef
  class Resource
        
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::Language
    include Chef::Mixin::ConvertToClassName
    
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
      @not_if = nil
      @only_if = nil
      sline = caller(4).shift
      if sline
        @source_line = sline.gsub!(/^(.+):(.+):.+$/, '\1 line \2')
        @source_line = ::File.expand_path(@source_line) if @source_line
      end
    end
    
    def load_prior_resource
      begin
        prior_resource = @collection.lookup(self.to_s)
        Chef::Log.debug("Setting #{self.to_s} to the state of the prior #{self.to_s}")
        prior_resource.instance_variables.each do |iv|
          unless iv == "@source_line" || iv == "@action"
            self.instance_variable_set(iv, prior_resource.instance_variable_get(iv))
          end
        end
        true
      rescue ArgumentError => e
        true
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
      klass = if arg.kind_of?(String) || arg.kind_of?(Symbol)
                begin
                  Chef::Provider.const_get(convert_to_class_name(arg.to_s))
                rescue NameError => e
                  raise ArgumentError, "Undefined provider for #{arg}"
                end
              else
                arg
              end
      set_or_return(
        :provider,
        klass,
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
    
    def notifies(*args)
      raise ArgumentError, "Wrong number of arguments (should be 1, 2, or 3)" unless ( args.size > 0 && args.size < 4)
      if args.size > 1
        notifies_helper(*args)
      else
        resources_array = *args
        resources_array.each do |resource|
          resource.each do |key, value|
            notifies_helper(value[0], key, value[1])    
          end
        end 
      end
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
    
    def to_hash
      instance_vars = Hash.new
      self.instance_variables.each do |iv|
        instance_vars[iv.sub(/^@/,'').to_sym] = self.instance_variable_get(iv) unless iv == "@collection"
      end
      instance_vars
    end
    
    def only_if(arg=nil, &blk)
      if Kernel.block_given?
        @only_if = blk
      else
        @only_if = arg if arg
      end
      @only_if
    end
    
    def not_if(arg=nil, &blk)
      if Kernel.block_given?
        @not_if = blk
      else
        @not_if = arg if arg
      end
      @not_if
    end
    
    def run_action(action)
      provider = Chef::Platform.provider_for_node(@node, self)
      provider.load_current_resource
      provider.send("action_#{action}")
    end
    
    class << self
      def json_create(o)
        resource = self.new(o["instance_vars"]["@name"])
        o["instance_vars"].each do |k,v|
          resource.instance_variable_set(k.to_sym, v)
        end
        resource
      end
      
      def build_from_file(filename)
        Class.new self do |cls|
          
          # default initialize method that ensures that when initialize is finally
          # wrapped (see below), super is called in the event that the resource
          # definer does not implement initialize
          def initialize(name, collection=nil, node=nil)
            super(name, collection, node)
          end
          
          @actions_to_create = []
          
          class << cls
            include Chef::Mixin::FromFile
            
            def actions_to_create
              @actions_to_create
            end
            
            def actions_to_create=(val)
              @actions_to_create = val
            end
            
            define_method(:actions) do |*action_names|
              actions_to_create.push(*action_names)
            end
            
            def attribute(attr_name, validation_opts={})
              define_method(attr_name.to_sym) do |arg|
                set_or_return(attr_name.to_sym, arg, validation_opts)
              end
            end
          end
          
          # load resource definition from file
          cls.class_from_file(filename)
          
          # create a new constructor that wraps the old one and adds the actions
          # specified in the DSL
          old_init = instance_method(:initialize)
          
          define_method(:initialize) do |name, *optional_args|
            collection = optional_args.shift
            node = optional_args.shift
            old_init.bind(self).call(name, collection, node)
            allowed_actions.push(self.class.actions_to_create).flatten!
          end
          
        end
      end
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
      
      def notifies_helper(action, resources, timing=:delayed)
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
  end
end
