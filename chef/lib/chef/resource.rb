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

require 'chef/mixin/deprecation'

class Chef
  class Resource
    class Notification < Struct.new(:resource, :action)
    end

    HIDDEN_IVARS = [:@allowed_actions, :@resource_name, :@source_line, :@run_context, :@name, :@node]

    include Chef::Mixin::CheckHelper
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::Language
    include Chef::Mixin::ConvertToClassName
    include Chef::Mixin::Deprecation
    
    attr_accessor :params, :provider, :updated, :allowed_actions, :run_context, :cookbook_name, :recipe_name, :enclosing_provider
    attr_accessor :source_line
    attr_reader :resource_name, :not_if_args, :only_if_args

    # Each notify entry is a resource/action pair, modeled as an
    # OpenStruct with a .resource and .action member
    attr_reader :notifies_immediate, :notifies_delayed
    
    def initialize(name, run_context=nil)
      @name = name
      @run_context = run_context
      @noop = nil
      @before = nil
      @params = Hash.new
      @provider = nil
      @allowed_actions = [ :nothing ]
      @action = :nothing
      @updated = false
      @supports = {}
      @ignore_failure = false
      @not_if = nil
      @not_if_args = {}
      @only_if = nil
      @only_if_args = {}
      @notifies_immediate = Array.new
      @notifies_delayed = Array.new
      @source_line = nil

      @node = run_context ? deprecated_ivar(run_context.node, :node, :warn) : nil
    end
    
    def node
      run_context && run_context.node
    end

    # If an unknown method is invoked, determine whether the enclosing Provider's
    # lexical scope can fulfill the request. E.g. This happens when the Resource's
    # block invokes new_resource.
    def method_missing(method_symbol, *args, &block)
      if enclosing_provider && enclosing_provider.respond_to?(method_symbol)
        enclosing_provider.send(method_symbol, *args, &block)
      else
        raise NoMethodError, "undefined method `#{method_symbol.to_s}' for #{self.class.to_s}"
      end
    end
    
    def load_prior_resource
      begin
        prior_resource = run_context.resource_collection.lookup(self.to_s)
        Chef::Log.debug("Setting #{self.to_s} to the state of the prior #{self.to_s}")
        prior_resource.instance_variables.each do |iv|
          unless iv.to_sym == :@source_line || iv.to_sym == :@action
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
                lookup_provider_constant(arg)
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
        # This syntax is so weird. surely people will just give us one hash?
        notifications = args.flatten
        notifications.each do |resources_notifications|
          begin
            resources_notifications.each do |resource, notification|
              Chef::Log.error "resource KV: `#{resource.inspect}' => `#{notification.inspect}'"
              notifies_helper(notification[0], resource, notification[1])    
            end
          rescue NoMethodError
            Chef::Log.fatal("encountered NME processing resource #{resources_notifications.inspect}")
            Chef::Log.fatal("incoming args: #{args.inspect}")
            raise
          end
        end 
      end
    end
    
    def resources(*args)
      run_context.resource_collection.resources(*args)
    end
    
    def subscribes(action, resources, timing=:delayed)
      resources = [resources].flatten
      resources.each do |resource|
        resource.notifies(action, self, timing)
      end
      true
    end
    
    def is(*args)
      if args.size == 1
        args.first
      else
        return *args
      end
    end
    
    def to_s
      "#{@resource_name}[#{@name}]"
    end

    def to_text
      ivars = instance_variables.map { |ivar| ivar.to_sym } - HIDDEN_IVARS
      text = "# Declared in #{@source_line}\n"
      text << convert_to_snake_case(self.class.name, 'Chef::Resource') + "(\"#{name}\") do\n"
      ivars.each do |ivar|
        if (value = instance_variable_get(ivar)) && !(value.respond_to?(:empty?) && value.empty?)
          text << "  #{ivar.to_s.sub(/^@/,'')}(#{value.inspect})\n"
        end
      end
      text << "end\n"
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      instance_vars = Hash.new
      self.instance_variables.each do |iv|
        unless iv == "@run_context"
          instance_vars[iv] = self.instance_variable_get(iv) 
        end
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
        key = iv.to_s.sub(/^@/,'').to_sym
        instance_vars[key] = self.instance_variable_get(iv) unless (key == :run_context) || (key == :node)
      end
      instance_vars
    end
    
    def only_if(arg=nil, args = {}, &blk)
      if Kernel.block_given?
        @only_if = blk
        @only_if_args = args
      else
        @only_if = arg if arg
        @only_if_args = args if arg
      end
      @only_if
    end
    
    def not_if(arg=nil, args = {}, &blk)
      if Kernel.block_given?
        @not_if = blk
        @not_if_args = args
      else
        @not_if = arg if arg
        @not_if_args = args if arg
      end
      @not_if
    end
    
    def run_action(action)
      provider = Chef::Platform.provider_for_resource(self)
      provider.load_current_resource
      provider.send("action_#{action}")
    end
    
    def updated?
      updated
    end

    class << self
      
      def json_create(o)
        resource = self.new(o["instance_vars"]["@name"])
        o["instance_vars"].each do |k,v|
          resource.instance_variable_set(k.to_sym, v)
        end
        resource
      end
      
      include Chef::Mixin::ConvertToClassName
      
      def attribute(attr_name, validation_opts={})
        # This atrocity is the only way to support 1.8 and 1.9 at the same time
        # When you're ready to drop 1.8 support, do this:
        # define_method attr_name.to_sym do |arg=nil|
        # etc.
        shim_method=<<-SHIM
        def #{attr_name}(arg=nil)
          _set_or_return_#{attr_name}(arg)
        end
        SHIM
        class_eval(shim_method)
        
        define_method("_set_or_return_#{attr_name.to_s}".to_sym) do |arg|
          set_or_return(attr_name.to_sym, arg, validation_opts)
        end
      end
      
      def build_from_file(cookbook_name, filename)
        rname = filename_to_qualified_string(cookbook_name, filename)

        # Add log entry if we override an existing light-weight resource.
        class_name = convert_to_class_name(rname)
        overriding = Chef::Resource.const_defined?(class_name)
        Chef::Log.info("#{class_name} light-weight resource already initialized -- overriding!") if overriding
          
        new_resource_class = Class.new self do |cls|
          
          # default initialize method that ensures that when initialize is finally
          # wrapped (see below), super is called in the event that the resource
          # definer does not implement initialize
          def initialize(name, run_context)
            super(name, run_context)
          end
          
          @actions_to_create = []
          
          class << cls
            include Chef::Mixin::FromFile
            
            def actions_to_create
              @actions_to_create
            end
            
            define_method(:actions) do |*action_names|
              actions_to_create.push(*action_names)
            end
          end
          
          # load resource definition from file
          cls.class_from_file(filename)
          
          # create a new constructor that wraps the old one and adds the actions
          # specified in the DSL
          old_init = instance_method(:initialize)

          define_method(:initialize) do |name, *optional_args|
            args_run_context = optional_args.shift
            @resource_name = rname.to_sym
            old_init.bind(self).call(name, args_run_context)
            allowed_actions.push(self.class.actions_to_create).flatten!
          end
        end
        
        # register new class as a Chef::Resource
        class_name = convert_to_class_name(rname)
        Chef::Resource.const_set(class_name, new_resource_class)
        Chef::Log.debug("Loaded contents of #{filename} into a resource named #{rname} defined in Chef::Resource::#{class_name}")
        
        new_resource_class
      end
      
      # Resources that want providers namespaced somewhere other than 
      # Chef::Provider can set the namespace with +provider_base+
      # Ex:
      #   class MyResource < Chef::Resource
      #     provider_base Chef::Provider::Deploy
      #     # ...other stuff
      #   end
      def provider_base(arg=nil)
        @provider_base ||= arg
        @provider_base ||= Chef::Provider
      end
      
    end
    
    private
    
      def lookup_provider_constant(name)
        begin
          self.class.provider_base.const_get(convert_to_class_name(name.to_s))
        rescue NameError => e
          if e.to_s =~ /#{Regexp.escape(self.class.provider_base.to_s)}/
            raise ArgumentError, "No provider found to match '#{name}'"
          else
            raise e
          end
        end
      end
      
      def validate_timing(timing)
        timing = timing.to_sym
        raise ArgumentError, "invalid timing: #{timing}; must be one of: :delayed, :immediate, :immediately" unless (timing == :delayed || timing == :immediate || timing == :immediately)
        timing == :immediately ? :immediate : timing
      end
      
      def notifies_helper(action, resources, timing=:delayed)
        timing = validate_timing(timing)
        
        resource_array = [resources].flatten
        resource_array.each do |resource|
          new_notify = Notification.new(resource, action)
          if timing == :delayed
            notifies_delayed << new_notify
          else
            notifies_immediate << new_notify
          end
        end
        
        true
      end
    end
end
