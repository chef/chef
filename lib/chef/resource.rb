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
require 'chef/dsl/platform_introspection'
require 'chef/dsl/data_query'
require 'chef/dsl/registry_helper'
require 'chef/dsl/reboot_pending'
require 'chef/mixin/convert_to_class_name'
require 'chef/guard_interpreter/resource_guard_interpreter'
require 'chef/resource/conditional'
require 'chef/resource/conditional_action_not_nothing'
require 'chef/resource_collection'
require 'chef/node_map'
require 'chef/node'
require 'chef/platform'
require 'chef/resource/resource_notification'

require 'chef/mixin/deprecation'
require 'chef/mixin/descendants_tracker'

class Chef
  class Resource

    FORBIDDEN_IVARS = [:@run_context, :@not_if, :@only_if, :@enclosing_provider]
    HIDDEN_IVARS = [:@allowed_actions, :@resource_name, :@source_line, :@run_context, :@name, :@not_if, :@only_if, :@elapsed_time, :@enclosing_provider]

    include Chef::DSL::DataQuery
    include Chef::Mixin::ParamsValidate
    include Chef::DSL::PlatformIntrospection
    include Chef::DSL::RegistryHelper
    include Chef::DSL::RebootPending
    include Chef::Mixin::ConvertToClassName
    include Chef::Mixin::Deprecation

    extend Chef::Mixin::ConvertToClassName
    extend Chef::Mixin::DescendantsTracker

    if Module.method(:const_defined?).arity == 1
      def self.strict_const_defined?(const)
        const_defined?(const)
      end
    else
      def self.strict_const_defined?(const)
        const_defined?(const, false)
      end
    end

    class << self
      # back-compat
      # NOTE: that we do not support unregistering classes as descendents like
      # we used to for LWRP unloading because that was horrible and removed in
      # Chef-12.
      alias :resource_classes :descendants
      alias :find_subclass_by_name :find_descendants_by_name
    end

    # Set or return the list of "state attributes" implemented by the Resource
    # subclass. State attributes are attributes that describe the desired state
    # of the system, such as file permissions or ownership. In general, state
    # attributes are attributes that could be populated by examining the state
    # of the system (e.g., File.stat can tell you the permissions on an
    # existing file). Contrarily, attributes that are not "state attributes"
    # usually modify the way Chef itself behaves, for example by providing
    # additional options for a package manager to use when installing a
    # package.
    #
    # This list is used by the Chef client auditing system to extract
    # information from resources to describe changes made to the system.
    def self.state_attrs(*attr_names)
      @state_attrs ||= []
      @state_attrs = attr_names unless attr_names.empty?

      # Return *all* state_attrs that this class has, including inherited ones
      if superclass.respond_to?(:state_attrs)
        superclass.state_attrs + @state_attrs
      else
        @state_attrs
      end
    end

    # Set or return the "identity attribute" for this resource class. This is
    # generally going to be the "name attribute" for this resource. In other
    # words, the resource type plus this attribute uniquely identify a given
    # bit of state that chef manages. For a File resource, this would be the
    # path, for a package resource, it will be the package name. This will show
    # up in chef-client's audit records as a searchable field.
    def self.identity_attr(attr_name=nil)
      @identity_attr ||= nil
      @identity_attr = attr_name if attr_name

      # If this class doesn't have an identity attr, we'll defer to the superclass:
      if @identity_attr || !superclass.respond_to?(:identity_attr)
        @identity_attr
      else
        superclass.identity_attr
      end
    end

    def self.dsl_name
      convert_to_snake_case(name, 'Chef::Resource')
    end

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
    attr_accessor :declared_type

    attr_reader :updated

    attr_reader :resource_name
    attr_reader :not_if_args
    attr_reader :only_if_args

    attr_reader :elapsed_time

    attr_reader :default_guard_interpreter

    # Each notify entry is a resource/action pair, modeled as an
    # Struct with a #resource and #action member

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
      @source_line = nil
      # We would like to raise an error when the user gives us a guard
      # interpreter and a ruby_block to the guard. In order to achieve this
      # we need to understand when the user overrides the default guard
      # interpreter. Therefore we store the default separately in a different
      # attribute.
      @guard_interpreter = nil
      @default_guard_interpreter = :default
      @elapsed_time = 0
      @sensitive = false
    end

    # Returns a Hash of attribute => value for the state attributes declared in
    # the resource's class definition.
    def state
      self.class.state_attrs.inject({}) do |state_attrs, attr_name|
        state_attrs[attr_name] = send(attr_name)
        state_attrs
      end
    end

    # Returns the value of the identity attribute, if declared. Falls back to
    # #name if no identity attribute is declared.
    def identity
      if identity_attr = self.class.identity_attr
        send(identity_attr)
      else
        name
      end
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

    def load_prior_resource(resource_type, instance_name)
      begin
        key = "#{resource_type}[#{instance_name}]"
        prior_resource = run_context.resource_collection.lookup(key)
        # if we get here, there is a prior resource (otherwise we'd have jumped
        # to the rescue clause).
        Chef::Log.warn("Cloning resource attributes for #{key} from prior resource (CHEF-3694)")
        Chef::Log.warn("Previous #{prior_resource}: #{prior_resource.source_line}") if prior_resource.source_line
        Chef::Log.warn("Current  #{self}: #{self.source_line}") if self.source_line
        prior_resource.instance_variables.each do |iv|
          unless iv.to_sym == :@source_line || iv.to_sym == :@action || iv.to_sym == :@not_if || iv.to_sym == :@only_if
            self.instance_variable_set(iv, prior_resource.instance_variable_get(iv))
          end
        end
        true
      rescue Chef::Exceptions::ResourceNotFound
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
      if !name.nil?
        raise ArgumentError, "name must be a string!" unless name.kind_of?(String)
        @name = name
      end
      @name
    end

    def noop(tf=nil)
      if !tf.nil?
        raise ArgumentError, "noop must be true or false!" unless tf == true || tf == false
        @noop = tf
      end
      @noop
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

    def sensitive(arg=nil)
      set_or_return(
        :sensitive,
        arg,
        :kind_of => [ TrueClass, FalseClass ]
      )
    end

    def epic_fail(arg=nil)
      ignore_failure(arg)
    end

    def guard_interpreter(arg=nil)
      if arg.nil?
        @guard_interpreter || @default_guard_interpreter
      else
        set_or_return(
          :guard_interpreter,
          arg,
          :kind_of => Symbol
        )
      end
    end

    # Sets up a notification from this resource to the resource specified by +resource_spec+.
    def notifies(action, resource_spec, timing=:delayed)
      # when using old-style resources(:template => "/foo.txt") style, you
      # could end up with multiple resources.
      validate_resource_spec!(resource_spec)

      resources = [ resource_spec ].flatten
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
      run_context.immediate_notifications(self).each { |n|
        n.resolve_resource_reference(run_context.resource_collection)
      }
      run_context.delayed_notifications(self).each {|n|
        n.resolve_resource_reference(run_context.resource_collection)
      }
    end

    def notifies_immediately(action, resource_spec)
      run_context.notifies_immediately(Notification.new(resource_spec, action, self))
    end

    def notifies_delayed(action, resource_spec)
      run_context.notifies_delayed(Notification.new(resource_spec, action, self))
    end

    def immediate_notifications
      run_context.immediate_notifications(self)
    end

    def delayed_notifications
      run_context.delayed_notifications(self)
    end

    def resources(*args)
      run_context.resource_collection.find(*args)
    end

    def subscribes(action, resources, timing=:delayed)
      resources = [resources].flatten
      resources.each do |resource|
        if resource.is_a?(String)
          resource = Chef::Resource.new(resource, run_context)
        end
        if resource.run_context.nil?
          resource.run_context = run_context
        end
        resource.notifies(action, self, timing)
      end
      true
    end

    def validate_resource_spec!(resource_spec)
      run_context.resource_collection.validate_lookup_spec!(resource_spec)
    end

    def is(*args)
      if args.size == 1
        args.first
      else
        return *args
      end
    end

    # We usually want to store and reference resources by their declared type and not the actual type that
    # was looked up by the Resolver (IE, "package" becomes YumPackage class).  If we have not been provided
    # the declared key we want to fall back on the old to_s key.
    def declared_key
      return to_s if declared_type.nil?
      "#{declared_type}[#{@name}]"
    end

    def to_s
      "#{@resource_name}[#{@name}]"
    end

    def to_text
      return "suppressed sensitive resource output" if sensitive
      ivars = instance_variables.map { |ivar| ivar.to_sym } - HIDDEN_IVARS
      text = "# Declared in #{@source_line}\n\n"
      text << self.class.dsl_name + "(\"#{name}\") do\n"
      ivars.each do |ivar|
        if (value = instance_variable_get(ivar)) && !(value.respond_to?(:empty?) && value.empty?)
          value_string = value.respond_to?(:to_text) ? value.to_text : value.inspect
          text << "  #{ivar.to_s.sub(/^@/,'')} #{value_string}\n"
        end
      end
      [@not_if, @only_if].flatten.each do |conditional|
        text << "  #{conditional.to_text}\n"
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
      {
        'json_class' => self.class.name,
        'instance_vars' => instance_vars
      }
    end

    # Serialize this object as a hash
    def to_json(*a)
      results = as_json
      Chef::JSONCompat.to_json(results, *a)
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
        @only_if << Conditional.only_if(self, command, opts, &block)
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
        @not_if << Conditional.not_if(self, command, opts, &block)
      end
      @not_if
    end

    def defined_at
      # The following regexp should match these two sourceline formats:
      #   /some/path/to/file.rb:80:in `wombat_tears'
      #   C:/some/path/to/file.rb:80 in 1`wombat_tears'
      # extracting the path to the source file and the line number.
      (file, line_no) = source_line.match(/(.*):(\d+):?.*$/).to_a[1,2] if source_line
      if cookbook_name && recipe_name && source_line
        "#{cookbook_name}::#{recipe_name} line #{line_no}"
      elsif source_line
        "#{file} line #{line_no}"
      else
        "dynamically defined"
      end
    end

    def cookbook_version
      if cookbook_name
        run_context.cookbook_collection[cookbook_name]
      end
    end

    def events
      run_context.events
    end

    def run_action(action, notification_type=nil, notifying_resource=nil)
      # reset state in case of multiple actions on the same resource.
      @elapsed_time = 0
      start_time = Time.now
      events.resource_action_start(self, action, notification_type, notifying_resource)
      # Try to resolve lazy/forward references in notifications again to handle
      # the case where the resource was defined lazily (ie. in a ruby_block)
      resolve_notification_references
      validate_action(action)

      if Chef::Config[:verbose_logging] || Chef::Log.level == :debug
        # This can be noisy
        Chef::Log.info("Processing #{self} action #{action} (#{defined_at})")
      end

      # ensure that we don't leave @updated_by_last_action set to true
      # on accident
      updated_by_last_action(false)

      # Don't modify @retries directly and keep it intact, so that the
      # recipe_snippet from ResourceFailureInspector can print the value
      # that was set in the resource block initially.
      remaining_retries = retries

      begin
        return if should_skip?(action)
        provider_for_action(action).run_action
      rescue Exception => e
        if ignore_failure
          Chef::Log.error("#{custom_exception_message(e)}; ignore_failure is set, continuing")
          events.resource_failed(self, action, e)
        elsif remaining_retries > 0
          events.resource_failed_retriable(self, action, remaining_retries, e)
          remaining_retries -= 1
          Chef::Log.info("Retrying execution of #{self}, #{remaining_retries} attempt(s) left")
          sleep retry_delay
          retry
        else
          events.resource_failed(self, action, e)
          raise customize_exception(e)
        end
      ensure
        @elapsed_time = Time.now - start_time
        # Reporting endpoint doesn't accept a negative resource duration so set it to 0.
        # A negative value can occur when a resource changes the system time backwards
        @elapsed_time = 0 if @elapsed_time < 0
        events.resource_completed(self)
      end
    end

    def validate_action(action)
      raise ArgumentError, "nil is not a valid action for resource #{self}" if action.nil?
    end

    def provider_for_action(action)
      provider = Chef::ProviderResolver.new(node, self, action).resolve.new(self, run_context)
      provider.action = action
      provider
    end

    def custom_exception_message(e)
      "#{self} (#{defined_at}) had an error: #{e.class.name}: #{e.message}"
    end

    def customize_exception(e)
      new_exception = e.exception(custom_exception_message(e))
      new_exception.set_backtrace(e.backtrace)
      new_exception
    end
    # Evaluates not_if and only_if conditionals. Returns a falsey value if any
    # of the conditionals indicate that this resource should be skipped, i.e.,
    # if an only_if evaluates to false or a not_if evaluates to true.
    #
    # If this resource should be skipped, returns the first conditional that
    # "fails" its check. Subsequent conditionals are not evaluated, so in
    # general it's not a good idea to rely on side effects from not_if or
    # only_if commands/blocks being evaluated.
    #
    # Also skips conditional checking when the action is :nothing
    def should_skip?(action)
      conditional_action = ConditionalActionNotNothing.new(action)

      conditionals = [ conditional_action ] + only_if + not_if
      conditionals.find do |conditional|
        if conditional.continue?
          false
        else
          events.resource_skipped(self, action, conditional)
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

    def self.node_map
      @@node_map ||= NodeMap.new
    end

    # Maps a short_name (and optionally a platform  and version) to a
    # Chef::Resource.  This allows finer grained per platform resource
    # attributes and the end of overloaded resource definitions
    # (I'm looking at you Chef::Resource::Package)
    # Ex:
    #   class WindowsFile < Chef::Resource
    #     provides :file, os: "linux", platform_family: "rhel", platform: "redhat"
    #     provides :file, os: "!windows
    #     provides :file, os: [ "linux", "aix" ]
    #     provides :file, os: "solaris2" do |node|
    #       node['platform_version'].to_f <= 5.11
    #     end
    #     # ...other stuff
    #   end
    #
    def self.provides(short_name, opts={}, &block)
      short_name_sym = short_name
      if short_name.kind_of?(String)
        # YAGNI: this is probably completely unnecessary and can be removed?
        Chef::Log.warn "[DEPRECATION] Passing a String to Chef::Resource#provides will be removed"
        short_name.downcase!
        short_name.gsub!(/\s/, "_")
        short_name_sym = short_name.to_sym
      end
      node_map.set(short_name_sym, constantize(self.name), opts, &block)
    end

    # Returns a resource based on a short_name and node
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    # node<Chef::Node>:: Node object to look up platform and version in
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    def self.resource_for_node(short_name, node)
      klass = node_map.get(node, short_name) ||
        resource_matching_short_name(short_name)
      raise Chef::Exceptions::NoSuchResourceType.new(short_name, node) if klass.nil?
      klass
    end

    # Returns the class of a Chef::Resource based on the short name
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    def self.resource_matching_short_name(short_name)
      begin
        rname = convert_to_class_name(short_name.to_s)
        Chef::Resource.const_get(rname)
      rescue NameError
        nil
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
  end
end

# We require this at the BOTTOM of this file to avoid circular requires (it is used
# at runtime but not load time)
require 'chef/provider_resolver'
