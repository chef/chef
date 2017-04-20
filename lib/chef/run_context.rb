#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/resource_collection"
require "chef/cookbook_version"
require "chef/node"
require "chef/role"
require "chef/log"
require "chef/recipe"
require "chef/run_context/cookbook_compiler"
require "chef/event_dispatch/events_output_stream"
require "forwardable"

class Chef

  # == Chef::RunContext
  # Value object that loads and tracks the context of a Chef run
  class RunContext
    #
    # Global state
    #

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

    #
    # Event dispatcher for this run.
    #
    # @return [Chef::EventDispatch::Dispatcher]
    #
    attr_reader :events

    #
    # Hash of factoids for a reboot request.
    #
    # @return [Hash]
    #
    attr_accessor :reboot_info

    #
    # Scoped state
    #

    #
    # The parent run context.
    #
    # @return [Chef::RunContext] The parent run context, or `nil` if this is the
    #   root context.
    #
    attr_reader :parent_run_context

    #
    # The root run context.
    #
    # @return [Chef::RunContext] The root run context.
    #
    def root_run_context
      rc = self
      rc = rc.parent_run_context until rc.parent_run_context.nil?
      rc
    end

    #
    # The collection of resources intended to be converged (and able to be
    # notified).
    #
    # @return [Chef::ResourceCollection]
    #
    # @see CookbookCompiler
    #
    attr_reader :resource_collection

    #
    # The list of control groups to execute during the audit phase
    #
    attr_reader :audits

    #
    # Pointer back to the Chef::Runner that created this
    #
    attr_accessor :runner

    #
    # Notification handling
    #

    #
    # A Hash containing the before notifications triggered by resources
    # during the converge phase of the chef run.
    #
    # @return [Hash[String, Array[Chef::Resource::Notification]]] A hash from
    #   <notifying resource name> => <list of notifications it sent>
    #
    attr_reader :before_notification_collection

    #
    # A Hash containing the immediate notifications triggered by resources
    # during the converge phase of the chef run.
    #
    # @return [Hash[String, Array[Chef::Resource::Notification]]] A hash from
    #   <notifying resource name> => <list of notifications it sent>
    #
    attr_reader :immediate_notification_collection

    #
    # A Hash containing the delayed (end of run) notifications triggered by
    # resources during the converge phase of the chef run.
    #
    # @return [Hash[String, Array[Chef::Resource::Notification]]] A hash from
    #   <notifying resource name> => <list of notifications it sent>
    #
    attr_reader :delayed_notification_collection

    #
    # An Array containing the delayed (end of run) notifications triggered by
    # resources during the converge phase of the chef run.
    #
    # @return [Array[Chef::Resource::Notification]] An array of notification objects
    #
    attr_reader :delayed_actions

    # Creates a new Chef::RunContext object and populates its fields. This object gets
    # used by the Chef Server to generate a fully compiled recipe list for a node.
    #
    # @param node [Chef::Node] The node to run against.
    # @param cookbook_collection [Chef::CookbookCollection] The cookbooks
    #   involved in this run.
    # @param events [EventDispatch::Dispatcher] The event dispatcher for this
    #   run.
    #
    def initialize(node, cookbook_collection, events)
      @node = node
      @cookbook_collection = cookbook_collection
      @events = events

      node.run_context = self
      node.set_cookbook_attribute

      @definitions = Hash.new
      @loaded_recipes_hash = {}
      @loaded_attributes_hash = {}
      @reboot_info = {}
      @cookbook_compiler = nil
      @delayed_actions = []

      initialize_child_state
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
      @audits = {}
      @resource_collection = Chef::ResourceCollection.new(self)
      @before_notification_collection = Hash.new { |h, k| h[k] = [] }
      @immediate_notification_collection = Hash.new { |h, k| h[k] = [] }
      @delayed_notification_collection = Hash.new { |h, k| h[k] = [] }
      @delayed_actions = []
    end

    #
    # Adds an before notification to the +before_notification_collection+.
    #
    # @param [Chef::Resource::Notification] The notification to add.
    #
    def notifies_before(notification)
      # Note for the future, notification.notifying_resource may be an instance
      # of Chef::Resource::UnresolvedSubscribes when calling {Resource#subscribes}
      # with a string value.
      before_notification_collection[notification.notifying_resource.declared_key] << notification
    end

    #
    # Adds an immediate notification to the +immediate_notification_collection+.
    #
    # @param [Chef::Resource::Notification] The notification to add.
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
    # @param [Chef::Resource::Notification] The notification to add.
    #
    def notifies_delayed(notification)
      # Note for the future, notification.notifying_resource may be an instance
      # of Chef::Resource::UnresolvedSubscribes when calling {Resource#subscribes}
      # with a string value.
      delayed_notification_collection[notification.notifying_resource.declared_key] << notification
    end

    #
    # Adds a delayed action to the +delayed_actions+.
    #
    def add_delayed_action(notification)
      if delayed_actions.any? { |existing_notification| existing_notification.duplicates?(notification) }
        Chef::Log.info( "#{notification.notifying_resource} not queuing delayed action #{notification.action} on #{notification.resource}"\
                       " (delayed), as it's already been queued")
      else
        delayed_actions << notification
      end
    end

    #
    # Get the list of before notifications sent by the given resource.
    #
    # @return [Array[Notification]]
    #
    def before_notifications(resource)
      before_notification_collection[resource.declared_key]
    end

    #
    # Get the list of immediate notifications sent by the given resource.
    #
    # @return [Array[Notification]]
    #
    def immediate_notifications(resource)
      immediate_notification_collection[resource.declared_key]
    end

    #
    # Get the list of delayed (end of run) notifications sent by the given
    # resource.
    #
    # @return [Array[Notification]]
    #
    def delayed_notifications(resource)
      delayed_notification_collection[resource.declared_key]
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
      result_recipes = Array.new
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
    # @param recipe_names [Array[String]] The recipe name (e.g 'my_cookbook' or
    #   'my_cookbook::my_resource').
    # @param current_cookbook The cookbook we are currently running in.
    #
    # @return A truthy value if the load occurred; `false` if already loaded.
    #
    # @see DSL::IncludeRecipe#load_recipe
    #
    def load_recipe(recipe_name, current_cookbook: nil)
      Chef::Log.debug("Loading recipe #{recipe_name} via include_recipe")

      cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name, current_cookbook: current_cookbook)

      if unreachable_cookbook?(cookbook_name) # CHEF-4367
        Chef::Log.warn(<<-ERROR_MESSAGE)
