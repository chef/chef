#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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

require 'chef/resource_collection'
require 'chef/cookbook_version'
require 'chef/node'
require 'chef/role'
require 'chef/log'
require 'chef/recipe'
require 'chef/run_context/cookbook_compiler'
require 'chef/event_dispatch/events_output_stream'
require 'forwardable'

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
    # Notification handling
    #

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

      initialize_non_shared_state
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
    def initialize_non_shared_state
      @audits = {}
      @resource_collection = Chef::ResourceCollection.new
      @immediate_notification_collection = Hash.new {|h,k| h[k] = []}
      @delayed_notification_collection = Hash.new {|h,k| h[k] = []}
    end

    #
    # Adds an immediate notification to the +immediate_notification_collection+.
    #
    # @param [Chef::Resource::Notification] The notification to add.
    #
    def notifies_immediately(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        # TODO is there any point at all to keying on name?  Do we really want
        # to categorize notifications from execute[do it] with file[do it]
        # and directory[do it]?
        immediate_notification_collection[nr.name] << notification
      else
        # TODO this is only declared on Chef::Resource.  Does it even run?
        immediate_notification_collection[nr.declared_key] << notification
      end
    end

    #
    # Adds a delayed notification to the +delayed_notification_collection+.
    #
    # @param [Chef::Resource::Notification] The notification to add.
    #
    def notifies_delayed(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        # TODO this seems odd and possibly even wrong.
        delayed_notification_collection[nr.name] << notification
      else
        delayed_notification_collection[nr.declared_key] << notification
      end
    end

    #
    # Get the list of immediate notifications sent by the given resource.
    #
    # TODO seriously, this is actually wrong.  resource.name is not unique,
    # you need the type as well.
    #
    # @return [Array[Notification]]
    #
    def immediate_notifications(resource)
      if resource.instance_of?(Chef::Resource)
        return immediate_notification_collection[resource.name]
      else
        return immediate_notification_collection[resource.declared_key]
      end
    end

    #
    # Get the list of delayed (end of run) notifications sent by the given
    # resource.
    #
    # TODO seriously, this is actually wrong.  resource.name is not unique,
    # you need the type as well.
    #
    # @return [Array[Notification]]
    #
    def delayed_notifications(resource)
      if resource.instance_of?(Chef::Resource)
        return delayed_notification_collection[resource.name]
      else
        return delayed_notification_collection[resource.declared_key]
      end
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
      Chef::Log.debug("Loading Recipe #{recipe_name} via include_recipe")

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

      Chef::Log.debug("Loading Recipe File #{recipe_file}")
      recipe = Chef::Recipe.new('@recipe_files', recipe_file, self)
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
      Chef::Log::info "Changing reboot status from #{self.reboot_info.inspect} to #{reboot_info.inspect}"
      @reboot_info = reboot_info
    end

    def cancel_reboot
      Chef::Log::info "Changing reboot status from #{reboot_info.inspect} to {}"
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

    private

    attr_reader :cookbook_compiler
    attr_reader :loaded_attributes_hash
    attr_reader :loaded_recipes_hash

    module Deprecated
      ###
      # These need to be settable so deploy can run a resource_collection
      # independent of any cookbooks via +recipe_eval+

      def audits=(value)
        Chef::Log.deprecation("Setting run_context.audits will be removed in a future Chef.  Use run_context.create_child to create a new RunContext instead.")
      end

      def immediate_notification_collection=(value)
        Chef::Log.deprecation("Setting run_context.immediate_notification_collection will be removed in a future Chef.  Use run_context.create_child to create a new RunContext instead.")
      end

      def delayed_notification_collection=(value)
        Chef::Log.deprecation("Setting run_context.delayed_notification_collection will be removed in a future Chef.  Use run_context.create_child to create a new RunContext instead.")
      end
    end
    prepend Deprecated


    #
    # A child run context.  Delegates all root context calls to its parent.
    #
    # @api private
    #
    class ChildRunContext < RunContext
      extend Forwardable
      def_delegators :parent_run_context, :node, :cookbook_collection, :definitions, :events, :reboot_info, :reboot_info=, :cookbook_compiler

      def initialize(parent_run_context)
        # We don't call super, because we don't bother initializing stuff we're
        # going to delegate to the parent anyway.  Just initialize things that
        # every instance needs.
        initialize_non_shared_state
        @parent_run_context = parent_run_context
      end
    end
  end
end
