#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "resource_collection"
require_relative "cookbook_version"
require_relative "node"
require_relative "role"
require_relative "log"
require_relative "recipe"
require_relative "run_context/cookbook_compiler"
require_relative "event_dispatch/events_output_stream"
require_relative "compliance/input_collection"
require_relative "compliance/waiver_collection"
require_relative "compliance/profile_collection"
require_relative "train_transport"
require_relative "exceptions"
require "forwardable" unless defined?(Forwardable)
autoload :Set, "set"

class Chef

  # Value object that loads and tracks the context of a Chef run
  class RunContext
    extend Forwardable

    #
    # Global state
    #

    # Common rest object for using to talk to the Chef Server, this strictly 'validates' utf8
    # and will throw.  (will be nil on solo-legacy runs)
    #
    # @return [Chef::ServerAPI]
    #
    attr_accessor :rest

    # Common rest object for using to talk to the Chef Server, this has utf8 sanitization turned
    # on and will replace invalid utf8 with valid characters.  (will be nil on solo-legacy runs)
    #
    # @return [Chef::ServerAPI]
    #
    attr_accessor :rest_clean

    #
    # The node for this run
    #
    # @return [Chef::Node]
    #
    attr_reader :node

    #
    # The set of cookbooks involved in this run
    #
    # @return [Chef::CookbookCollection]
    #
    attr_reader :cookbook_collection

    #
    # Resource Definitions for this run. Populated when the files in
    # +definitions/+ are evaluated (this is triggered by #load).
    #
    # @return [Array[Chef::ResourceDefinition]]
    #
    attr_reader :definitions

    # Event dispatcher for this run.
    #
    # @return [Chef::EventDispatch::Dispatcher]
    #
    attr_accessor :events

    # Hash of factoids for a reboot request.
    #
    # @return [Hash]
    #
    attr_accessor :reboot_info

    #
    # Scoped state
    #

    # The parent run context.
    #
    # @return [Chef::RunContext] The parent run context, or `nil` if this is the
    #   root context.
    #
    attr_reader :parent_run_context

    # The root run context.
    #
    # @return [Chef::RunContext] The root run context.
    #
    def root_run_context
      rc = self
      rc = rc.parent_run_context until rc.parent_run_context.nil?
      rc
    end

    # The collection of resources intended to be converged (and able to be
    # notified).
    #
    # @return [Chef::ResourceCollection]
    #
    # @see CookbookCompiler
    #
    attr_reader :resource_collection

    # Handle to the global action_collection of executed actions for reporting / data_collector /etc
    #
    # @return [Chef::ActionCollection]
    #
    attr_accessor :action_collection

    # Handle to the global profile_collection of inspec profiles for the compliance phase
    #
    # @return [Chef::Compliance::ProfileCollection]
    #
    attr_accessor :profile_collection

    # Handle to the global waiver_collection of inspec waiver files for the compliance phase
    #
    # @return [Chef::Compliance::WaiverCollection]
    #
    attr_accessor :waiver_collection

    # Handle to the global input_collection of inspec input files for the compliance phase
    #
    # @return [Chef::Compliance::inputCollection]
    #
    attr_accessor :input_collection

    #
    # @return [Symbol, nil]
    #
    attr_accessor :default_secret_service

    #
    # @return [Hash<Symbol,Object>]
    #
    attr_accessor :default_secret_config

    # Pointer back to the Chef::Runner that created this
    #
    attr_accessor :runner

    #
    # Notification handling
    #

    # A Hash containing the before notifications triggered by resources
    # during the converge phase of the chef run.
    #
    # @return [Hash[String, Array[Chef::Resource::Notification]]] A hash from
    #   <notifying resource name> => <list of notifications it sent>
    #
    attr_reader :before_notification_collection

    # A Hash containing the immediate notifications triggered by resources
    # during the converge phase of the chef run.
    #
    # @return [Hash[String, Array[Chef::Resource::Notification]]] A hash from
    #   <notifying resource name> => <list of notifications it sent>
    #
    attr_reader :immediate_notification_collection

    # A Hash containing the delayed (end of run) notifications triggered by
    # resources during the converge phase of the chef run.
    #
    # @return [Hash[String, Array[Chef::Resource::Notification]]] A hash from
    #   <notifying resource name> => <list of notifications it sent>
    #
    attr_reader :delayed_notification_collection

    # An Array containing the delayed (end of run) notifications triggered by
    # resources during the converge phase of the chef run.
    #
    # @return [Array[Chef::Resource::Notification]] An array of notification objects
    #
    attr_reader :delayed_actions

    # A Set keyed by the string name, of all the resources that are updated.  We do not
    # track actions or individual resource objects, since this matches the behavior of
    # the notification collections which are keyed by Strings.
    #
    attr_reader :updated_resources

    # @return [Boolean] If the resource_collection is in unified_mode (no separate converge phase)
    #
    def_delegator :resource_collection, :unified_mode

    # A child of the root Chef::Log logging object.
    #
    # @return Mixlib::Log::Child A child logger
    #
    attr_reader :logger

    # Creates a new Chef::RunContext object and populates its fields. This object gets
    # used by the Chef Server to generate a fully compiled recipe list for a node.
    #
    # @param node [Chef::Node] The node to run against.
    # @param cookbook_collection [Chef::CookbookCollection] The cookbooks
    #   involved in this run.
    # @param events [EventDispatch::Dispatcher] The event dispatcher for this
    #   run.
    #
    def initialize(node = nil, cookbook_collection = nil, events = nil, logger = nil)
      @events = events
      @logger = logger || Chef::Log.with_child
      self.node = node if node
      self.cookbook_collection = cookbook_collection if cookbook_collection
      @definitions = {}
      @loaded_recipes_hash = {}
      @loaded_attributes_hash = {}
      @reboot_info = {}
      @cookbook_compiler = nil
      @input_collection = Chef::Compliance::InputCollection.new(events)
      @waiver_collection = Chef::Compliance::WaiverCollection.new(events)
      @profile_collection = Chef::Compliance::ProfileCollection.new(events)
      @default_secret_service = nil
      @default_secret_config = {}

      initialize_child_state
    end

    def node=(node)
      @node = node
      node.run_context = self
    end

    def cookbook_collection=(cookbook_collection)
      @cookbook_collection = cookbook_collection
      node.set_cookbook_attribute
    end

    #
    # Triggers the compile phase of the chef run.
    #
    # @param run_list_expansion [Chef::RunList::RunListExpansion] The run list.
    # @see Chef::RunContext::CookbookCompiler
    #
    def load(run_list_expansion)
      @cookbook_compiler = CookbookCompiler.new(self, run_list_expansion, events)
      cookbook_compiler.compile
    end

    #
    # Initialize state that applies to both Chef::RunContext and Chef::ChildRunContext
    #
    def initialize_child_state
      @resource_collection = Chef::ResourceCollection.new(self)
      @before_notification_collection = Hash.new { |h, k| h[k] = [] }
      @immediate_notification_collection = Hash.new { |h, k| h[k] = [] }
      @delayed_notification_collection = Hash.new { |h, k| h[k] = [] }
      @delayed_actions = []
      @updated_resources = Set.new
    end

    #
    # Adds an before notification to the +before_notification_collection+.
    #
    # @param [Chef::Resource::Notification] notification The notification to add.
    #
    def notifies_before(notification)
      # Note for the future, notification.notifying_resource may be an instance
      # of Chef::Resource::UnresolvedSubscribes when calling {Resource#subscribes}
      # with a string value.
      if unified_mode && updated_resources.include?(notification.notifying_resource.declared_key)
        raise Chef::Exceptions::UnifiedModeBeforeSubscriptionEarlierResource.new(notification)
      end

      before_notification_collection[notification.notifying_resource.declared_key] << notification
    end

    #
    # Adds an immediate notification to the +immediate_notification_collection+.
    #
    # @param [Chef::Resource::Notification] notification The notification to add.
    #
    def notifies_immediately(notification)
      # Note for the future, notification.notifying_resource may be an instance
      # of Chef::Resource::UnresolvedSubscribes when calling {Resource#subscribes}
      # with a string value.
      immediate_notification_collection[notification.notifying_resource.declared_key] << notification
    end

    #
    # Adds a delayed notification to the +delayed_notification_collection+.
    #
    # @param [Chef::Resource::Notification] notification The notification to add.
    #
    def notifies_delayed(notification)
      # Note for the future, notification.notifying_resource may be an instance
      # of Chef::Resource::UnresolvedSubscribes when calling {Resource#subscribes}
      # with a string value.
      if unified_mode && updated_resources.include?(notification.notifying_resource.declared_key)
        add_delayed_action(notification)
      end
      delayed_notification_collection[notification.notifying_resource.declared_key] << notification
    end

    # Adds a delayed action to the delayed_actions collection
    #
    def add_delayed_action(notification)
      if delayed_actions.any? { |existing_notification| existing_notification.duplicates?(notification) }
        logger.info( "#{notification.notifying_resource} not queuing delayed action #{notification.action} on #{notification.resource}" \
                       " (delayed), as it's already been queued")
      else
        delayed_actions << notification
      end
    end

    # Get the list of before notifications sent by the given resource.
    #
    # @return [Array[Notification]]
    #
    def before_notifications(resource)
      key = resource.is_a?(String) ? resource : resource.declared_key
      before_notification_collection[key]
    end

    # Get the list of immediate notifications sent by the given resource.
    #
    # @return [Array[Notification]]
    #
    def immediate_notifications(resource)
      key = resource.is_a?(String) ? resource : resource.declared_key
      immediate_notification_collection[key]
    end

    # Get the list of immediate notifications pending to the given resource
    #
    # @return [Array[Notification]]
    #
    def reverse_immediate_notifications(resource)
      immediate_notification_collection.map do |k, v|
        v.select do |n|
          (n.resource.is_a?(String) && n.resource == resource.declared_key) ||
            n.resource == resource
        end
      end.flatten
    end

    # Get the list of delayed (end of run) notifications sent by the given
    # resource.
    #
    # @return [Array[Notification]]
    #
    def delayed_notifications(resource)
      key = resource.is_a?(String) ? resource : resource.declared_key
      delayed_notification_collection[key]
    end

    #
    # Cookbook and recipe loading
    #

    #
    # Evaluates the recipes +recipe_names+. Used by DSL::IncludeRecipe
    #
    # @param recipe_names [Array[String]] The list of recipe names (e.g.
    #   'my_cookbook' or 'my_cookbook::my_resource').
    # @param current_cookbook The cookbook we are currently running in.
    #
    # @see DSL::IncludeRecipe#include_recipe
    #
    def include_recipe(*recipe_names, current_cookbook: nil)
      result_recipes = []
      recipe_names.flatten.each do |recipe_name|
        if result = load_recipe(recipe_name, current_cookbook: current_cookbook)
          result_recipes << result
        end
      end
      result_recipes
    end

    #
    # Evaluates the recipe +recipe_name+. Used by DSL::IncludeRecipe
    #
    # TODO I am sort of confused why we have both this and include_recipe ...
    #      I don't see anything different beyond accepting and returning an
    #      array of recipes.
    #
    # @param recipe_name [Array[String]] The recipe name (e.g 'my_cookbook' or
    #   'my_cookbook::my_resource').
    # @param current_cookbook [String] The cookbook we are currently running in.
    #
    # @return A truthy value if the load occurred; `false` if already loaded.
    #
    # @see DSL::IncludeRecipe#load_recipe
    #
    def load_recipe(recipe_name, current_cookbook: nil)
      logger.trace("Loading recipe #{recipe_name} via include_recipe")

      cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name, current_cookbook: current_cookbook)

      if unreachable_cookbook?(cookbook_name) # CHEF-4367
        logger.warn(<<~ERROR_MESSAGE)
          MissingCookbookDependency:
          Recipe `#{recipe_name}` is not in the run_list, and cookbook '#{cookbook_name}'
          is not a dependency of any cookbook in the run_list. To load this recipe,
          first add a dependency of the cookbook '#{cookbook_name}' into the metadata
		  of the cookbook which depends on '#{cookbook_name}'.
        ERROR_MESSAGE
      end

      if loaded_fully_qualified_recipe?(cookbook_name, recipe_short_name)
        logger.trace("I am not loading #{recipe_name}, because I have already seen it.")
        false
      else
        loaded_recipe(cookbook_name, recipe_short_name)
        node.loaded_recipe(cookbook_name, recipe_short_name)
        cookbook = cookbook_collection[cookbook_name]
        cookbook.load_recipe(recipe_short_name, self)
      end
    end

    #
    # Load the given recipe from a filename.
    #
    # @param recipe_file [String] The recipe filename.
    #
    # @return [Chef::Recipe] The loaded recipe.
    #
    # @raise [Chef::Exceptions::RecipeNotFound] If the file does not exist.
    #
    def load_recipe_file(recipe_file)
      unless File.exist?(recipe_file)
        raise Chef::Exceptions::RecipeNotFound, "could not find recipe file #{recipe_file}"
      end

      logger.trace("Loading recipe file #{recipe_file}")
      recipe = Chef::Recipe.new("@recipe_files", recipe_file, self)
      recipe.from_file(recipe_file)
      recipe
    end

    #
    # Look up an attribute filename.
    #
    # @param cookbook_name [String] The cookbook name of the attribute file.
    # @param attr_file_name [String] The attribute file's name (not path).
    #
    # @return [String] The filename.
    #
    # @see DSL::IncludeAttribute#include_attribute
    #
    # @raise [Chef::Exceptions::CookbookNotFound] If the cookbook could not be found.
    # @raise [Chef::Exceptions::AttributeNotFound] If the attribute file could not be found.
    #
    def resolve_attribute(cookbook_name, attr_file_name)
      cookbook = cookbook_collection[cookbook_name]
      raise Chef::Exceptions::CookbookNotFound, "could not find cookbook #{cookbook_name} while loading attribute #{name}" unless cookbook

      attribute_filename = cookbook.attribute_filenames_by_short_filename[attr_file_name]
      raise Chef::Exceptions::AttributeNotFound, "could not find filename for attribute #{attr_file_name} in cookbook #{cookbook_name}" unless attribute_filename

      attribute_filename
    end

    #
    # A list of all recipes that have been loaded.
    #
    # This is stored internally as a Hash, so ordering is predictable.
    #
    # TODO is the above statement true in a 1.9+ ruby world?  Is it relevant?
    #
    # @return [Array[String]] A list of recipes in fully qualified form, e.g.
    #   the recipe "nginx" will be given as "nginx::default".
    #
    # @see #loaded_recipe? To determine if a particular recipe has been loaded.
    #
    def loaded_recipes
      loaded_recipes_hash.keys
    end

    #
    # A list of all attributes files that have been loaded.
    #
    # Stored internally using a Hash, so order is predictable.
    #
    # TODO is the above statement true in a 1.9+ ruby world?  Is it relevant?
    #
    # @return [Array[String]] A list of attribute file names in fully qualified
    #   form, e.g. the "nginx" will be given as "nginx::default".
    #
    def loaded_attributes
      loaded_attributes_hash.keys
    end

    #
    # Find out if a given recipe has been loaded.
    #
    # @param cookbook [String] Cookbook name.
    # @param recipe [String] Recipe name.
    #
    # @return [Boolean] `true` if the recipe has been loaded, `false` otherwise.
    #
    def loaded_fully_qualified_recipe?(cookbook, recipe)
      loaded_recipes_hash.key?("#{cookbook}::#{recipe}")
    end

    #
    # Find out if a given recipe has been loaded.
    #
    # @param recipe [String] Recipe name.  "nginx" and "nginx::default" yield
    #   the same results.
    #
    # @return [Boolean] `true` if the recipe has been loaded, `false` otherwise.
    #
    def loaded_recipe?(recipe)
      cookbook, recipe_name = Chef::Recipe.parse_recipe_name(recipe)
      loaded_fully_qualified_recipe?(cookbook, recipe_name)
    end

    #
    # Mark a given recipe as having been loaded.
    #
    # @param cookbook [String] Cookbook name.
    # @param recipe [String] Recipe name.
    #
    def loaded_recipe(cookbook, recipe)
      loaded_recipes_hash["#{cookbook}::#{recipe}"] = true
    end

    #
    # Find out if a given attribute file has been loaded.
    #
    # @param cookbook [String] Cookbook name.
    # @param attribute_file [String] Attribute file name.
    #
    # @return [Boolean] `true` if the recipe has been loaded, `false` otherwise.
    #
    def loaded_fully_qualified_attribute?(cookbook, attribute_file)
      loaded_attributes_hash.key?("#{cookbook}::#{attribute_file}")
    end

    #
    # Mark a given attribute file as having been loaded.
    #
    # @param cookbook [String] Cookbook name.
    # @param attribute_file [String] Attribute file name.
    #
    def loaded_attribute(cookbook, attribute_file)
      loaded_attributes_hash["#{cookbook}::#{attribute_file}"] = true
    end

    ##
    # Cookbook File Introspection

    #
    # Find out if the cookbook has the given template.
    #
    # @param cookbook [String] Cookbook name.
    # @param template_name [String] Template name.
    #
    # @return [Boolean] `true` if the template is in the cookbook, `false`
    #   otherwise.
    # @see Chef::CookbookVersion#has_template_for_node?
    #
    def has_template_in_cookbook?(cookbook, template_name)
      cookbook = cookbook_collection[cookbook]
      cookbook.has_template_for_node?(node, template_name)
    end

    #
    # Find out if the cookbook has the given file.
    #
    # @param cookbook [String] Cookbook name.
    # @param cb_file_name [String] File name.
    #
    # @return [Boolean] `true` if the file is in the cookbook, `false`
    #   otherwise.
    # @see Chef::CookbookVersion#has_cookbook_file_for_node?
    #
    def has_cookbook_file_in_cookbook?(cookbook, cb_file_name)
      cookbook = cookbook_collection[cookbook]
      cookbook.has_cookbook_file_for_node?(node, cb_file_name)
    end

    #
    # Find out whether the given cookbook is in the cookbook dependency graph.
    #
    # @param cookbook_name [String] Cookbook name.
    #
    # @return [Boolean] `true` if the cookbook is reachable, `false` otherwise.
    #
    # @see Chef::CookbookCompiler#unreachable_cookbook?
    def unreachable_cookbook?(cookbook_name)
      cookbook_compiler.unreachable_cookbook?(cookbook_name)
    end

    #
    # Open a stream object that can be printed into and will dispatch to events
    #
    # @param name [String] The name of the stream.
    # @param options [Hash] Other options for the stream.
    #
    # @return [EventDispatch::EventsOutputStream] The created stream.
    #
    # @yield If a block is passed, it will be run and the stream will be closed
    #   afterwards.
    # @yieldparam stream [EventDispatch::EventsOutputStream] The created stream.
    #
    def open_stream(name: nil, **options)
      stream = EventDispatch::EventsOutputStream.new(events, name: name, **options)
      if block_given?
        begin
          yield stream
        ensure
          stream.close
        end
      else
        stream
      end
    end

    # there are options for how to handle multiple calls to these functions:
    # 1. first call always wins (never change reboot_info once set).
    # 2. last call always wins (happily change reboot_info whenever).
    # 3. raise an exception on the first conflict.
    # 4. disable reboot after this run if anyone ever calls :cancel.
    # 5. raise an exception on any second call.
    # 6. ?
    def request_reboot(reboot_info)
      logger.info "Changing reboot status from #{self.reboot_info.inspect} to #{reboot_info.inspect}"
      @reboot_info = reboot_info
    end

    #
    # Cancels a pending reboot
    #
    def cancel_reboot
      logger.info "Changing reboot status from #{reboot_info.inspect} to {}"
      @reboot_info = {}
    end

    #
    # Checks to see if a reboot has been requested
    # @return [Boolean]
    #
    def reboot_requested?
      reboot_info.size > 0
    end

    # Remote transport from Train
    #
    # @return [Train::Plugins::Transport] The child class for our train transport.
    #
    def transport
      @transport ||= Chef::TrainTransport.new(logger).build_transport
    end

    # Remote connection object from Train
    #
    # @return [Train::Plugins::Transport::BaseConnection]
    #
    def transport_connection
      @transport_connection ||= transport&.connection
    end

    #
    # Create a child RunContext.
    #
    def create_child
      ChildRunContext.new(self)
    end

    # @api private
    attr_writer :resource_collection

    protected

    attr_reader :cookbook_compiler
    attr_reader :loaded_attributes_hash
    attr_reader :loaded_recipes_hash

    #
    # A child run context.  Delegates all root context calls to its parent.
    #
    # @api private
    #
    class ChildRunContext < RunContext
      extend Forwardable
      def_delegators :parent_run_context, *%w{
        action_collection
        action_collection=
        cancel_reboot
        config
        cookbook_collection
        cookbook_collection=
        cookbook_compiler
        default_secret_config
        default_secret_config=
        default_secret_service
        default_secret_service=
        definitions
        events
        events=
        has_cookbook_file_in_cookbook?
        has_template_in_cookbook?
        input_collection
        input_collection=
        load
        loaded_attribute
        loaded_attributes
        loaded_attributes_hash
        loaded_fully_qualified_attribute?
        loaded_fully_qualified_recipe?
        loaded_recipe
        loaded_recipe?
        loaded_recipes
        loaded_recipes_hash
        logger
        node
        node=
        open_stream
        profile_collection
        profile_collection=
        reboot_info
        reboot_info=
        reboot_requested?
        request_reboot
        resolve_attribute
        rest
        rest=
        rest_clean
        rest_clean=
        transport
        transport_connection
        unreachable_cookbook?
        waiver_collection
        waiver_collection=
      }

      def initialize(parent_run_context)
        @parent_run_context = parent_run_context

        # We don't call super, because we don't bother initializing stuff we're
        # going to delegate to the parent anyway.  Just initialize things that
        # every instance needs.
        initialize_child_state
      end

      CHILD_STATE = %w{
        add_delayed_action
        before_notification_collection
        before_notifications
        create_child
        delayed_actions
        delayed_notification_collection
        delayed_notification_collection=
        delayed_notifications
        immediate_notification_collection
        immediate_notification_collection=
        immediate_notifications
        include_recipe
        initialize_child_state
        load_recipe
        load_recipe_file
        notifies_before
        notifies_delayed
        notifies_immediately
        parent_run_context
        resource_collection
        resource_collection=
        reverse_immediate_notifications
        root_run_context
        runner
        runner=
        unified_mode
        updated_resources
      }.map(&:to_sym)

      # Verify that we didn't miss any methods
      unless @__skip_method_checking # hook specifically for compat_resource
        missing_methods = superclass.instance_methods(false) - instance_methods(false) - CHILD_STATE
        unless missing_methods.empty?
          raise "ERROR: not all methods of RunContext accounted for in ChildRunContext! All methods must be marked as child methods with CHILD_STATE or delegated to the parent_run_context. Missing #{missing_methods.join(", ")}."
        end
      end
    end
  end
end
