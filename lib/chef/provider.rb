#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/mixin/from_file'
require 'chef/mixin/convert_to_class_name'
require 'chef/mixin/enforce_ownership_and_permissions'
require 'chef/mixin/why_run'
require 'chef/mixin/shell_out'
require 'chef/mixin/powershell_out'
require 'chef/mixin/provides'
require 'chef/platform/service_helpers'
require 'chef/node_map'
require 'forwardable'

class Chef
  class Provider
    require 'chef/mixin/why_run'
    require 'chef/mixin/shell_out'
    require 'chef/mixin/provides'
    include Chef::Mixin::WhyRun
    include Chef::Mixin::ShellOut
    include Chef::Mixin::PowershellOut
    extend Chef::Mixin::Provides

    # supports the given resource and action (late binding)
    def self.supports?(resource, action)
      true
    end

    attr_accessor :new_resource
    attr_accessor :current_resource
    attr_accessor :run_context

    attr_reader :recipe_name
    attr_reader :cookbook_name

    #--
    # TODO: this should be a reader, and the action should be passed in the
    # constructor; however, many/most subclasses override the constructor so
    # changing the arity would be a breaking change. Change this at the next
    # break, e.g., Chef 11.
    attr_accessor :action

    def initialize(new_resource, run_context)
      @new_resource = new_resource
      @action = action
      @current_resource = nil
      @run_context = run_context
      @converge_actions = nil

      @recipe_name = nil
      @cookbook_name = nil
      self.class.include_resource_dsl_module(new_resource)
    end

    def whyrun_mode?
      Chef::Config[:why_run]
    end

    def whyrun_supported?
      false
    end

    def node
      run_context && run_context.node
    end

    # Used by providers supporting embedded recipes
    def resource_collection
      run_context && run_context.resource_collection
    end

    def cookbook_name
      new_resource.cookbook_name
    end

    def check_resource_semantics!
    end

    def load_current_resource
      raise Chef::Exceptions::Override, "You must override load_current_resource in #{self.to_s}"
    end

    def define_resource_requirements
    end

    def cleanup_after_converge
    end

    def action_nothing
      Chef::Log.debug("Doing nothing for #{@new_resource.to_s}")
      true
    end

    def events
      run_context.events
    end

    def run_action(action=nil)
      @action = action unless action.nil?

      # TODO: it would be preferable to get the action to be executed in the
      # constructor...

      check_resource_semantics!

      # user-defined LWRPs may include unsafe load_current_resource methods that cannot be run in whyrun mode
      if whyrun_mode? && !whyrun_supported?
        events.resource_current_state_load_bypassed(@new_resource, @action, @current_resource)
      else
        load_current_resource
        events.resource_current_state_loaded(@new_resource, @action, @current_resource)
      end

      define_resource_requirements
      process_resource_requirements

      # user-defined providers including LWRPs may
      # not include whyrun support - if they don't support it
      # we can't execute any actions while we're running in
      # whyrun mode. Instead we 'fake' whyrun by documenting that
      # we can't execute the action.
      # in non-whyrun mode, this will still cause the action to be
      # executed normally.
      if whyrun_mode? && (!whyrun_supported? || requirements.action_blocked?(@action))
        events.resource_bypassed(@new_resource, @action, self)
      else
        send("action_#{@action}")
      end

      set_updated_status

      cleanup_after_converge
    end

    def process_resource_requirements
      requirements.run(:all_actions) unless @action == :nothing
      requirements.run(@action)
    end

    def resource_updated?
      !converge_actions.empty? || @new_resource.updated_by_last_action?
    end

    def set_updated_status
      if !resource_updated?
        events.resource_up_to_date(@new_resource, @action)
      else
        events.resource_updated(@new_resource, @action)
        new_resource.updated_by_last_action(true)
      end
    end

    def requirements
      @requirements ||= ResourceRequirements.new(@new_resource, run_context)
    end

    def converge_by(descriptions, &block)
      converge_actions.add_action(descriptions, &block)
    end

    #
    # Handle patchy convergence safely.
    #
    # - Does *not* call the block if the current_resource's properties match
    #   the properties the user specified on the resource.
    # - Calls the block if current_resource does not exist
    # - Calls the block if the user has specified any properties in the resource
    #   whose values are *different* from current_resource.
    # - Does *not* call the block if why-run is enabled (just prints out text).
    # - Prints out automatic green text saying what properties have changed.
    #
    # @param properties An optional list of property names (symbols). If not
    #   specified, `new_resource.class.state_properties` will be used.
    # @param converge_block The block to do the converging in.
    #
    # @return [Boolean] whether the block was executed.
    #
    def converge_if_changed(*properties, &converge_block)
      if !converge_block
        raise ArgumentError, "converge_if_changed must be passed a block!"
      end

      properties = new_resource.class.state_properties.map { |p| p.name } if properties.empty?
      properties = properties.map { |p| p.to_sym }
      if current_resource
        # Collect the list of modified properties
        specified_properties = properties.select { |property| new_resource.property_is_set?(property) }
        modified = specified_properties.select { |p| new_resource.send(p) != current_resource.send(p) }
        if modified.empty?
          Chef::Log.debug("Skipping update of #{new_resource.to_s}: has not changed any of the specified properties #{specified_properties.map { |p| "#{p}=#{new_resource.send(p).inspect}" }.join(", ")}.")
          return false
        end

        # Print the pretty green text and run the block
        property_size = modified.map { |p| p.size }.max
        modified = modified.map { |p| "  set #{p.to_s.ljust(property_size)} to #{new_resource.send(p).inspect} (was #{current_resource.send(p).inspect})" }
        converge_by([ "update #{current_resource.identity}" ] + modified, &converge_block)

      else
        # The resource doesn't exist. Mark that we are *creating* this, and
        # write down any properties we are setting.
        property_size = properties.map { |p| p.size }.max
        created = []
        properties.each do |property|
          if new_resource.property_is_set?(property)
            created << "  set #{property.to_s.ljust(property_size)} to #{new_resource.send(property).inspect}"
          else
            created << "  set #{property.to_s.ljust(property_size)} to #{new_resource.send(property).inspect} (default value)"
          end
        end

        converge_by([ "create #{new_resource.identity}" ] + created, &converge_block)
      end
      true
    end

    def self.provides(short_name, opts={}, &block)
      Chef.provider_handler_map.set(short_name, self, opts, &block)
    end

    def self.provides?(node, resource)
      Chef::ProviderResolver.new(node, resource, :nothing).provided_by?(self)
    end

    #
    # Include attributes, public and protected methods from this Resource in
    # the provider.
    #
    # If this is set to true, delegate methods are included in the provider so
    # that you can call (for example) `attrname` and it will call
    # `new_resource.attrname`.
    #
    # The actual include does not happen until the first time the Provider
    # is instantiated (so that we don't have to worry about load order issues).
    #
    # @param include_resource_dsl [Boolean] Whether to include resource DSL or
    #   not (defaults to `false`).
    #
    def self.include_resource_dsl(include_resource_dsl)
      @include_resource_dsl = include_resource_dsl
    end

    # Create the resource DSL module that forwards resource methods to new_resource
    #
    # @api private
    def self.include_resource_dsl_module(resource)
      if @include_resource_dsl && !defined?(@included_resource_dsl_module)
        provider_class = self
        @included_resource_dsl_module = Module.new do
          extend Forwardable
          define_singleton_method(:to_s) { "forwarder module for #{provider_class}" }
          define_singleton_method(:inspect) { to_s }
          # Add a delegator for each explicit property that will get the *current* value
          # of the property by default instead of the *actual* value.
          resource.class.properties.each do |name, property|
            class_eval(<<-EOM, __FILE__, __LINE__)
              def #{name}(*args, &block)
                # If no arguments were passed, we process "get" by defaulting
                # the value to current_resource, not new_resource. This helps
                # avoid issues where resources accidentally overwrite perfectly
                # valid stuff with default values.
                if args.empty? && !block
                  if !new_resource.property_is_set?(__method__) && current_resource
                    return current_resource.public_send(__method__)
                  end
                end
                new_resource.public_send(__method__, *args, &block)
              end
            EOM
          end
          dsl_methods =
             resource.class.public_instance_methods +
             resource.class.protected_instance_methods -
             provider_class.instance_methods -
             resource.class.properties.keys
          def_delegators(:new_resource, *dsl_methods)
        end
        include @included_resource_dsl_module
      end
    end

    # Enables inline evaluation of resources in provider actions.
    #
    # Without this option, any resources declared inside the Provider are added
    # to the resource collection after the current position at the time the
    # action is executed. Because they are added to the primary resource
    # collection for the chef run, they can notify other resources outside
    # the Provider, and potentially be notified by resources outside the Provider
    # (but this is complicated by the fact that they don't exist until the
    # provider executes). In this mode, it is impossible to correctly set the
    # updated_by_last_action flag on the parent Provider resource, since it
    # executes and returns before its component resources are run.
    #
    # With this option enabled, each action creates a temporary run_context
    # with its own resource collection, evaluates the action's code in that
    # context, and then converges the resources created. If any resources
    # were updated, then this provider's new_resource will be marked updated.
    #
    # In this mode, resources created within the Provider cannot interact with
    # external resources via notifies, though notifications to other
    # resources within the Provider will work. Delayed notifications are executed
    # at the conclusion of the provider's action, *not* at the end of the
    # main chef run.
    #
    # This mode of evaluation is experimental, but is believed to be a better
    # set of tradeoffs than the append-after mode, so it will likely become
    # the default in a future major release of Chef.
    #
    def self.use_inline_resources
      extend InlineResources::ClassMethods
      include InlineResources
    end

    # Chef::Provider::InlineResources
    # Implementation of inline resource convergence for providers. See
    # Provider.use_inline_resources for a longer explanation.
    #
    # This code is restricted to a module so that it can be selectively
    # applied to providers on an opt-in basis.
    #
    # @api private
    module InlineResources

      # Our run context is a child of the main run context; that gives us a
      # whole new resource collection and notification set.
      def initialize(resource, run_context)
        super(resource, run_context.create_child)
      end

      # Class methods for InlineResources. Overrides the `action` DSL method
      # with one that enables inline resource convergence.
      #
      # @api private
      module ClassMethods
        # Defines an action method on the provider, running the block to
        # compile the resources, converging them, and then checking if any
        # were updated (and updating new-resource if so)
        def action(name, &block)
          # We first try to create the method using "def method_name", which is
          # preferred because it actually shows up in stack traces. If that
          # fails, we try define_method.
          begin
            class_eval <<-EOM, __FILE__, __LINE__+1
              def action_#{name}
                return_value = compile_action_#{name}
                Chef::Runner.new(run_context).converge
                return_value
              ensure
                if run_context.resource_collection.any? {|r| r.updated? }
                  new_resource.updated_by_last_action(true)
                end
              end
            EOM
          rescue SyntaxError
            define_method("action_#{name}") do
              begin
                return_value = send("compile_action_#{name}")
                Chef::Runner.new(run_context).converge
                return_value
              ensure
                if run_context.resource_collection.any? {|r| r.updated? }
                  new_resource.updated_by_last_action(true)
                end
              end
            end
          end
          # We put the action in its own method so that super() works.
          define_method("compile_action_#{name}", &block)
        end
      end

      require 'chef/dsl/recipe'
      include Chef::DSL::Recipe::FullDSL
    end

    protected

    def converge_actions
      @converge_actions ||= ConvergeActions.new(@new_resource, run_context, @action)
    end

    def recipe_eval(&block)
      # This block has new resource definitions within it, which
      # essentially makes it an in-line Chef run. Save our current
      # run_context and create one anew, so the new Chef run only
      # executes the embedded resources.
      #
      # TODO: timh,cw: 2010-5-14: This means that the resources within
      # this block cannot interact with resources outside, e.g.,
      # manipulating notifies.

      converge_by ("evaluate block and run any associated actions") do
        saved_run_context = run_context
        begin
          @run_context = run_context.create_child
          instance_eval(&block)
          Chef::Runner.new(run_context).converge
        ensure
          @run_context = saved_run_context
        end
      end
    end

    module DeprecatedLWRPClass
      def const_missing(class_name)
        if deprecated_constants[class_name.to_sym]
          Chef.log_deprecation("Using an LWRP provider by its name (#{class_name}) directly is no longer supported in Chef 12 and will be removed.  Use Chef::ProviderResolver.new(node, resource, action) instead.")
          deprecated_constants[class_name.to_sym]
        else
          raise NameError, "uninitialized constant Chef::Provider::#{class_name}"
        end
      end

      # @api private
      def register_deprecated_lwrp_class(provider_class, class_name)
        # Register Chef::Provider::MyProvider with deprecation warnings if you
        # try to access it
        if Chef::Provider.const_defined?(class_name, false)
          Chef::Log.warn "Chef::Provider::#{class_name} already exists!  Cannot create deprecation class for #{provider_class}"
        else
          deprecated_constants[class_name.to_sym] = provider_class
        end
      end

      private

      def deprecated_constants
        @deprecated_constants ||= {}
      end
    end
    extend DeprecatedLWRPClass
  end
end

# Requiring things at the bottom breaks cycles
require 'chef/chef_class'
require 'chef/mixin/why_run'
require 'chef/resource_collection'
require 'chef/runner'
