#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2016, 2009-2017, Chef Software Inc.
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

require "chef/mixin/from_file"
require "chef/mixin/convert_to_class_name"
require "chef/mixin/enforce_ownership_and_permissions"
require "chef/mixin/why_run"
require "chef/mixin/shell_out"
require "chef/mixin/provides"
require "chef/dsl/core"
require "chef/platform/service_helpers"
require "chef/node_map"
require "forwardable"

class Chef
  class Provider
    require "chef/mixin/why_run"
    require "chef/mixin/provides"

    attr_accessor :new_resource
    attr_accessor :current_resource
    attr_accessor :run_context

    attr_reader :recipe_name
    attr_reader :cookbook_name

    include Chef::Mixin::WhyRun
    extend Chef::Mixin::Provides

    # includes the "core" DSL and not the "recipe" DSL by design
    include Chef::DSL::Core

    # supports the given resource and action (late binding)
    def self.supports?(resource, action)
      true
    end

    # Defines an action method on the provider, running the block to compile the
    # resources, converging them, and then checking if any were updated (and
    # updating new-resource if so)
    #
    # @since 13.0
    # @param name [String, Symbol] Name of the action to define.
    # @param block [Proc] Body of the action.
    # @return [void]
    def self.action(name, &block)
      # We need the block directly in a method so that `super` works.
      define_method("compile_action_#{name}", &block)
      class_eval <<-EOM
        def action_#{name}
          compile_and_converge_action { compile_action_#{name} }
        end
      EOM
    end

    # Deprecation stub for the old use_inline_resources mode.
    #
    # @return [void]
    def self.use_inline_resources
      # Uncomment this in Chef 13.6.
      # Chef.deprecated(:use_inline_resources, "The use_inline_resources mode is no longer optional and the line enabling it can be removed")
    end

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
      true
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
      raise Chef::Exceptions::Override, "You must override load_current_resource in #{self}"
    end

    def define_resource_requirements
    end

    def cleanup_after_converge
    end

    def action_nothing
      Chef::Log.debug("Doing nothing for #{@new_resource}")
      true
    end

    def events
      run_context.events
    end

    def run_action(action = nil)
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

    # Create a child run_context, compile the block, and converge it.
    #
    # @api private
    def compile_and_converge_action(&block)
      old_run_context = run_context
      @run_context = run_context.create_child
      return_value = instance_eval(&block)
      Chef::Runner.new(run_context).converge
      return_value
    ensure
      if run_context.resource_collection.any? { |r| r.updated? }
        new_resource.updated_by_last_action(true)
      end
      @run_context = old_run_context
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
          properties_str = if new_resource.sensitive
                             specified_properties.join(", ")
                           else
                             specified_properties.map { |p| "#{p}=#{new_resource.send(p).inspect}" }.join(", ")
                           end
          Chef::Log.debug("Skipping update of #{new_resource}: has not changed any of the specified properties #{properties_str}.")
          return false
        end

        # Print the pretty green text and run the block
        property_size = modified.map { |p| p.size }.max
        modified.map! do |p|
          properties_str = if new_resource.sensitive
                             "(suppressed sensitive property)"
                           else
                             "#{new_resource.send(p).inspect} (was #{current_resource.send(p).inspect})"
                           end
          "  set #{p.to_s.ljust(property_size)} to #{properties_str}"
        end
        converge_by([ "update #{current_resource.identity}" ] + modified, &converge_block)

      else
        # The resource doesn't exist. Mark that we are *creating* this, and
        # write down any properties we are setting.
        property_size = properties.map { |p| p.size }.max
        created = properties.map do |property|
          default = " (default value)" unless new_resource.property_is_set?(property)
          properties_str = if new_resource.sensitive
                             "(suppressed sensitive property)"
                           else
                             new_resource.send(property).inspect
                           end
          "  set #{property.to_s.ljust(property_size)} to #{properties_str}#{default}"
        end

        converge_by([ "create #{new_resource.identity}" ] + created, &converge_block)
      end
      true
    end

    def self.provides(short_name, opts = {}, &block)
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
    def self.include_resource_dsl?
      false
    end

    # Create the resource DSL module that forwards resource methods to new_resource
    #
    # @api private
    def self.include_resource_dsl_module(resource)
      if include_resource_dsl? && !defined?(@included_resource_dsl_module)
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
                # FIXME:  DEPRECATE THIS IN CHEF 13.1
                #
                # If no arguments were passed, we process "get" by defaulting
                # the value to current_resource, not new_resource. This helps
                # avoid issues where resources accidentally overwrite perfectly
                # valid stuff with default values.
                #
                # This magic is to make this kind of thing easy:
                #
                # FileUtils.chown new_resource.mode.nil? ? current_resource.mode : new_resource.mode, new_resource.path
                #
                # We do this in the file provider where we need to construct a new filesystem object and
                # when the new_resource is nil/default that means "preserve the current stuff" and does not
                # mean to ignore it which will wind up defaulting to changing the file to have a "root"
                # ownership if anything else changes.  Its kind of overly clever and magical, and most likely
                # gets the use case wrong where someone has a property that they really mean to default to
                # some value which /should/ get set if its left as the default and where the default is
                # meant to be declarative.  Instead of property_is_set? we should most likely be using
                # nil? but we're going to deprecate all of it anyway.  Just type out what you really mean longhand.
                #
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

  end
end

# Requiring things at the bottom breaks cycles
require "chef/chef_class"
require "chef/mixin/why_run"
require "chef/resource_collection"
require "chef/runner"
