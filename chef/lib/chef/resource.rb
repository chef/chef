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
require 'chef/resource/conditional'
require 'chef/resource_collection'
require 'chef/resource_platform_map'
require 'chef/node'

require 'chef/mixin/deprecation'

class Chef
  class Resource
    class Notification < Struct.new(:resource, :action, :notifying_resource)

      def duplicates?(other_notification)
        unless other_notification.respond_to?(:resource) && other_notification.respond_to?(:action)
          msg = "only duck-types of Chef::Resource::Notification can be checked for duplication "\
                "you gave #{other_notification.inspect}"
          raise ArgumentError, msg
        end
        other_notification.resource == resource && other_notification.action == action
      end

      def resolve_resource_reference(resource_collection)
        return resource if resource.kind_of?(Chef::Resource)

        matching_resource = resource_collection.find(resource)
        if Array(matching_resource).size > 1
          msg = "Notification #{self} from #{notifying_resource} was created with a reference to multiple resources, "\
                "but can only notify one resource. Notifying resource was defined on #{notifying_resource.source_line}"
          raise Chef::Exceptions::InvalidResourceReference, msg
        end
        self.resource = matching_resource
      rescue Chef::Exceptions::ResourceNotFound => e
        err = Chef::Exceptions::ResourceNotFound.new(<<-FAIL)
Resource #{notifying_resource} is configured to notify resource #{resource} with action #{action}, \
but #{resource} cannot be found in the resource collection. #{notifying_resource} is defined in \
#{notifying_resource.source_line}
FAIL
        err.set_backtrace(e.backtrace)
        raise err
      rescue Chef::Exceptions::InvalidResourceSpecification => e
          err = Chef::Exceptions::InvalidResourceSpecification.new(<<-F)
