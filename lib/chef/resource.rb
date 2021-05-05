#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: John Keiser (<jkeiser@chef.io)
# Copyright:: Copyright 2008-2016, Chef, Inc.
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

require_relative "exceptions"
require_relative "dsl/reboot_pending"
require_relative "dsl/resources"
require_relative "dsl/declare_resource"
require_relative "json_compat"
require_relative "mixin/convert_to_class_name"
require_relative "guard_interpreter/resource_guard_interpreter"
require_relative "resource/conditional"
require_relative "resource/conditional_action_not_nothing"
require_relative "resource/action_class"
require_relative "resource_collection"
require_relative "node_map"
require_relative "node"
require_relative "platform"
require_relative "resource/resource_notification"
require_relative "provider_resolver"
require_relative "resource_resolver"
require_relative "provider"
autoload :Set, "set"

require_relative "mixin/deprecation"
require_relative "mixin/properties"
require_relative "mixin/provides"
require_relative "dsl/universal"
require_relative "constants"

class Chef
  class Resource

    #
    # Generic User DSL (not resource-specific)
    #

    include Chef::DSL::DeclareResource
    include Chef::DSL::RebootPending
    extend Chef::Mixin::Provides

    include Chef::DSL::Universal
    extend Chef::DSL::Universal

    # Bring in `property` and `property_type`
    include Chef::Mixin::Properties

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
    property :name, String, coerce: proc { |v| v.is_a?(Array) ? v.join(", ") : v.to_s }, desired_state: false, required: true

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
    # Resource User Interface (for users)
    #

    #
    # Create a new Resource.
    #
    # @param name The name of this resource (corresponds to the #name attribute,
    #   used for notifications to this resource).
    # @param run_context The context of the Chef run. Corresponds to #run_context.
    #
    def initialize(name, run_context = nil)
      name(name) unless name.nil?
      @run_context = run_context

      @logger = if run_context
                  run_context.logger.with_child({ name: name, resource: resource_name })
                else
                  Chef::Log.with_child({ name: name, resource: resource_name })
                end

      @before = nil
      @params = {}
      @provider = nil
      @allowed_actions = self.class.allowed_actions.to_a
      @action = self.class.default_action
      @updated = false
      @updated_by_last_action = false
      @not_if = []
      @only_if = []
      @source_line = nil
      @deprecated = false
      @skip_docs = false
      # We would like to raise an error when the user gives us a guard
      # interpreter and a ruby_block to the guard. In order to achieve this
      # we need to understand when the user overrides the default guard
      # interpreter. Therefore we store the default separately in a different
      # attribute.
      @guard_interpreter = nil
      @default_guard_interpreter = :default
      @elapsed_time = 0
      @executed_by_runner = false
    end

    #
    # The action or actions that will be taken when this resource is run.
    #
    # @param arg [Array[Symbol], Symbol] A list of actions (e.g. `:create`)
    # @return [Array[Symbol]] the list of actions.
    #
    def action(arg = nil)
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

    # Alias for normal assignment syntax.
    alias_method :action=, :action

    #
    # Force a delayed notification into this resource's run_context.
    #
    # This should most likely be paired with action :nothing
    #
    # @param arg [Array[Symbol], Symbol] A list of actions (e.g. `:create`)
    #
    def delayed_action(arg)
      arg = Array(arg).map(&:to_sym)
      arg.map do |action|
        validate(
          { action: action },
          { action: { kind_of: Symbol, equal_to: allowed_actions } }
        )
        # the resource effectively sends a delayed notification to itself
        run_context.add_delayed_action(Notification.new(self, action, self, run_context.unified_mode))
      end
    end

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
    #   - `before`: Will run the action on the other resource
    #     immediately *before* the action is actually run.
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
    def notifies(action, resource_spec, timing = :delayed)
      # when using old-style resources(:template => "/foo.txt") style, you
      # could end up with multiple resources.
      validate_resource_spec!(resource_spec)

      resources = [ resource_spec ].flatten
      resources.each do |resource|

        case timing.to_s
        when "delayed"
          notifies_delayed(action, resource)
        when "immediate", "immediately"
          notifies_immediately(action, resource)
        when "before"
          notifies_before(action, resource)
        else
          raise ArgumentError,  "invalid timing: #{timing} for notifies(#{action}, #{resources.inspect}, #{timing}) resource #{self} "\
            "Valid timings are: :delayed, :immediate, :immediately, :before"
        end
      end

      true
    end

    #
    # Token class to hold an unresolved subscribes call with an associated
    # run context.
    #
    # @api private
    # @see Resource#subscribes
    class UnresolvedSubscribes < self
      # The full key ise given as the name in {Resource#subscribes}
      alias_method :to_s, :name
      alias_method :declared_key, :name
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
    #   - `before`: The action will run immediately before the
    #     other resource is updated.
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
    def subscribes(action, resources, timing = :delayed)
      resources = [resources].flatten
      resources.each do |resource|
        if resource.is_a?(String)
          resource = UnresolvedSubscribes.new(resource, run_context)
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
    def only_if(command = nil, opts = {}, &block)
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
    def not_if(command = nil, opts = {}, &block)
      if command || block_given?
        @not_if << Conditional.not_if(self, command, opts, &block)
      end
      @not_if
    end

    # The number of times to retry this resource if it fails by throwing an
    # exception while running an action.  Default: 0
    #
    # When the retries have run out, the Resource will throw the last
    # exception.
    #
    # @param arg [Integer] The number of retries.
    # @return [Integer] The number of retries.
    #
    property :retries, Integer, default: 0, desired_state: false

    # The number of seconds to wait between retries.  Default: 2.
    #
    # @param arg [Integer] The number of seconds to wait between retries.
    # @return [Integer] The number of seconds to wait between retries.
    #
    property :retry_delay, Integer, default: 2, desired_state: false

    # Whether to treat this resource's data as sensitive.  If set, no resource
    # data will be displayed in log output.
    #
    # @param arg [Boolean] Whether this resource is sensitive or not.
    # @return [Boolean] Whether this resource is sensitive or not.
    #
    property :sensitive, [ TrueClass, FalseClass ], default: false, desired_state: false

    # If this is set the resource will be set to run at compile time and the converge time
    # action will be set to :nothing.
    #
    # @param arg [Boolean] Whether or not to force this resource to run at compile time.
    # @return [Boolean] Whether or not to force this resource to run at compile time.
    #
    property :compile_time, [TrueClass, FalseClass],
      description: "Determines whether or not the resource is executed during the compile time phase.",
      default: false, desired_state: false

    # Set a umask to be used for the duration of converging the resource.
    # Defaults to `nil`, which means to use the system umask.
    #
    # @param arg [String] The umask to apply while converging the resource.
    # @return [Boolean] The umask to apply while converging the resource.
    #
    property :umask, String,
      desired_state: false,
      introduced: "16.2",
      description: "Set a umask to be used for the duration of converging the resource. Defaults to `nil`, which means to use the system umask. Unsupported on Windows because Windows lacks a direct equivalent to UNIX's umask."

    # The time it took (in seconds) to run the most recently-run action.  Not
    # cumulative across actions.  This is set to 0 as soon as a new action starts
    # running, and set to the elapsed time at the end of the action.
    #
    # @return [Integer] The time (in seconds) it took to process the most recent
    # action.  Not cumulative.
    #
    attr_reader :elapsed_time

    # @return [Boolean] If the resource was executed by the runner
    #
    attr_accessor :executed_by_runner

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
    def guard_interpreter(arg = nil)
      if arg.nil?
        @guard_interpreter || @default_guard_interpreter
      else
        set_or_return(:guard_interpreter, arg, kind_of: Symbol)
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
        if property.is_set?(self)
          state[property.name] = property.sensitive? ? "*sensitive value suppressed*" : send(property.name)
        end
      end
      state
    end

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
    # be thrown (and no error will be output).  Defaults to `false`. If set to
    # `:quiet` or `'quiet'`, the normal error trace will be suppressed.
    #
    # TODO ignore_failure and retries seem to be mutually exclusive; I doubt
    # that was intended.
    #
    # @param arg [Boolean, String, Symbol] Whether to ignore failures.
    # @return Whether this resource will ignore failures.
    #
    property :ignore_failure, [ true, false, :quiet, "quiet" ], default: false, desired_state: false

    #
    # Make this resource into an exact (shallow) copy of the other resource.
    #
    # @param resource [Chef::Resource] The resource to copy from.
    #
    def load_from(resource)
      resource.instance_variables.each do |iv|
        unless iv == :@source_line || iv == :@action || iv == :@not_if || iv == :@only_if
          instance_variable_set(iv, resource.instance_variable_get(iv))
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
    def run_action(action, notification_type = nil, notifying_resource = nil)
      # reset state in case of multiple actions on the same resource.
      @elapsed_time = 0
      start_time = Time.now
      events.resource_action_start(self, action, notification_type, notifying_resource)
      # Try to resolve lazy/forward references in notifications again to handle
      # the case where the resource was defined lazily (ie. in a ruby_block)
      resolve_notification_references
      validate_action(action)

      if Chef::Config[:verbose_logging] || logger.level == :debug
        # This can be noisy
        logger.info("Processing #{self} action #{action} (#{defined_at})")
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

        with_umask do
          provider_for_action(action).run_action
        end
      rescue StandardError => e
        if ignore_failure
          logger.error("#{custom_exception_message(e)}; ignore_failure is set, continuing")
          events.resource_failed(self, action, e)
        elsif remaining_retries > 0
          events.resource_failed_retriable(self, action, remaining_retries, e)
          remaining_retries -= 1
          logger.info("Retrying execution of #{self}, #{remaining_retries} attempt#{"s" if remaining_retries > 1} left")
          sleep retry_delay
          retry
        else
          events.resource_failed(self, action, e)
          raise customize_exception(e)
        end
      end
    ensure
      @elapsed_time = Time.now - start_time
      # Reporting endpoint doesn't accept a negative resource duration so set it to 0.
      # A negative value can occur when a resource changes the system time backwards
      @elapsed_time = 0 if @elapsed_time < 0
      events.resource_completed(self)
    end

    def with_umask
      old_value = ::File.umask(umask.oct) if umask
      yield
    ensure
      ::File.umask(old_value) if umask
    end

    #
    # If we are currently initializing the resource, this will be true.
    #
    # Do NOT use this. It may be removed. It is for internal purposes only.
    # @api private
    attr_reader :resource_initializing

    def resource_initializing=(value)
      if value
        @resource_initializing = true
      else
        remove_instance_variable(:@resource_initializing)
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

      text = "# Declared in #{@source_line}\n\n"
      text << "#{resource_name}(\"#{name}\") do\n"

      all_props = {}
      self.class.state_properties.map do |p|

        all_props[p.name.to_s] = p.sensitive? ? '"*sensitive value suppressed*"' : value_to_text(p.get(self))
      rescue Chef::Exceptions::ValidationFailed
        # This space left intentionally blank, the property was probably required or had an invalid default.

      end

      ivars = instance_variables.map(&:to_sym) - HIDDEN_IVARS
      ivars.each do |ivar|
        iv = ivar.to_s.sub(/^@/, "")
        if all_props.key?(iv)
          text << "  #{iv} #{all_props[iv]}\n"
        elsif (value = instance_variable_get(ivar)) && !(value.respond_to?(:empty?) && value.empty?)
          text << "  #{iv} #{value_to_text(value)}\n"
        end
      end

      [@not_if, @only_if].flatten.each do |conditional|
        text << "  #{conditional.to_text}\n"
      end
      text << "end\n"
    end

    def value_to_text(value)
      value.respond_to?(:to_text) ? value.to_text : value.inspect
    end

    def inspect
      ivars = instance_variables.map(&:to_sym) - FORBIDDEN_IVARS
      ivars.inject("<#{self}") do |str, ivar|
        str << " #{ivar}: #{instance_variable_get(ivar).inspect}"
      end << ">"
    end

    # as_json does most of the to_json heavy lifted. It exists here in case activesupport
    # is loaded. activesupport will call as_json and skip over to_json. This ensure
    # json is encoded as expected
    def as_json(*a)
      safe_ivars = instance_variables.map(&:to_sym) - FORBIDDEN_IVARS
      instance_vars = {}
      safe_ivars.each do |iv|
        instance_vars[iv.to_s.sub(/^@/, "")] = instance_variable_get(iv)
      end
      {
        "json_class" => self.class.name,
        "instance_vars" => instance_vars,
      }
    end

    # Serialize this object as a hash
    def to_json(*a)
      results = as_json
      Chef::JSONCompat.to_json(results, *a)
    end

    def to_h
      # Grab all current state, then any other ivars (backcompat)
      result = {}
      self.class.state_properties.each do |p|
        result[p.name] = p.get(self)
      end
      safe_ivars = instance_variables.map(&:to_sym) - FORBIDDEN_IVARS
      safe_ivars.each do |iv|
        key = iv.to_s.sub(/^@/, "").to_sym
        next if result.key?(key)

        result[key] = instance_variable_get(iv)
      end
      result
    end

    alias_method :to_hash, :to_h

    def self.from_hash(o)
      resource = new(o["instance_vars"]["@name"])
      o["instance_vars"].each do |k, v|
        resource.instance_variable_set("@#{k}".to_sym, v)
      end
      resource
    end

    def self.json_create(o)
      from_hash(o)
    end

    def self.from_json(j)
      from_hash(Chef::JSONCompat.parse(j))
    end

    #
    # Resource Definition Interface (for resource developers)
    #

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
    def provider(arg = nil)
      klass = if arg.is_a?(String) || arg.is_a?(Symbol)
                lookup_provider_constant(arg)
              else
                arg
              end
      set_or_return(:provider, klass, kind_of: [ Class ])
    end

    def provider=(arg)
      provider(arg)
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
      state_properties(*names).map(&:name)
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
    def self.identity_property(name = nil)
      result = identity_properties(*Array(name))
      if result.size > 1
        raise Chef::Exceptions::MultipleIdentityError, "identity_property cannot be called on an object with more than one identity property (#{result.map(&:name).join(", ")})."
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
    def self.identity_attr(name = nil)
      property = identity_property(name)
      return nil unless property

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
    attr_writer :allowed_actions

    def allowed_actions(value = NOT_PASSED)
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
    # A hook called after a resource is created.  Meant to be overridden by
    # subclasses.
    #
    def after_created
      nil
    end

    #
    # The display name of this resource type, for printing purposes.
    #
    # Call `resource_name nil` to remove the resource name
    #
    # @param value [Symbol] The desired name of this resource type (e.g.
    #   `execute`), or `nil` if this class is abstract and has no resource_name.
    #
    # @return [Symbol] The name of this resource type (e.g. `:execute`).
    #
    def self.resource_name(name = NOT_PASSED)
      # Setter
      if name != NOT_PASSED
        @resource_name = name.to_sym rescue nil
      end

      @resource_name = nil unless defined?(@resource_name)
      @resource_name
    end

    def self.resource_name=(name)
      resource_name(name)
    end

    # If the resource's action should run in separated compile/converge mode.
    #
    # @param flag [Boolean] value to set unified_mode to
    # @return [Boolean] unified_mode value
    def self.unified_mode(flag = nil)
      @unified_mode = Chef::Config[:resource_unified_mode_default] if !defined?(@unified_mode) || @unified_mode.nil?
      @unified_mode = flag unless flag.nil?
      !!@unified_mode
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
    # Setting default_action will automatically add the action to
    # allowed_actions, if it isn't already there.
    #
    # Defaults to [:nothing].
    #
    # @param action_name [Symbol,Array<Symbol>] The default action (or series
    #   of actions) to use.
    #
    # @return [Array<Symbol>] The default actions for the resource.
    #
    def self.default_action(action_name = NOT_PASSED)
      unless action_name.equal?(NOT_PASSED)
        @default_action = Array(action_name).map(&:to_sym)
        self.allowed_actions |= @default_action
      end

      if defined?(@default_action) && @default_action
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
    # @param description [String] optional description for the action
    # @param recipe_block The recipe to run when the action is taken. This block
    #   takes no parameters, and will be evaluated in a new context containing:
    #
    #   - The resource's public and protected methods (including attributes)
    #   - The Chef Recipe DSL (file, etc.)
    #   - super() referring to the parent version of the action (if any)
    #
    # @return The Action class implementing the action
    #
    def self.action(action, description: nil, &recipe_block)
      action = action.to_sym
      declare_action_class
      action_class.action(action, &recipe_block)
      self.allowed_actions += [ action ]
      # Accept any non-nil description, which will correctly override
      # any specific inherited description.
      action_descriptions[action] = description unless description.nil?
      default_action action if Array(default_action) == [:nothing]
    end

    # Retrieve the description for a resource's action, if
    # any description has been included in the definition.
    #
    # @param action [Symbol,String] the action name
    # @return the description of the action provided, or nil if no description
    # was defined
    def self.action_description(action)
      action_descriptions[action.to_sym]
    end

    # @api private
    #
    # @return existing action description hash, or newly-initialized
    # hash containing action descriptions inherited from parent Resource,
    # if any.
    def self.action_descriptions
      @action_descriptions ||=
        superclass.respond_to?(:action_descriptions) ? superclass.action_descriptions.dup : { nothing: nil }
    end

    # Define a method to load up this resource's properties with the current
    # actual values.
    #
    # @param load_block The block to load.  Will be run in the context of a newly
    #   created resource with its identity values filled in.
    #
    def self.load_current_value(&load_block)
      define_method(:load_current_value!, &load_block)
    end

    # Call this in `load_current_value` to indicate that the value does not
    # exist and that `current_resource` should therefore be `nil`.
    #
    # @raise Chef::Exceptions::CurrentValueDoesNotExist
    #
    def current_value_does_not_exist!
      raise Chef::Exceptions::CurrentValueDoesNotExist
    end

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
    # The action class is a `Chef::Provider` which is created at Resource
    # class evaluation time when the Custom Resource is being constructed.
    #
    # This happens the first time the ruby parser hits an `action` or an
    # `action_class` method, the presence of either indicates that this is
    # going to be a Chef-12.5 custom resource.  If we never see one of these
    # directives then we are constructing an old-style Resource+Provider or
    # LWRP or whatever.
    #
    # If a block is passed, the action_class is always created and the block is
    # run inside it.
    #
    def self.action_class(&block)
      @action_class ||= declare_action_class
      @action_class.class_eval(&block) if block
      @action_class
    end

    # Returns true or false based on if the resource is a custom resource.  The
    # top-level Chef::Resource is not a chef resource.  This value is inherited.
    #
    # @return [Boolean] if the resource is a custom_resource
    def self.custom_resource?
      false
    end

    # This sets the resource to being a custom resource, and does so in a way
    # that automatically inherits to all subclasses via defining a method on
    # the class (class variables and class instance variables don't have the
    # correct semantics here, this is a poor man's activesupport class_attribute)
    #
    # @api private
    def self.is_custom_resource!
      define_singleton_method :custom_resource? do
        true
      end
    end

    # Ensure the action class actually gets created. This is called
    # when the user does `action :x do ... end`.
    #
    # @api private
    def self.declare_action_class
      @action_class ||=
        begin
          is_custom_resource!
          base_provider =
            if superclass.custom_resource?
              superclass.action_class
            else
              ActionClass
            end

          resource_class = self
          Class.new(base_provider) do
            self.resource_class = resource_class
          end
        end
    end

    # Set or return if this resource is in preview mode.
    #
    # This only has value in the resource_inspector to mark a resource as being new-to-chef-core.
    # Its meaning is probably more equivalent to "experimental" in that the API might change even
    # in minor versions due to bugfixing and is NOT considered "stable" yet.
    #
    # @param value [nil, Boolean] If nil, get the current value. If not nil, set
    #   the value of the flag.
    # @return [Boolean]
    def self.preview_resource(value = nil)
      @preview_resource = false unless defined?(@preview_resource)
      @preview_resource = value unless value.nil?
      @preview_resource
    end

    #
    # Internal Resource Interface (for Chef)
    #

    # FORBIDDEN_IVARS do not show up when the resource is converted to JSON (ie. hidden from data_collector and sending to the chef server via #to_json/to_h/as_json/inspect)
    FORBIDDEN_IVARS = %i{@run_context @logger @not_if @only_if @enclosing_provider @description @introduced @examples @validation_message @deprecated @default_description @skip_docs @executed_by_runner @action_descriptions}.freeze
    # HIDDEN_IVARS do not show up when the resource is displayed to the user as text (ie. in the error inspector output via #to_text)
    HIDDEN_IVARS = %i{@allowed_actions @resource_name @source_line @run_context @logger @name @not_if @only_if @elapsed_time @enclosing_provider @description @introduced @examples @validation_message @deprecated @default_description @skip_docs @executed_by_runner @action_descriptions}.freeze

    include Chef::Mixin::ConvertToClassName
    extend Chef::Mixin::ConvertToClassName

    # XXX: this is required for definition params inside of the scope of a
    # subresource to work correctly.
    attr_accessor :params

    # @return [Chef::RunContext] The run context for this Resource.  This is
    # where the context for the current Chef run is stored, including the node
    # and the resource collection.
    #
    attr_accessor :run_context

    # @return [Mixlib::Log::Child] The logger for this resources. This is a child
    # of the run context's logger, if one exists.
    #
    attr_reader :logger

    # @return [String] The cookbook this resource was declared in.
    #
    attr_accessor :cookbook_name

    # @return [String] The recipe this resource was declared in.
    #
    attr_accessor :recipe_name

    # @return [Chef::Provider] The provider this resource was declared in (if
    #   it was declared in an LWRP).  When you call methods that do not exist
    #   on this Resource, Chef will try to call the method on the provider
    #   as well before giving up.
    #
    attr_accessor :enclosing_provider

    # @return [String] The source line where this resource was declared.
    #   Expected to come from caller() or a stack trace, it usually follows one
    #   of these formats:
    #     /some/path/to/file.rb:80:in `wombat_tears'
    #     C:/some/path/to/file.rb:80 in 1`wombat_tears'
    #
    attr_accessor :source_line

    # @return [String] The actual name that was used to create this resource.
    #   Sometimes, when you say something like `package 'blah'`, the system will
    #   create a different resource (i.e. `YumPackage`).  When this happens, the
    #   user will expect to see the thing they wrote, not the type that was
    #   returned.  May be `nil`, in which case callers should read #resource_name.
    #   See #declared_key.
    #
    attr_accessor :declared_type

    # Iterates over all immediate and delayed notifications, calling
    # resolve_resource_reference on each in turn, causing them to
    # resolve lazy/forward references.
    #
    def resolve_notification_references(always_raise = false)
      run_context.before_notifications(self).each do |n|
        n.resolve_resource_reference(run_context.resource_collection, true)
      end

      run_context.immediate_notifications(self).each do |n|
        n.resolve_resource_reference(run_context.resource_collection, always_raise)
      end

      run_context.delayed_notifications(self).each do |n|
        n.resolve_resource_reference(run_context.resource_collection, always_raise)
      end
    end

    # Helper for #notifies
    def notifies_before(action, resource_spec)
      run_context.notifies_before(Notification.new(resource_spec, action, self, run_context.unified_mode))
    end

    # Helper for #notifies
    def notifies_immediately(action, resource_spec)
      run_context.notifies_immediately(Notification.new(resource_spec, action, self, run_context.unified_mode))
    end

    # Helper for #notifies
    def notifies_delayed(action, resource_spec)
      run_context.notifies_delayed(Notification.new(resource_spec, action, self, run_context.unified_mode))
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
      @@sorted_descendants ||= descendants.sort_by(&:to_s)
    end

    def self.inherited(child)
      super
      @@sorted_descendants = nil
    end

    # If an unknown method is invoked, determine whether the enclosing Provider's
    # lexical scope can fulfill the request. E.g. This happens when the Resource's
    # block invokes new_resource.
    def method_missing(method_symbol, *args, &block)
      if enclosing_provider && enclosing_provider.respond_to?(method_symbol)
        enclosing_provider.send(method_symbol, *args, &block)
      else
        raise NoMethodError, "undefined method `#{method_symbol}' for #{self.class}"
      end
    end

    # This API can be used for backcompat to do:
    #
    # chef_version_for_provides "< 14.0" if defined?(:chef_version_for_provides)
    #
    # For core chef versions that do not support chef_version: in provides lines.
    #
    # Since resource_name calls provides the generally correct way of doing this is
    # to do `chef_version_for_provides` first, then `resource_name` and then
    # any additional options `provides` lines.
    #
    # Once we no longer care about supporting chef < 14.4 then we can deprecate
    # this API.
    #
    # @param arg [String] version constraint to match against (e.g. "> 14")
    #
    def self.chef_version_for_provides(constraint = NOT_PASSED)
      @chef_version_for_provides = constraint unless constraint == NOT_PASSED
      @chef_version_for_provides ||= nil
    end

    # Mark this resource as providing particular DSL.
    #
    # Resources have an automatic DSL based on their resource_name, equivalent to
    # `provides :resource_name` (providing the resource on all OS's).  If you
    # declare a `provides` with the given resource_name, it *replaces* that
    # provides (so that you can provide your resource DSL only on certain OS's).
    #
    def self.provides(name, **options, &block)
      name = name.to_sym

      # deliberately do not go through the accessor here
      @resource_name = name if resource_name.nil?

      if chef_version_for_provides && !options.include?(:chef_version)
        options[:chef_version] = chef_version_for_provides
      end

      result = Chef.resource_handler_map.set(name, self, **options, &block)
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

    def before_notifications
      run_context.before_notifications(self)
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

    def self.description(description = "NOT_PASSED")
      if description != "NOT_PASSED"
        @description = description
      end
      @description
    end

    def self.introduced(introduced = "NOT_PASSED")
      if introduced != "NOT_PASSED"
        @introduced = introduced
      end
      @introduced
    end

    def self.examples(examples = "NOT_PASSED")
      if examples != "NOT_PASSED"
        @examples = examples
      end
      @examples
    end

    def self.deprecated(deprecated = "NOT_PASSED")
      if deprecated != "NOT_PASSED"
        @deprecated = true
        @deprecated_message = deprecated
      end
      @deprecated
    end

    def self.skip_docs(skip_docs = "NOT_PASSED")
      if skip_docs != "NOT_PASSED"
        @skip_docs = skip_docs
      end
      @skip_docs
    end

    def self.default_description(default_description = "NOT_PASSED")
      if default_description != "NOT_PASSED"
        @default_description = default_description
      end
      @default_description
    end

    # Use a partial code fragment.  This can be used for code sharing between multiple resources.
    #
    # Do not wrap the code fragment in a class or module.  It also does not support the use of super
    # to subclass any methods defined in the fragment, the methods will just be overwritten.
    #
    # @param partial [String] the code fragment to eval against the class
    #
    def self.use(partial)
      dirname = ::File.dirname(partial)
      basename = ::File.basename(partial, ".rb")
      basename = basename[1..] if basename.start_with?("_")
      class_eval IO.read(::File.expand_path("#{dirname}/_#{basename}.rb", ::File.dirname(caller_locations.first.absolute_path)))
    end

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
          logger.debug("Skipping #{self} due to #{conditional.description}")
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

    # Returns the class with the given resource_name.
    #
    # NOTE: Chef::Resource.resource_matching_short_name(:package) returns
    # Chef::Resource::Package, while on rhel the API call
    # Chef::Resource.resource_for_node(:package, node) will return
    # Chef::Resource::YumPackage -- which is probably what you really
    # want.  This API should most likely be removed or changed to call
    # resource_for_node.
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    #
    def self.resource_matching_short_name(short_name)
      Chef::ResourceResolver.resolve(short_name)
    end

    # @api private
    def lookup_provider_constant(name, action = :nothing)
      # XXX: "name" is probably a poor choice of name here, ideally this would be nil, but we need to
      # fix resources so that nil or empty names work (also solving the apt_update "doesn't matter one bit"
      # problem).  WARNING: this string is not a public API and should not be referenced (e.g. in provides blocks)
      # and may change at any time.  If you've found this comment you're also probably very lost and should maybe
      # consider using `declare_resource :whatever` instead of trying to set `provider :whatever` on a resource, or in some
      # other way reconsider what you're trying to do, since you're likely trying to force a bad design that we
      # can't/won't support.
      self.class.resource_for_node(name, node).new("name", run_context).provider_for_action(action).class
    end

    # This is used to suppress the "(up to date)" message in the doc formatter
    # for the log resource (where it is nonsensical).
    #
    # This is not exactly a private API, but its doubtful there exist many other sane
    # use cases for this.
    #
    def suppress_up_to_date_messages?
      false
    end
  end
end

# Requiring things at the bottom breaks cycles
require_relative "chef_class"