MissingCookbookDependency:
Recipe `#{recipe_name}` is not in the run_list, and cookbook '#{cookbook_name}'
is not a dependency of any cookbook in the run_list.  To load this recipe,
first add a dependency on cookbook '#{cookbook_name}' in the cookbook you're
including it from in that cookbook's metadata.
ERROR_MESSAGE
      end

      if loaded_fully_qualified_recipe?(cookbook_name, recipe_short_name)
        Chef::Log.debug("I am not loading #{recipe_name}, because I have already seen it.")
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
      if !File.exist?(recipe_file)
        raise Chef::Exceptions::RecipeNotFound, "could not find recipe file #{recipe_file}"
      end

      Chef::Log.debug("Loading recipe file #{recipe_file}")
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
      loaded_recipes_hash.has_key?("#{cookbook}::#{recipe}")
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
      loaded_attributes_hash.has_key?("#{cookbook}::#{attribute_file}")
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
      Chef::Log.info "Changing reboot status from #{self.reboot_info.inspect} to #{reboot_info.inspect}"
      @reboot_info = reboot_info
    end

    def cancel_reboot
      Chef::Log.info "Changing reboot status from #{reboot_info.inspect} to {}"
      @reboot_info = {}
    end

    def reboot_requested?
      reboot_info.size > 0
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
        cancel_reboot
        config
        cookbook_collection
        cookbook_compiler
        definitions
        events
        has_cookbook_file_in_cookbook?
        has_template_in_cookbook?
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
        node
        open_stream
        reboot_info
        reboot_info=
        reboot_requested?
        request_reboot
        resolve_attribute
        unreachable_cookbook?
      }

      def initialize(parent_run_context)
        @parent_run_context = parent_run_context

        # We don't call super, because we don't bother initializing stuff we're
        # going to delegate to the parent anyway.  Just initialize things that
        # every instance needs.
        initialize_child_state
      end

      CHILD_STATE = %w{
        audits
        audits=
        create_child
        add_delayed_action
        delayed_actions
        delayed_notification_collection
        delayed_notification_collection=
        delayed_notifications
        immediate_notification_collection
        immediate_notification_collection=
        immediate_notifications
        before_notification_collection
        before_notifications
        include_recipe
        initialize_child_state
        load_recipe
        load_recipe_file
        notifies_before
        notifies_immediately
        notifies_delayed
        parent_run_context
        root_run_context
        resource_collection
        resource_collection=
        runner
        runner=
      }.map { |x| x.to_sym }

      # Verify that we didn't miss any methods
      unless @__skip_method_checking # hook specifically for compat_resource
        missing_methods = superclass.instance_methods(false) - instance_methods(false) - CHILD_STATE
        if !missing_methods.empty?
          raise "ERROR: not all methods of RunContext accounted for in ChildRunContext! All methods must be marked as child methods with CHILD_STATE or delegated to the parent_run_context. Missing #{missing_methods.join(", ")}."
        end
      end
    end
  end
end
