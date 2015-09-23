#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: John Keiser (<jkeiser@chef.io)
# Copyright:: Copyright (c) 2008-2015 Chef, Inc.
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

require 'chef/exceptions'
require 'chef/mixin/params_validate'
require 'chef/dsl/platform_introspection'
require 'chef/dsl/data_query'
require 'chef/dsl/registry_helper'
require 'chef/dsl/reboot_pending'
require 'chef/dsl/resources'
require 'chef/mixin/convert_to_class_name'
require 'chef/guard_interpreter/resource_guard_interpreter'
require 'chef/resource/conditional'
require 'chef/resource/conditional_action_not_nothing'
require 'chef/resource/action_class'
require 'chef/resource_collection'
require 'chef/node_map'
require 'chef/node'
require 'chef/platform'
require 'chef/resource/resource_notification'
require 'chef/provider_resolver'
require 'chef/resource_resolver'
require 'set'

require 'chef/mixin/deprecation'
require 'chef/mixin/provides'
require 'chef/mixin/shell_out'
require 'chef/mixin/powershell_out'

class Chef
  class Resource

    #
    # Generic User DSL (not resource-specific)
    #

    include Chef::DSL::DataQuery
    include Chef::DSL::PlatformIntrospection
    include Chef::DSL::RegistryHelper
    include Chef::DSL::RebootPending
    extend Chef::Mixin::Provides

    # This lets user code do things like `not_if { shell_out!("command") }`
    include Chef::Mixin::ShellOut
    include Chef::Mixin::PowershellOut

    #
    # The node the current Chef run is using.
    #
    # Corresponds to `run_context.node`.
    #
    # @return [Chef::Node] The node the current Chef run is using.
    #
    def node
      run_context && run_context.node
    end

    #
    # Find existing resources by searching the list of existing resources.  Possible
    # forms are:
    #
    #   find(:file => "foobar")
    #   find(:file => [ "foobar", "baz" ])
    #   find("file[foobar]", "file[baz]")
    #   find("file[foobar,baz]")
    #
    # Calls `run_context.resource_collection.find(*args)`
    #
    # @return the matching resource, or an Array of matching resources.
    #
    # @raise ArgumentError if you feed it bad lookup information
    # @raise RuntimeError if it can't find the resources you are looking for.
    #
    def resources(*args)
      run_context.resource_collection.find(*args)
    end

    #
    # Resource User Interface (for users)
    #

    #
    # Create a new Resource.
    #
    # @param name The name of this resource (corresponds to the #name attribute,
    #   used for notifications to this resource).
    # @param run_context The context of the Chef run. Corresponds to #run_context.
    #
    def initialize(name, run_context=nil)
      name(name) unless name.nil?
      @run_context = run_context
      @noop = nil
      @before = nil
      @params = Hash.new
      @provider = nil
      @allowed_actions = self.class.allowed_actions.to_a
      @action = self.class.default_action
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

    #
    # The list of properties defined on this resource.
    #
    # Everything defined with `property` is in this list.
    #
    # @param include_superclass [Boolean] `true` to include properties defined
    #   on superclasses; `false` or `nil` to return the list of properties
    #   directly on this class.
    #
    # @return [Hash<Symbol,Property>] The list of property names and types.
    #
    def self.properties(include_superclass=true)
      @properties ||= {}
      if include_superclass
        if superclass.respond_to?(:properties)
          superclass.properties.merge(@properties)
        else
          @properties.dup
        end
      else
        @properties
      end
    end

    #
    # The action or actions that will be taken when this resource is run.
    #
    # @param arg [Array[Symbol], Symbol] A list of actions (e.g. `:create`)
    # @return [Array[Symbol]] the list of actions.
    #
    def action(arg=nil)
      if arg
        arg = Array(arg).map(&:to_sym)
        arg.each do |action|
          validate(
            { action: action },
            { action: { kind_of: Symbol, equal_to: allowed_actions } }
          )
        end
        @action = arg
      else
        @action
      end
    end

    # Alias for normal assigment syntax.
    alias_method :action=, :action

    #
    # Sets up a notification that will run a particular action on another resource
    # if and when *this* resource is updated by an action.
    #
    # If the action does not update this resource, the notification never triggers.
    #
    # Only one resource may be specified per notification.
    #
    # `delayed` notifications will only *ever* happen once per resource, so if
    # multiple resources all notify a single resource to perform the same action,
    # the action will only happen once.  However, if they ask for different
    # actions, each action will happen once, in the order they were updated.
    #
    # `immediate` notifications will cause the action to be triggered once per
    # notification, regardless of how many other resources have triggered the
    # notification as well.
    #
    # @param action The action to run on the other resource.
    # @param resource_spec [String, Hash, Chef::Resource] The resource to run.
    # @param timing [String, Symbol] When to notify.  Has these values:
    #   - `delayed`: Will run the action on the other resource after all other
    #     actions have been run.  This is the default.
    #   - `immediate`, `immediately`: Will run the action on the other resource
    #     immediately (before any other action is run).
    #
    # @example Resource by string
    #   file '/foo.txt' do
    #     content 'hi'
    #     notifies :create, 'file[/bar.txt]'
    #   end
    #   file '/bar.txt' do
    #     action :nothing
    #     content 'hi'
    #   end
    # @example Resource by hash
    #   file '/foo.txt' do
    #     content 'hi'
    #     notifies :create, file: '/bar.txt'
    #   end
    #   file '/bar.txt' do
    #     action :nothing
    #     content 'hi'
    #   end
    # @example Direct Resource
    #   bar = file '/bar.txt' do
    #     action :nothing
    #     content 'hi'
    #   end
    #   file '/foo.txt' do
    #     content 'hi'
    #     notifies :create, bar
    #   end
    #
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

    #
    # Subscribes to updates from other resources, causing a particular action to
    # run on *this* resource when the other resource is updated.
    #
    # If multiple resources are specified, this resource action will be run if
    # *any* of them change.
    #
    # This notification will only trigger *once*, no matter how many other
    # resources are updated (or how many actions are run by a particular resource).
    #
    # @param action The action to run on the other resource.
    # @param resources [String, Resource, Array[String, Resource]] The resources to subscribe to.
    # @param timing [String, Symbol] When to notify.  Has these values:
    #   - `delayed`: An update will cause the action to run after all other
    #     actions have been run.  This is the default.
    #   - `immediate`, `immediately`: The action will run immediately following
    #     the other resource being updated.
    #
    # @example Resources by string
    #   file '/foo.txt' do
    #     content 'hi'
    #     action :nothing
    #     subscribes :create, 'file[/bar.txt]'
    #   end
    #   file '/bar.txt' do
    #     content 'hi'
    #   end
    # @example Direct resource
    #   bar = file '/bar.txt' do
    #     content 'hi'
    #   end
    #   file '/foo.txt' do
    #     content 'hi'
    #     action :nothing
    #     subscribes :create, '/bar.txt'
    #   end
    # @example Multiple resources by string
    #   file '/foo.txt' do
    #     content 'hi'
    #     action :nothing
    #     subscribes :create, [ 'file[/bar.txt]', 'file[/baz.txt]' ]
    #   end
    #   file '/bar.txt' do
    #     content 'hi'
    #   end
    #   file '/baz.txt' do
    #     content 'hi'
    #   end
    # @example Multiple resources
    #   bar = file '/bar.txt' do
    #     content 'hi'
    #   end
    #   baz = file '/bar.txt' do
    #     content 'hi'
    #   end
    #   file '/foo.txt' do
    #     content 'hi'
    #     action :nothing
    #     subscribes :create, [ bar, baz ]
    #   end
    #
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

    #
    # A command or block that indicates whether to actually run this resource.
    # The command or block is run just before the action actually executes, and
    # the action will be skipped if the block returns false.
    #
    # If a block is specified, it must return `true` in order for the Resource
    # to be executed.
    #
    # If a command is specified, the resource's #guard_interpreter will run the
    # command and interpret the results according to `opts`.  For example, the
    # default `execute` resource will be treated as `false` if the command
    # returns a non-zero exit code, and `true` if it returns 0.  Thus, in the
    # default case:
    #
    # - `only_if "your command"` will perform the action only if `your command`
    # returns 0.
    # - `only_if "your command", valid_exit_codes: [ 1, 2, 3 ]` will perform the
    #   action only if `your command` returns 1, 2, or 3.
    #
    # @param command [String] A string to execute.
    # @param opts [Hash] Options control the execution of the command
    # @param block [Proc] A ruby block to run. Ignored if a command is given.
    #
    def only_if(command=nil, opts={}, &block)
      if command || block_given?
        @only_if << Conditional.only_if(self, command, opts, &block)
      end
      @only_if
    end

    #
    # A command or block that indicates whether to actually run this resource.
    # The command or block is run just before the action actually executes, and
    # the action will be skipped if the block returns true.
    #
    # If a block is specified, it must return `false` in order for the Resource
    # to be executed.
    #
    # If a command is specified, the resource's #guard_interpreter will run the
    # command and interpret the results according to `opts`.  For example, the
    # default `execute` resource will be treated as `false` if the command
    # returns a non-zero exit code, and `true` if it returns 0.  Thus, in the
    # default case:
    #
    # - `not_if "your command"` will perform the action only if `your command`
    # returns a non-zero code.
    # - `only_if "your command", valid_exit_codes: [ 1, 2, 3 ]` will perform the
    #   action only if `your command` returns something other than 1, 2, or 3.
    #
    # @param command [String] A string to execute.
    # @param opts [Hash] Options control the execution of the command
    # @param block [Proc] A ruby block to run. Ignored if a command is given.
    #
    def not_if(command=nil, opts={}, &block)
      if command || block_given?
        @not_if << Conditional.not_if(self, command, opts, &block)
      end
      @not_if
    end

    #
    # The number of times to retry this resource if it fails by throwing an
    # exception while running an action.  Default: 0
    #
    # When the retries have run out, the Resource will throw the last
    # exception.
    #
    # @param arg [Integer] The number of retries.
    # @return [Integer] The number of retries.
    #
    def retries(arg=nil)
      set_or_return(:retries, arg, kind_of: Integer)
    end
    attr_writer :retries

    #
    # The number of seconds to wait between retries.  Default: 2.
    #
    # @param arg [Integer] The number of seconds to wait between retries.
    # @return [Integer] The number of seconds to wait between retries.
    #
    def retry_delay(arg=nil)
      set_or_return(:retry_delay, arg, kind_of: Integer)
    end
    attr_writer :retry_delay

    #
    # Whether to treat this resource's data as sensitive.  If set, no resource
    # data will be displayed in log output.
    #
    # @param arg [Boolean] Whether this resource is sensitive or not.
    # @return [Boolean] Whether this resource is sensitive or not.
    #
    def sensitive(arg=nil)
      set_or_return(:sensitive, arg, :kind_of => [ TrueClass, FalseClass ])
    end
    attr_writer :sensitive

    # ??? TODO unreferenced.  Delete?
    attr_reader :not_if_args
    # ??? TODO unreferenced.  Delete?
    attr_reader :only_if_args

    #
    # The time it took (in seconds) to run the most recently-run action.  Not
    # cumulative across actions.  This is set to 0 as soon as a new action starts
    # running, and set to the elapsed time at the end of the action.
    #
    # @return [Integer] The time (in seconds) it took to process the most recent
    # action.  Not cumulative.
    #
    attr_reader :elapsed_time

    #
    # The guard interpreter that will be used to process `only_if` and `not_if`
    # statements.  If left unset, the #default_guard_interpreter will be used.
    #
    # Must be a resource class like `Chef::Resource::Execute`, or
    # a corresponding to the name of a resource.  The resource must descend from
    # `Chef::Resource::Execute`.
    #
    # TODO this needs to be coerced on input so that retrieval is consistent.
    #
    # @param arg [Class, Symbol, String] The Guard interpreter resource class/
    #   symbol/name.
    # @return [Class, Symbol, String] The Guard interpreter resource.
    #
    def guard_interpreter(arg=nil)
      if arg.nil?
        @guard_interpreter || @default_guard_interpreter
      else
        set_or_return(:guard_interpreter, arg, :kind_of => Symbol)
      end
    end

    #
    # Get the value of the state attributes in this resource as a hash.
    #
    # Does not include properties that are not set (unless they are identity
    # properties).
    #
    # @return [Hash{Symbol => Object}] A Hash of attribute => value for the
    #   Resource class's `state_attrs`.
    #
    def state_for_resource_reporter
      state = {}
      state_properties = self.class.state_properties
      state_properties.each do |property|
        if property.identity? || property.is_set?(self)
          state[property.name] = send(property.name)
        end
      end
      state
    end

    #
    # Since there are collisions with LWRP parameters named 'state' this
    # method is not used by the resource_reporter and is most likely unused.
    # It certainly cannot be relied upon and cannot be fixed.
    #
    # @deprecated
    #
    alias_method :state, :state_for_resource_reporter

    #
    # The value of the identity of this resource.
    #
    # - If there are no identity properties on the resource, `name` is returned.
    # - If there is exactly one identity property on the resource, it is returned.
    # - If there are more than one, they are returned in a hash.
    #
    # @return [Object,Hash<Symbol,Object>] The identity of this resource.
    #
    def identity
      result = {}
      identity_properties = self.class.identity_properties
      identity_properties.each do |property|
        result[property.name] = send(property.name)
      end
      return result.values.first if identity_properties.size == 1
      result
    end

    #
    # Whether to ignore failures.  If set to `true`, and this resource when an
    # action is run, the resource will be marked as failed but no exception will
    # be thrown (and no error will be output).  Defaults to `false`.
    #
    # TODO ignore_failure and retries seem to be mutually exclusive; I doubt
    # that was intended.
    #
    # @param arg [Boolean] Whether to ignore failures.
    # @return Whether this resource will ignore failures.
    #
    def ignore_failure(arg=nil)
      set_or_return(:ignore_failure, arg, kind_of: [ TrueClass, FalseClass ])
    end
    attr_writer :ignore_failure

    #
    # Equivalent to #ignore_failure.
    #
    alias :epic_fail :ignore_failure

    #
    # Make this resource into an exact (shallow) copy of the other resource.
    #
    # @param resource [Chef::Resource] The resource to copy from.
    #
    def load_from(resource)
      resource.instance_variables.each do |iv|
        unless iv == :@source_line || iv == :@action || iv == :@not_if || iv == :@only_if
          self.instance_variable_set(iv, resource.instance_variable_get(iv))
        end
      end
    end

    #
    # Runs the given action on this resource, immediately.
    #
    # @param action The action to run (e.g. `:create`)
    # @param notification_type The notification type that triggered this (if any)
    # @param notifying_resource The resource that triggered this notification (if any)
    #
    # @raise Any error that occurs during the actual action.
    #
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

    #
    # Generic Ruby and Data Structure Stuff (for user)
    #

    def to_s
      "#{resource_name}[#{name}]"
    end

    def to_text
      return "suppressed sensitive resource output" if sensitive
      ivars = instance_variables.map { |ivar| ivar.to_sym } - HIDDEN_IVARS
      text = "# Declared in #{@source_line}\n\n"
      text << "#{resource_name}(\"#{name}\") do\n"
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

    def self.json_create(o)
      resource = self.new(o["instance_vars"]["@name"])
      o["instance_vars"].each do |k,v|
        resource.instance_variable_set("@#{k}".to_sym, v)
      end
      resource
    end

    #
    # Resource Definition Interface (for resource developers)
    #

    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::Deprecation

    #
    # The provider class for this resource.
    #
    # If `action :x do ... end` has been declared on this resource or its
    # superclasses, this will return the `action_class`.
    #
    # If this is not set, `provider_for_action` will dynamically determine the
    # provider.
    #
    # @param arg [String, Symbol, Class] Sets the provider class for this resource.
    #   If passed a String or Symbol, e.g. `:file` or `"file"`, looks up the
    #   provider based on the name.
    #
    # @return The provider class for this resource.
    #
    # @see Chef::Resource.action_class
    #
    def provider(arg=nil)
      klass = if arg.kind_of?(String) || arg.kind_of?(Symbol)
        lookup_provider_constant(arg)
      else
        arg
      end
      set_or_return(:provider, klass, kind_of: [ Class ]) ||
        self.class.action_class
    end
    def provider=(arg)
      provider(arg)
    end

    #
    # Create a property on this resource class.
    #
    # If a superclass has this property, or if this property has already been
    # defined by this resource, this will *override* the previous value.
    #
    # @param name [Symbol] The name of the property.
    # @param type [Object,Array<Object>] The type(s) of this property.
    #   If present, this is prepended to the `is` validation option.
    # @param options [Hash<Symbol,Object>] Validation options.
    #   @option options [Object,Array] :is An object, or list of
    #     objects, that must match the value using Ruby's `===` operator
    #     (`options[:is].any? { |v| v === value }`).
    #   @option options [Object,Array] :equal_to An object, or list
    #     of objects, that must be equal to the value using Ruby's `==`
    #     operator (`options[:is].any? { |v| v == value }`)
    #   @option options [Regexp,Array<Regexp>] :regex An object, or
    #     list of objects, that must match the value with `regex.match(value)`.
    #   @option options [Class,Array<Class>] :kind_of A class, or
    #     list of classes, that the value must be an instance of.
    #   @option options [Hash<String,Proc>] :callbacks A hash of
    #     messages -> procs, all of which match the value. The proc must
    #     return a truthy or falsey value (true means it matches).
    #   @option options [Symbol,Array<Symbol>] :respond_to A method
    #     name, or list of method names, the value must respond to.
    #   @option options [Symbol,Array<Symbol>] :cannot_be A property,
    #     or a list of properties, that the value cannot have (such as `:nil` or
    #     `:empty`). The method with a questionmark at the end is called on the
    #     value (e.g. `value.empty?`). If the value does not have this method,
    #     it is considered valid (i.e. if you don't respond to `empty?` we
    #     assume you are not empty).
    #   @option options [Proc] :coerce A proc which will be called to
    #     transform the user input to canonical form. The value is passed in,
    #     and the transformed value returned as output. Lazy values will *not*
    #     be passed to this method until after they are evaluated. Called in the
    #     context of the resource (meaning you can access other properties).
    #   @option options [Boolean] :required `true` if this property
    #     must be present; `false` otherwise. This is checked after the resource
    #     is fully initialized.
    #   @option options [Boolean] :name_property `true` if this
    #     property defaults to the same value as `name`. Equivalent to
    #     `default: lazy { name }`, except that #property_is_set? will
    #     return `true` if the property is set *or* if `name` is set.
    #   @option options [Boolean] :name_attribute Same as `name_property`.
    #   @option options [Object] :default The value this property
    #     will return if the user does not set one. If this is `lazy`, it will
    #     be run in the context of the instance (and able to access other
    #     properties).
    #   @option options [Boolean] :desired_state `true` if this property is
    #     part of desired state. Defaults to `true`.
    #   @option options [Boolean] :identity `true` if this property
    #     is part of object identity. Defaults to `false`.
    #
    # @example Bare property
    #   property :x
    #
    # @example With just a type
    #   property :x, String
    #
    # @example With just options
    #   property :x, default: 'hi'
    #
    # @example With type and options
    #   property :x, String, default: 'hi'
    #
    def self.property(name, type=NOT_PASSED, **options)
      name = name.to_sym

      options.each { |k,v| options[k.to_sym] = v if k.is_a?(String) }

      options[:instance_variable_name] = :"@#{name}" if !options.has_key?(:instance_variable_name)
      options.merge!(name: name, declared_in: self)

      if type == NOT_PASSED
        # If a type is not passed, the property derives from the
        # superclass property (if any)
        if properties.has_key?(name)
          property = properties[name].derive(**options)
        else
          property = property_type(**options)
        end

      # If a Property is specified, derive a new one from that.
      elsif type.is_a?(Property) || (type.is_a?(Class) && type <= Property)
        property = type.derive(**options)

      # If a primitive type was passed, combine it with "is"
      else
        if options[:is]
          options[:is] = ([ type ] + [ options[:is] ]).flatten(1)
        else
          options[:is] = type
        end
        property = property_type(**options)
      end

      local_properties = properties(false)
      local_properties[name] = property

      property.emit_dsl
    end

    #
    # Create a reusable property type that can be used in multiple properties
    # in different resources.
    #
    # @param options [Hash<Symbol,Object>] Validation options. see #property for
    #   the list of options.
    #
    # @example
    #   property_type(default: 'hi')
    #
    def self.property_type(**options)
      Property.derive(**options)
    end

    #
    # The name of this particular resource.
    #
    # This special resource attribute is set automatically from the declaration
    # of the resource, e.g.
    #
    #   execute 'Vitruvius' do
    #     command 'ls'
    #   end
    #
    # Will set the name to "Vitruvius".
    #
    # This is also used in to_s to show the resource name, e.g. `execute[Vitruvius]`.
    #
    # This is also used for resource notifications and subscribes in the same manner.
    #
    # This will coerce any object into a string via #to_s.  Arrays are a special case
    # so that `package ["foo", "bar"]` becomes package[foo, bar] instead of the more
    # awkward `package[["foo", "bar"]]` that #to_s would produce.
    #
    # @param name [Object] The name to set, typically a String or Array
    # @return [String] The name of this Resource.
    #
    property :name, String, coerce: proc { |v| v.is_a?(Array) ? v.join(', ') : v.to_s }, desired_state: false

    #
    # Whether this property has been set (or whether it has a default that has
    # been retrieved).
    #
    # @param name [Symbol] The name of the property.
    # @return [Boolean] `true` if the property has been set.
    #
    def property_is_set?(name)
      property = self.class.properties[name.to_sym]
      raise ArgumentError, "Property #{name} is not defined in class #{self}" if !property
      property.is_set?(self)
    end

    #
    # Clear this property as if it had never been set. It will thereafter return
    # the default.
    # been retrieved).
    #
    # @param name [Symbol] The name of the property.
    #
    def reset_property(name)
      property = self.class.properties[name.to_sym]
      raise ArgumentError, "Property #{name} is not defined in class #{self}" if !property
      property.reset(self)
    end

    #
    # Create a lazy value for assignment to a default value.
    #
    # @param block The block to run when the value is retrieved.
    #
    # @return [Chef::DelayedEvaluator] The lazy value
    #
    def self.lazy(&block)
      DelayedEvaluator.new(&block)
    end

    #
    # Get or set the list of desired state properties for this resource.
    #
    # State properties are properties that describe the desired state
    # of the system, such as file permissions or ownership.
    # In general, state properties are properties that could be populated by
    # examining the state of the system (e.g., File.stat can tell you the
    # permissions on an existing file). Contrarily, properties that are not
    # "state properties" usually modify the way Chef itself behaves, for example
    # by providing additional options for a package manager to use when
    # installing a package.
    #
    # This list is used by the Chef client auditing system to extract
    # information from resources to describe changes made to the system.
    #
    # This method is unnecessary when declaring properties with `property`;
    # properties are added to state_properties by default, and can be turned off
    # with `desired_state: false`.
    #
    # ```ruby
    # property :x # part of desired state
    # property :y, desired_state: false # not part of desired state
    # ```
    #
    # @param names [Array<Symbol>] A list of property names to set as desired
    #   state.
    #
    # @return [Array<Property>] All properties in desired state.
    #
    def self.state_properties(*names)
      if !names.empty?
        names = names.map { |name| name.to_sym }.uniq

        local_properties = properties(false)
        # Add new properties to the list.
        names.each do |name|
          property = properties[name]
          if !property
            self.property name, instance_variable_name: false, desired_state: true
          elsif !property.desired_state?
            self.property name, desired_state: true
          end
        end

        # If state_attrs *excludes* something which is currently desired state,
        # mark it as desired_state: false.
        local_properties.each do |name,property|
          if property.desired_state? && !names.include?(name)
            self.property name, desired_state: false
          end
        end
      end

      properties.values.select { |property| property.desired_state? }
    end

    #
    # Set or return the list of "state properties" implemented by the Resource
    # subclass.
    #
    # Equivalent to calling #state_properties and getting `state_properties.keys`.
    #
    # @deprecated Use state_properties.keys instead. Note that when you declare
    #   properties with `property`: properties are added to state_properties by
    #   default, and can be turned off with `desired_state: false`
    #
    #   ```ruby
    #   property :x # part of desired state
    #   property :y, desired_state: false # not part of desired state
    #   ```
    #
    # @param names [Array<Symbol>] A list of property names to set as desired
    #   state.
    #
    # @return [Array<Symbol>] All property names with desired state.
    #
    def self.state_attrs(*names)
      state_properties(*names).map { |property| property.name }
    end

    #
    # Set the identity of this resource to a particular set of properties.
    #
    # This drives #identity, which returns data that uniquely refers to a given
    # resource on the given node (in such a way that it can be correlated
    # across Chef runs).
    #
    # This method is unnecessary when declaring properties with `property`;
    # properties can be added to identity during declaration with
    # `identity: true`.
    #
    # ```ruby
    # property :x, identity: true # part of identity
    # property :y # not part of identity
    # ```
    #
    # If no properties are marked as identity, "name" is considered the identity.
    #
    # @param names [Array<Symbol>] A list of property names to set as the identity.
    #
    # @return [Array<Property>] All identity properties.
    #
    def self.identity_properties(*names)
      if !names.empty?
        names = names.map { |name| name.to_sym }

        # Add or change properties that are not part of the identity.
        names.each do |name|
          property = properties[name]
          if !property
            self.property name, instance_variable_name: false, identity: true
          elsif !property.identity?
            self.property name, identity: true
          end
        end

        # If identity_properties *excludes* something which is currently part of
        # the identity, mark it as identity: false.
        properties.each do |name,property|
          if property.identity? && !names.include?(name)
            self.property name, identity: false
          end
        end
      end

      result = properties.values.select { |property| property.identity? }
      result = [ properties[:name] ] if result.empty?
      result
    end

    #
    # Set the identity of this resource to a particular property.
    #
    # This drives #identity, which returns data that uniquely refers to a given
    # resource on the given node (in such a way that it can be correlated
    # across Chef runs).
    #
    # This method is unnecessary when declaring properties with `property`;
    # properties can be added to identity during declaration with
    # `identity: true`.
    #
    # ```ruby
    # property :x, identity: true # part of identity
    # property :y # not part of identity
    # ```
    #
    # @param name [Symbol] A list of property names to set as the identity.
    #
    # @return [Symbol] The identity property if there is only one; or `nil` if
    #   there are more than one.
    #
    # @raise [ArgumentError] If no arguments are passed and the resource has
    #   more than one identity property.
    #
    def self.identity_property(name=nil)
      result = identity_properties(*Array(name))
      if result.size > 1
        raise Chef::Exceptions::MultipleIdentityError, "identity_property cannot be called on an object with more than one identity property (#{result.map { |r| r.name }.join(", ")})."
      end
      result.first
    end

    #
    # Set a property as the "identity attribute" for this resource.
    #
    # Identical to calling #identity_property.first.key.
    #
    # @param name [Symbol] The name of the property to set.
    #
    # @return [Symbol]
    #
    # @deprecated `identity_property` should be used instead.
    #
    # @raise [ArgumentError] If no arguments are passed and the resource has
    #   more than one identity property.
    #
    def self.identity_attr(name=nil)
      property = identity_property(name)
      return nil if !property
      property.name
    end

    #
    # The guard interpreter that will be used to process `only_if` and `not_if`
    # statements by default.  If left unset, or set to `:default`, the guard
    # interpreter used will be Chef::GuardInterpreter::DefaultGuardInterpreter.
    #
    # Must be a resource class like `Chef::Resource::Execute`, or
    # a corresponding to the name of a resource.  The resource must descend from
    # `Chef::Resource::Execute`.
    #
    # TODO this needs to be coerced on input so that retrieval is consistent.
    #
    # @return [Class, Symbol, String] the default Guard interpreter resource.
    #
    attr_reader :default_guard_interpreter

    #
    # The list of actions this Resource is allowed to have.  Setting `action`
    # will fail unless it is in this list.  Default: [ :nothing ]
    #
    # @return [Array<Symbol>] The list of actions this Resource is allowed to
    #   have.
    #
    attr_accessor :allowed_actions
    def allowed_actions(value=NOT_PASSED)
      if value != NOT_PASSED
        self.allowed_actions = value
      end
      @allowed_actions
    end

    #
    # Whether or not this resource was updated during an action.  If multiple
    # actions are set on the resource, this will be `true` if *any* action
    # caused an update to happen.
    #
    # @return [Boolean] Whether the resource was updated during an action.
    #
    attr_reader :updated

    #
    # Whether or not this resource was updated during an action.  If multiple
    # actions are set on the resource, this will be `true` if *any* action
    # caused an update to happen.
    #
    # @return [Boolean] Whether the resource was updated during an action.
    #
    def updated?
      updated
    end

    #
    # Whether or not this resource was updated during the most recent action.
    # This is set to `false` at the beginning of each action.
    #
    # @param true_or_false [Boolean] Whether the resource was updated during the
    #   current / most recent action.
    # @return [Boolean] Whether the resource was updated during the most recent action.
    #
    def updated_by_last_action(true_or_false)
      @updated ||= true_or_false
      @updated_by_last_action = true_or_false
    end

    #
    # Whether or not this resource was updated during the most recent action.
    # This is set to `false` at the beginning of each action.
    #
    # @return [Boolean] Whether the resource was updated during the most recent action.
    #
    def updated_by_last_action?
      @updated_by_last_action
    end

    #
    # Set whether this class was updated during an action.
    #
    # @deprecated Multiple actions are supported by resources.  Please call {}#updated_by_last_action} instead.
    #
    def updated=(true_or_false)
      Chef::Log.warn("Chef::Resource#updated=(true|false) is deprecated. Please call #updated_by_last_action(true|false) instead.")
      Chef::Log.warn("Called from:")
      caller[0..3].each {|line| Chef::Log.warn(line)}
      updated_by_last_action(true_or_false)
      @updated = true_or_false
    end

    #
    # The display name of this resource type, for printing purposes.
    #
    # Will be used to print out the resource in messages, e.g. resource_name[name]
    #
    # @return [Symbol] The name of this resource type (e.g. `:execute`).
    #
    def resource_name
      @resource_name || self.class.resource_name
    end

    #
    # Sets a list of capabilities of the real resource.  For example, `:remount`
    # (for filesystems) and `:restart` (for services).
    #
    # TODO Calling resource.supports({}) will not set this to empty; it will do
    # a get instead.  That's wrong.
    #
    # @param args Hash{Symbol=>Boolean} If non-empty, sets the capabilities of
    #   this resource. Default: {}
    # @return Hash{Symbol=>Boolean} An array of things this resource supports.
    #
    def supports(args={})
      if args.any?
        @supports = args
      else
        @supports
      end
    end
    def supports=(args)
      supports(args)
    end

    #
    # A hook called after a resource is created.  Meant to be overriden by
    # subclasses.
    #
    def after_created
      nil
    end

    #
    # The DSL name of this resource (e.g. `package` or `yum_package`)
    #
    # @return [String] The DSL name of this resource.
    #
    # @deprecated Use resource_name instead.
    #
    def self.dsl_name
      Chef.log_deprecation "Resource.dsl_name is deprecated and will be removed in Chef 13.  Use resource_name instead."
      if name
        name = self.name.split('::')[-1]
        convert_to_snake_case(name)
      end
    end

    #
    # The display name of this resource type, for printing purposes.
    #
    # This also automatically calls "provides" to provide DSL with the given
    # name.
    #
    # resource_name defaults to your class name.
    #
    # Call `resource_name nil` to remove the resource name (and any
    # corresponding DSL).
    #
    # @param value [Symbol] The desired name of this resource type (e.g.
    #   `execute`), or `nil` if this class is abstract and has no resource_name.
    #
    # @return [Symbol] The name of this resource type (e.g. `:execute`).
    #
    def self.resource_name(name=NOT_PASSED)
      # Setter
      if name != NOT_PASSED
        remove_canonical_dsl

        # Set the resource_name and call provides
        if name
          name = name.to_sym
          # If our class is not already providing this name, provide it.
          if !Chef::ResourceResolver.includes_handler?(name, self)
            provides name, canonical: true
          end
          @resource_name = name
        else
          @resource_name = nil
        end
      end
      @resource_name
    end
    def self.resource_name=(name)
      resource_name(name)
    end

    #
    # Use the class name as the resource name.
    #
    # Munges the last part of the class name from camel case to snake case,
    # and sets the resource_name to that:
    #
    # A::B::BlahDBlah -> blah_d_blah
    #
    def self.use_automatic_resource_name
      automatic_name = convert_to_snake_case(self.name.split('::')[-1])
      resource_name automatic_name
    end

    #
    # The module where Chef should look for providers for this resource.
    # The provider for `MyResource` will be looked up using
    # `provider_base::MyResource`.  Defaults to `Chef::Provider`.
    #
    # @param arg [Module] The module containing providers for this resource
    # @return [Module] The module containing providers for this resource
    #
    # @example
    #   class MyResource < Chef::Resource
    #     provider_base Chef::Provider::Deploy
    #     # ...other stuff
    #   end
    #
    # @deprecated Use `provides` on the provider, or `provider` on the resource, instead.
    #
    def self.provider_base(arg=nil)
      if arg
        Chef.log_deprecation("Resource.provider_base is deprecated and will be removed in Chef 13. Use provides on the provider, or provider on the resource, instead.")
      end
      @provider_base ||= arg || Chef::Provider
    end

    #
    # The list of allowed actions for the resource.
    #
    # @param actions [Array<Symbol>] The list of actions to add to allowed_actions.
    #
    # @return [Array<Symbol>] The list of actions, as symbols.
    #
    def self.allowed_actions(*actions)
      @allowed_actions ||=
        if superclass.respond_to?(:allowed_actions)
          superclass.allowed_actions.dup
        else
          [ :nothing ]
        end
      @allowed_actions |= actions.flatten
    end
    def self.allowed_actions=(value)
      @allowed_actions = value.uniq
    end

    #
    # The action that will be run if no other action is specified.
    #
    # Setting default_action will automatially add the action to
    # allowed_actions, if it isn't already there.
    #
    # Defaults to [:nothing].
    #
    # @param action_name [Symbol,Array<Symbol>] The default action (or series
    #   of actions) to use.
    #
    # @return [Array<Symbol>] The default actions for the resource.
    #
    def self.default_action(action_name=NOT_PASSED)
      unless action_name.equal?(NOT_PASSED)
        @default_action = Array(action_name).map(&:to_sym)
        self.allowed_actions |= @default_action
      end

      if @default_action
        @default_action
      elsif superclass.respond_to?(:default_action)
        superclass.default_action
      else
        [:nothing]
      end
    end
    def self.default_action=(action_name)
      default_action action_name
    end

    #
    # Define an action on this resource.
    #
    # The action is defined as a *recipe* block that will be compiled and then
    # converged when the action is taken (when Resource is converged).  The recipe
    # has access to the resource's attributes and methods, as well as the Chef
    # recipe DSL.
    #
    # Resources in the action recipe may notify and subscribe to other resources
    # within the action recipe, but cannot notify or subscribe to resources
    # in the main Chef run.
    #
    # Resource actions are *inheritable*: if resource A defines `action :create`
    # and B is a subclass of A, B gets all of A's actions.  Additionally,
    # resource B can define `action :create` and call `super()` to invoke A's
    # action code.
    #
    # The first action defined (besides `:nothing`) will become the default
    # action for the resource.
    #
    # @param name [Symbol] The action name to define.
    # @param recipe_block The recipe to run when the action is taken. This block
    #   takes no parameters, and will be evaluated in a new context containing:
    #
    #   - The resource's public and protected methods (including attributes)
    #   - The Chef Recipe DSL (file, etc.)
    #   - super() referring to the parent version of the action (if any)
    #
    # @return The Action class implementing the action
    #
    def self.action(action, &recipe_block)
      action = action.to_sym
      declare_action_class
      action_class.action(action, &recipe_block)
      self.allowed_actions += [ action ]
      default_action action if Array(default_action) == [:nothing]
    end

    #
    # Define a method to load up this resource's properties with the current
    # actual values.
    #
    # @param load_block The block to load.  Will be run in the context of a newly
    #   created resource with its identity values filled in.
    #
    def self.load_current_value(&load_block)
      define_method(:load_current_value!, &load_block)
    end

    #
    # Call this in `load_current_value` to indicate that the value does not
    # exist and that `current_resource` should therefore be `nil`.
    #
    # @raise Chef::Exceptions::CurrentValueDoesNotExist
    #
    def current_value_does_not_exist!
      raise Chef::Exceptions::CurrentValueDoesNotExist
    end

    #
    # Get the current actual value of this resource.
    #
    # This does not cache--a new value will be returned each time.
    #
    # @return A new copy of the resource, with values filled in from the actual
    #   current value.
    #
    def current_value
      provider = provider_for_action(Array(action).first)
      if provider.whyrun_mode? && !provider.whyrun_supported?
        raise "Cannot retrieve #{self.class.current_resource} in why-run mode: #{provider} does not support why-run"
      end
      provider.load_current_resource
      provider.current_resource
    end

    #
    # The action class is an automatic `Provider` created to handle
    # actions declared by `action :x do ... end`.
    #
    # This class will be returned by `resource.provider` if `resource.provider`
    # is not set. `provider_for_action` will also use this instead of calling
    # out to `Chef::ProviderResolver`.
    #
    # If the user has not declared actions on this class or its superclasses
    # using `action :x do ... end`, then there is no need for this class and
    # `action_class` will be `nil`.
    #
    # @api private
    #
    def self.action_class
      @action_class ||
        # If the superclass needed one, then we need one as well.
        if superclass.respond_to?(:action_class) && superclass.action_class
          declare_action_class
        end
    end

    #
    # Ensure the action class actually gets created. This is called
    # when the user does `action :x do ... end`.
    #
    # If a block is passed, it is run inside the action_class.
    #
    # @api private
    def self.declare_action_class
      return @action_class if @action_class

      if superclass.respond_to?(:action_class)
        base_provider = superclass.action_class
      end
      base_provider ||= Chef::Provider

      resource_class = self
      @action_class = Class.new(base_provider) do
        include ActionClass
        self.resource_class = resource_class
      end
    end

    #
    # Internal Resource Interface (for Chef)
    #

    FORBIDDEN_IVARS = [:@run_context, :@not_if, :@only_if, :@enclosing_provider]
    HIDDEN_IVARS = [:@allowed_actions, :@resource_name, :@source_line, :@run_context, :@name, :@not_if, :@only_if, :@elapsed_time, :@enclosing_provider]

    include Chef::Mixin::ConvertToClassName
    extend Chef::Mixin::ConvertToClassName

    # XXX: this is required for definition params inside of the scope of a
    # subresource to work correctly.
    attr_accessor :params

    # @return [Chef::RunContext] The run context for this Resource.  This is
    # where the context for the current Chef run is stored, including the node
    # and the resource collection.
    attr_accessor :run_context

    # @return [String] The cookbook this resource was declared in.
    attr_accessor :cookbook_name

    # @return [String] The recipe this resource was declared in.
    attr_accessor :recipe_name

    # @return [Chef::Provider] The provider this resource was declared in (if
    #   it was declared in an LWRP).  When you call methods that do not exist
    #   on this Resource, Chef will try to call the method on the provider
    #   as well before giving up.
    attr_accessor :enclosing_provider

    # @return [String] The source line where this resource was declared.
    #   Expected to come from caller() or a stack trace, it usually follows one
    #   of these formats:
    #     /some/path/to/file.rb:80:in `wombat_tears'
    #     C:/some/path/to/file.rb:80 in 1`wombat_tears'
    attr_accessor :source_line

    # @return [String] The actual name that was used to create this resource.
    #   Sometimes, when you say something like `package 'blah'`, the system will
    #   create a different resource (i.e. `YumPackage`).  When this happens, the
    #   user will expect to see the thing they wrote, not the type that was
    #   returned.  May be `nil`, in which case callers should read #resource_name.
    #   See #declared_key.
    attr_accessor :declared_type

    #
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

    # Helper for #notifies
    def notifies_immediately(action, resource_spec)
      run_context.notifies_immediately(Notification.new(resource_spec, action, self))
    end

    # Helper for #notifies
    def notifies_delayed(action, resource_spec)
      run_context.notifies_delayed(Notification.new(resource_spec, action, self))
    end

    class << self
      # back-compat
      # NOTE: that we do not support unregistering classes as descendants like
      # we used to for LWRP unloading because that was horrible and removed in
      # Chef-12.
      # @deprecated
      # @api private
      alias :resource_classes :descendants
      # @deprecated
      # @api private
      alias :find_subclass_by_name :find_descendants_by_name
    end

    # @deprecated
    # @api private
    # We memoize a sorted version of descendants so that resource lookups don't
    # have to sort all the things, all the time.
    # This was causing performance issues in test runs, and probably in real
    # life as well.
    @@sorted_descendants = nil
    def self.sorted_descendants
      @@sorted_descendants ||= descendants.sort_by { |x| x.to_s }
    end
    def self.inherited(child)
      super
      @@sorted_descendants = nil
      # set resource_name automatically if it's not set
      if child.name && !child.resource_name
        if child.name =~ /^Chef::Resource::(\w+)$/
          child.resource_name(convert_to_snake_case($1))
        end
      end
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

    #
    # Mark this resource as providing particular DSL.
    #
    # Resources have an automatic DSL based on their resource_name, equivalent to
    # `provides :resource_name` (providing the resource on all OS's).  If you
    # declare a `provides` with the given resource_name, it *replaces* that
    # provides (so that you can provide your resource DSL only on certain OS's).
    #
    def self.provides(name, **options, &block)
      name = name.to_sym

      # `provides :resource_name, os: 'linux'`) needs to remove the old
      # canonical DSL before adding the new one.
      if @resource_name && name == @resource_name
        remove_canonical_dsl
      end

      result = Chef.resource_handler_map.set(name, self, options, &block)
      Chef::DSL::Resources.add_resource_dsl(name)
      result
    end

    def self.provides?(node, resource_name)
      Chef::ResourceResolver.new(node, resource_name).provided_by?(self)
    end

    # Helper for #notifies
    def validate_resource_spec!(resource_spec)
      run_context.resource_collection.validate_lookup_spec!(resource_spec)
    end

    # We usually want to store and reference resources by their declared type and not the actual type that
    # was looked up by the Resolver (IE, "package" becomes YumPackage class).  If we have not been provided
    # the declared key we want to fall back on the old to_s key.
    def declared_key
      return to_s if declared_type.nil?
      "#{declared_type}[#{@name}]"
    end

    def immediate_notifications
      run_context.immediate_notifications(self)
    end

    def delayed_notifications
      run_context.delayed_notifications(self)
    end

    def source_line_file
      if source_line
        source_line.match(/(.*):(\d+):?.*$/).to_a[1]
      else
        nil
      end
    end

    def source_line_number
      if source_line
        source_line.match(/(.*):(\d+):?.*$/).to_a[2]
      else
        nil
      end
    end

    def defined_at
      # The following regexp should match these two sourceline formats:
      #   /some/path/to/file.rb:80:in `wombat_tears'
      #   C:/some/path/to/file.rb:80 in 1`wombat_tears'
      # extracting the path to the source file and the line number.
      if cookbook_name && recipe_name && source_line
        "#{cookbook_name}::#{recipe_name} line #{source_line_number}"
      elsif source_line
        "#{source_line_file} line #{source_line_number}"
      else
        "dynamically defined"
      end
    end

    #
    # The cookbook in which this Resource was defined (if any).
    #
    # @return Chef::CookbookVersion The cookbook in which this Resource was defined.
    #
    def cookbook_version
      if cookbook_name
        run_context.cookbook_collection[cookbook_name]
      end
    end

    def events
      run_context.events
    end

    def validate_action(action)
      raise ArgumentError, "nil is not a valid action for resource #{self}" if action.nil?
    end

    def provider_for_action(action)
      provider_class = Chef::ProviderResolver.new(node, self, action).resolve
      provider = provider_class.new(self, run_context)
      provider.action = action
      provider
    end

    # ??? TODO Seems unused.  Delete?
    def noop(tf=nil)
      if !tf.nil?
        raise ArgumentError, "noop must be true or false!" unless tf == true || tf == false
        @noop = tf
      end
      @noop
    end

    # TODO Seems unused.  Delete?
    def is(*args)
      if args.size == 1
        args.first
      else
        return *args
      end
    end

    #
    # Preface an exception message with generic Resource information.
    #
    # @param e [StandardError] An exception with `e.message`
    # @return [String] An exception message customized with class name.
    #
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

    # Returns a resource based on a short_name and node
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    # node<Chef::Node>:: Node object to look up platform and version in
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    def self.resource_for_node(short_name, node)
      klass = Chef::ResourceResolver.resolve(short_name, node: node)
      raise Chef::Exceptions::NoSuchResourceType.new(short_name, node) if klass.nil?
      klass
    end

    #
    # Returns the class with the given resource_name.
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    #
    def self.resource_matching_short_name(short_name)
      Chef::ResourceResolver.resolve(short_name, canonical: true)
    end

    # @api private
    def self.register_deprecated_lwrp_class(resource_class, class_name)
      if Chef::Resource.const_defined?(class_name, false)
        Chef::Log.warn "#{class_name} already exists!  Deprecation class overwrites #{resource_class}"
        Chef::Resource.send(:remove_const, class_name)
      end

      if !Chef::Config[:treat_deprecation_warnings_as_errors]
        Chef::Resource.const_set(class_name, resource_class)
        deprecated_constants[class_name.to_sym] = resource_class
      end

    end

    def self.deprecated_constants
      @deprecated_constants ||= {}
    end

    # @api private
    def lookup_provider_constant(name, action=:nothing)
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

    private

    def self.remove_canonical_dsl
      if @resource_name
        remaining = Chef.resource_handler_map.delete_canonical(@resource_name, self)
        if !remaining
          Chef::DSL::Resources.remove_resource_dsl(@resource_name)
        end
      end
    end
  end
end

# Requiring things at the bottom breaks cycles
require 'chef/chef_class'
