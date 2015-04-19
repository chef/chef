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
require 'chef/dsl/resources'
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
require 'chef/mixin/provides'

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
      name(name)
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
    def name(name=nil)
      if !name.nil?
        if name.is_a?(Array)
          @name = name.join(', ')
        else
          @name = name.to_s
        end
      end
      @name
    end

    #
    # The action or actions that will be taken when this resource is run.
    #
    # @param arg [Array[Symbol], Symbol] A list of actions (e.g. `:create`)
    # @return [Array[Symbol]] the list of actions.
    #
    def action(arg=nil)
      if arg
        action_list = arg.kind_of?(Array) ? arg : [ arg ]
        action_list = action_list.collect { |a| a.to_sym }
        action_list.each do |action|
          validate(
            { action: action },
            { action: { kind_of: Symbol, equal_to: @allowed_actions } }
          )
        end
        @action = action_list
      else
        @action
      end
    end

    #
    # Sets up a notification that will run a particular action on another resource
    # if and when *this* resource is updated by an action.
    #
    # If the action does nothing--does not update this resource, the
    # notification never triggers.)
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
    # @return [Hash{Symbol => Object}] A Hash of attribute => value for the
    #   Resource class's `state_attrs`.
    def state_for_resource_reporter
      self.class.state_attrs.inject({}) do |state_attrs, attr_name|
        state_attrs[attr_name] = send(attr_name)
        state_attrs
      end
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
    # The value of the identity attribute, if declared. Falls back to #name if
    # no identity attribute is declared.
    #
    # @return The value of the identity attribute.
    #
    def identity
      if identity_attr = self.class.identity_attr
        send(identity_attr)
      else
        name
      end
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
    def epic_fail(arg=nil)
      ignore_failure(arg)
    end

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
    # If this is not set, `provider_for_action` will dynamically determine the
    # provider.
    #
    # @param arg [String, Symbol, Class] Sets the provider class for this resource.
    #   If passed a String or Symbol, e.g. `:file` or `"file"`, looks up the
    #   provider based on the name.
    # @return The provider class for this resource.
    #
    def provider(arg=nil)
      klass = if arg.kind_of?(String) || arg.kind_of?(Symbol)
        lookup_provider_constant(arg)
      else
        arg
      end
      set_or_return(:provider, klass, kind_of: [ Class ])
    end
    def provider=(arg)
      provider(arg)
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
    # The DSL name of this resource (e.g. `package` or `yum_package`)
    #
    # @return [String] The DSL name of this resource.
    def self.dsl_name
      if name
        name = self.name.split('::')[-1]
        convert_to_snake_case(name)
      end
    end

    #
    # The name of this resource (e.g. `file`)
    #
    # @return [String] The name of this resource.
    #
    attr_reader :resource_name

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
    def self.provider_base(arg=nil)
      @provider_base ||= arg
      @provider_base ||= Chef::Provider
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
      # NOTE: that we do not support unregistering classes as descendents like
      # we used to for LWRP unloading because that was horrible and removed in
      # Chef-12.
      alias :resource_classes :descendants
      alias :find_subclass_by_name :find_descendants_by_name
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

    # Cause each subclass to register itself with the DSL
    def self.inherited(subclass)
      super
      if subclass.dsl_name
        subclass.provides subclass.dsl_name.to_sym
        subclass.instance_eval { @auto_provides = subclass.dsl_name.to_sym }
      end
    end

    def self.provides(name, *args, &block)
      # If the user specifies provides, then we get rid of the auto-provided DSL
      # and let them specify what they want
      if @auto_provides
        @auto_provides = auto_provides = nil
        does_not_provide(auto_provides)
      end

      super

      Chef::DSL::Resources.add_resource_dsl(name)
    end

    def self.does_not_provide(name=nil)
      name ||= dsl_name
      if @auto_provides
        @auto_provides = auto_provides = nil
        does_not_provide(auto_provides) if name != auto_provides
      end

      super

      # Get rid of the DSL if this was the only resource that used it
      if !Chef::Resource.resource_matching_short_name(name)
        Chef::DSL::Resources.remove_resource_dsl(name)
      end
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
      require 'chef/provider_resolver'
      provider = Chef::ProviderResolver.new(node, self, action).resolve.new(self, run_context)
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
      klass = Chef::ResourceResolver.new(node, short_name).resolve
      raise Chef::Exceptions::NoSuchResourceType.new(short_name, node) if klass.nil?
      klass
    end

    #
    # Returns the class of a Chef::Resource based on the short name
    # Only returns the *canonical* class with the given name, not the one that
    # would be picked by the ResourceResolver.
    #
    # ==== Parameters
    # short_name<Symbol>:: short_name of the resource (ie :directory)
    #
    # === Returns
    # <Chef::Resource>:: returns the proper Chef::Resource class
    def self.resource_matching_short_name(short_name)
      Chef::ResourceResolver.new(Chef::Node.new, short_name).resolve
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

require 'chef/resource_resolver'