Resource #{notifying_resource} is configured to notify resource #{resource} with action #{action}, \
but #{resource.inspect} is not valid syntax to look up a resource in the resource collection. Notification \
is defined near #{notifying_resource.source_line}
F
          err.set_backtrace(e.backtrace)
        raise err
      end

    end

    FORBIDDEN_IVARS = [:@run_context, :@node, :@not_if, :@only_if]
    HIDDEN_IVARS = [:@allowed_actions, :@resource_name, :@source_line, :@run_context, :@name, :@node]

    include Chef::Mixin::CheckHelper
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::Language
    include Chef::Mixin::ConvertToClassName
    include Chef::Mixin::Deprecation

    attr_accessor :params
    attr_accessor :provider
    attr_accessor :allowed_actions
    attr_accessor :run_context
    attr_accessor :cookbook_name
    attr_accessor :recipe_name
    attr_accessor :enclosing_provider
    attr_accessor :source_line
    attr_accessor :retries
    attr_accessor :retry_delay

    attr_reader :updated

    attr_reader :resource_name
    attr_reader :not_if_args
    attr_reader :only_if_args

    # Each notify entry is a resource/action pair, modeled as an
    # Struct with a #resource and #action member
    attr_reader :immediate_notifications
    attr_reader :delayed_notifications

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
      @updated_by_last_action = false
      @supports = {}
      @ignore_failure = false
      @retries = 0
      @retry_delay = 2
      @not_if = []
      @only_if = []
      @immediate_notifications = Array.new
      @delayed_notifications = Array.new
      @source_line = nil

      @node = run_context ? deprecated_ivar(run_context.node, :node, :warn) : nil
    end

    def updated=(true_or_false)
      Chef::Log.warn("Chef::Resource#updated=(true|false) is deprecated. Please call #updated_by_last_action(true|false) instead.")
      Chef::Log.warn("Called from:")
      caller[0..3].each {|line| Chef::Log.warn(line)}
      updated_by_last_action(true_or_false)
      @updated = true_or_false
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
      rescue Chef::Exceptions::ResourceNotFound => e
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

    def retries(arg=nil)
      set_or_return(
        :retries,
        arg,
        :kind_of => Integer
      )
    end

    def retry_delay(arg=nil)
      set_or_return(
        :retry_delay,
        arg,
        :kind_of => Integer
      )
    end

    def epic_fail(arg=nil)
      ignore_failure(arg)
    end

    def notifies(*args)
      unless ( args.size > 0 && args.size < 4)
        raise ArgumentError, "Wrong number of arguments for notifies: should be 1-3 arguments, you gave #{args.inspect}"
      end

      if args.size > 1 # notifies(:action, resource) OR notifies(:action, resource, :immediately)
        add_notification(*args)
      else
        # This syntax is so weird. surely people will just give us one hash?
        notifications = args.flatten
        notifications.each do |resources_notifications|
          resources_notifications.each do |resource, notification|
            action, timing = notification[0], notification[1]
            Chef::Log.debug "Adding notification from resource #{self} to `#{resource.inspect}' => `#{notification.inspect}'"
            add_notification(action, resource, timing)
          end
        end
      end
    rescue NoMethodError
      Chef::Log.fatal("Error processing notifies(#{args.inspect}) on #{self}")
      raise
    end

    def add_notification(action, resources, timing=:delayed)
      resources = [resources].flatten
      resources.each do |resource|
        case timing.to_s
        when 'delayed'
          notifies_delayed(action, resource)
        when 'immediate', 'immediately'
          notifies_immediately(action, resource)
        else
          raise ArgumentError,  "invalid timing: #{timing} for notifies(#{action}, #{resources.inspect}, #{timing}) resource #{self} "\
                                "Valid timings are: :delayed, :immediate, :immediately"
        end
      end

      true
    end

    # Iterates over all immediate and delayed notifications, calling
    # resolve_resource_reference on each in turn, causing them to
    # resolve lazy/forward references.
    def resolve_notification_references
      @immediate_notifications.each { |n| n.resolve_resource_reference(run_context.resource_collection) }
      @delayed_notifications.each {|n| n.resolve_resource_reference(run_context.resource_collection) }
    end

    def notifies_immediately(action, resource_spec)
      @immediate_notifications << Notification.new(resource_spec, action, self)
    end

    def notifies_delayed(action, resource_spec)
      @delayed_notifications << Notification.new(resource_spec, action, self)
    end

    def resources(*args)
      run_context.resource_collection.find(*args)
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

    def inspect
      ivars = instance_variables.map { |ivar| ivar.to_sym } - FORBIDDEN_IVARS
      ivars.inject("<#{to_s}") do |str, ivar|
        str << " #{ivar}: #{instance_variable_get(ivar).inspect}"
      end << ">"
    end

    # as_json does most of the to_json heavy lifted. It exists here in case activesupport
    # is loaded. activesupport will call as_json and skip over to_json. This ensure
    # json is encoded as expected
    def as_json(*a)
      safe_ivars = instance_variables.map { |ivar| ivar.to_sym } - FORBIDDEN_IVARS
      instance_vars = Hash.new
      safe_ivars.each do |iv|
        instance_vars[iv.to_s.sub(/^@/, '')] = instance_variable_get(iv)
      end
      results = {
        'json_class' => self.class.name,
        'instance_vars' => instance_vars
      }
    end

    # Serialize this object as a hash
    def to_json(*a)
      results = as_json
      results.to_json(*a)
    end

    def to_hash
      safe_ivars = instance_variables.map { |ivar| ivar.to_sym } - FORBIDDEN_IVARS
      instance_vars = Hash.new
      safe_ivars.each do |iv|
        key = iv.to_s.sub(/^@/,'').to_sym
        instance_vars[key] = instance_variable_get(iv)
      end
      instance_vars
    end

    # If command is a block, returns true if the block returns true, false if it returns false.
    # ("Only run this resource if the block is true")
    #
    # If the command is not a block, executes the command.  If it returns any status other than
    # 0, it returns false (clearly, a 0 status code is true)
    #
    # === Parameters
    # command<String>:: A a string to execute.
    # opts<Hash>:: Options control the execution of the command
    # block<Proc>:: A ruby block to run. Ignored if a command is given.
    #
    # === Evaluation
    # * evaluates to true if the block is true, or if the command returns 0
    # * evaluates to false if the block is false, or if the command returns a non-zero exit code.
    def only_if(command=nil, opts={}, &block)
      if command || block_given?
        @only_if << Conditional.only_if(command, opts, &block)
      end
      @only_if
    end

    # If command is a block, returns false if the block returns true, true if it returns false.
    # ("Do not run this resource if the block is true")
    #
    # If the command is not a block, executes the command.  If it returns a 0 exitstatus, returns false.
    # ("Do not run this resource if the command returns 0")
    #
    # === Parameters
    # command<String>:: A a string to execute.
    # opts<Hash>:: Options control the execution of the command
    # block<Proc>:: A ruby block to run. Ignored if a command is given.
    #
    # === Evaluation
    # * evaluates to true if the block is false, or if the command returns a non-zero exit status.
    # * evaluates to false if the block is true, or if the command returns a 0 exit status.
    def not_if(command=nil, opts={}, &block)
      if command || block_given?
        @not_if << Conditional.not_if(command, opts, &block)
      end
      @not_if
    end

    def defined_at
      if cookbook_name && recipe_name && source_line
        "#{cookbook_name}::#{recipe_name} line #{source_line.split(':')[1]}"
      elsif source_line
        file, line_no = source_line.split(':')
        "#{file} line #{line_no}"
      else
        "dynamically defined"
      end
    end

    def run_action(action)
      if Chef::Config[:verbose_logging] || Chef::Log.level == :debug
        # This can be noisy
        Chef::Log.info("Processing #{self} action #{action} (#{defined_at})")
      end

      # ensure that we don't leave @updated_by_last_action set to true
      # on accident
      updated_by_last_action(false)

      begin
        return if should_skip?
        # leverage new platform => short_name => resource
        # which requires explicitly setting provider in
        # resource class
        if self.provider
          provider = self.provider.new(self, self.run_context)
        else # fall back to old provider resolution
          provider = Chef::Platform.provider_for_resource(self)
        end
        provider.run_action(action)
      rescue => e
        if ignore_failure
          Chef::Log.error("#{self} (#{defined_at}) had an error: #{e.message}")
        else
          Chef::Log.error("#{self} (#{defined_at}) has had an error")
          new_exception = e.exception("#{self} (#{defined_at}) had an error: #{e.class.name}: #{e.message}")
          new_exception.set_backtrace(e.backtrace)
          raise new_exception
        end
      end
    end

    # Evaluates not_if and only_if conditionals. Returns a falsey value if any
    # of the conditionals indicate that this resource should be skipped, i.e.,
    # if an only_if evaluates to false or a not_if evaluates to true.
    #
    # If this resource should be skipped, returns the first conditional that
    # "fails" its check. Subsequent conditionals are not evaluated, so in
    # general it's not a good idea to rely on side effects from not_if or
    # only_if commands/blocks being evaluated.
    def should_skip?
      conditionals = only_if + not_if
      return false if conditionals.empty?

      conditionals.find do |conditional|
        if conditional.continue?
          false
        else
          Chef::Log.debug("Skipping #{self} due to #{conditional.description}")
          true
        end
      end
    end

    def updated_by_last_action(true_or_false)
      @updated ||= true_or_false
      @updated_by_last_action = true_or_false
    end

    def updated_by_last_action?
      @updated_by_last_action
    end

    def updated?
      updated
    end

    def self.json_create(o)
      resource = self.new(o["instance_vars"]["@name"])
      o["instance_vars"].each do |k,v|
        resource.instance_variable_set("@#{k}".to_sym, v)
      end
      resource
    end

    # Hook to allow a resource to run specific code after creation
    def after_created
      nil
    end

    extend Chef::Mixin::ConvertToClassName

    def self.attribute(attr_name, validation_opts={})
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

    def self.build_from_file(cookbook_name, filename, run_context)
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

          attr_accessor :run_context
          attr_reader :action_to_set_default

          def node
            self.run_context.node
          end

          def actions_to_create
            @actions_to_create
          end

          define_method(:default_action) do |action_name|
            actions_to_create.push(action_name)
            @action_to_set_default = action_name
          end

          define_method(:actions) do |*action_names|
            actions_to_create.push(*action_names)
          end
        end

        # set the run context in the class instance variable
        cls.run_context = run_context

        # load resource definition from file
        cls.class_from_file(filename)

        # create a new constructor that wraps the old one and adds the actions
        # specified in the DSL
        old_init = instance_method(:initialize)

        define_method(:initialize) do |name, *optional_args|
          args_run_context = optional_args.shift
          @resource_name = rname.to_sym
          old_init.bind(self).call(name, args_run_context)
          @action = self.class.action_to_set_default || @action
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
    def self.provider_base(arg=nil)
      @provider_base ||= arg
      @provider_base ||= Chef::Provider
    end

    def self.platform_map
      @@platform_map ||= PlatformMap.new
    end

    # Maps a short_name (and optionally a platform  and version) to a
    # Chef::Resource.  This allows finer grained per platform resource
    # attributes and the end of overloaded resource definitions
    # (I'm looking at you Chef::Resource::Package)
    # Ex:
    #   class WindowsFile < Chef::Resource
    #     provides :file, :on_platforms => ["windows"]
    #     # ...other stuff
    #   end
    #
    # TODO: 2011-11-02 schisamo - platform_version support
    def self.provides(short_name, opts={})
      short_name_sym = short_name
      if short_name.kind_of?(String)
        short_name.downcase!
        short_name.gsub!(/\s/, "_")
        short_name_sym = short_name.to_sym
      end
      if opts.has_key?(:on_platforms)
        platforms = [opts[:on_platforms]].flatten
        platforms.each do |p|
          p = :default if :all == p.to_sym
          platform_map.set(
            :platform => p.to_sym,
            :short_name => short_name_sym,
            :resource => self
          )
        end
      else
        platform_map.set(
          :short_name => short_name_sym,
          :resource => self
        )
      end
    end

    # Returns a resource based on a short_name anda platform and version.
    #
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    # platform<Symbol,String>:: platform name
    # version<String>:: platform version
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    def self.resource_for_platform(short_name, platform=nil, version=nil)
      platform_map.get(short_name, platform, version)
    end

    # Returns a resource based on a short_name and a node's
    # platform and version.
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    # node<Chef::Node>:: Node object to look up platform and version in
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    def self.resource_for_node(short_name, node)
      begin
        platform, version = Chef::Platform.find_platform_and_version(node)
      rescue ArgumentError
      end
      resource = resource_for_platform(short_name, platform, version)
      resource
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

  end
end
