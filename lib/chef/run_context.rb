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

class Chef

  # == Chef::RunContext
  # Value object that loads and tracks the context of a Chef run
  class RunContext

    # Chef::Node object for this run
    attr_reader :node

    # Chef::CookbookCollection for this run
    attr_reader :cookbook_collection

    # Resource Definitions for this run. Populated when the files in
    # +definitions/+ are evaluated (this is triggered by #load).
    attr_reader :definitions

    ###
    # These need to be settable so deploy can run a resource_collection
    # independent of any cookbooks via +recipe_eval+

    # The Chef::ResourceCollection for this run. Populated by evaluating
    # recipes, which is triggered by #load. (See also: CookbookCompiler)
    attr_accessor :resource_collection

    # The list of control groups to execute during the audit phase
    attr_accessor :audits

    # A Hash containing the immediate notifications triggered by resources
    # during the converge phase of the chef run.
    attr_accessor :immediate_notification_collection

    # A Hash containing the delayed (end of run) notifications triggered by
    # resources during the converge phase of the chef run.
    attr_accessor :delayed_notification_collection

    # Event dispatcher for this run.
    attr_reader :events

    # Hash of factoids for a reboot request.
    attr_reader :reboot_info

    # Creates a new Chef::RunContext object and populates its fields. This object gets
    # used by the Chef Server to generate a fully compiled recipe list for a node.
    #
    # === Returns
    # object<Chef::RunContext>:: Duh. :)
    def initialize(node, cookbook_collection, events)
      @node = node
      @cookbook_collection = cookbook_collection
      @resource_collection = Chef::ResourceCollection.new
      @audits = {}
      @immediate_notification_collection = Hash.new {|h,k| h[k] = []}
      @delayed_notification_collection = Hash.new {|h,k| h[k] = []}
      @definitions = Hash.new
      @loaded_recipes = {}
      @loaded_attributes = {}
      @events = events
      @reboot_info = {}

      @node.run_context = self
      @node.consume_cookbook_collection
      @cookbook_compiler = nil
    end

    # Triggers the compile phase of the chef run. Implemented by
    # Chef::RunContext::CookbookCompiler
    def load(run_list_expansion)
      @cookbook_compiler = CookbookCompiler.new(self, run_list_expansion, events)
      @cookbook_compiler.compile
    end

    # Adds an immediate notification to the
    # +immediate_notification_collection+. The notification should be a
    # Chef::Resource::Notification or duck type.
    def notifies_immediately(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        @immediate_notification_collection[nr.name] << notification
      else
        @immediate_notification_collection[nr.declared_key] << notification
      end
    end

    # Adds a delayed notification to the +delayed_notification_collection+. The
    # notification should be a Chef::Resource::Notification or duck type.
    def notifies_delayed(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        @delayed_notification_collection[nr.name] << notification
      else
        @delayed_notification_collection[nr.declared_key] << notification
      end
    end

    def immediate_notifications(resource)
      if resource.instance_of?(Chef::Resource)
        return @immediate_notification_collection[resource.name]
      else
        return @immediate_notification_collection[resource.declared_key]
      end
    end

    def delayed_notifications(resource)
      if resource.instance_of?(Chef::Resource)
        return @delayed_notification_collection[resource.name]
      else
        return @delayed_notification_collection[resource.declared_key]
      end
    end

    # Evaluates the recipes +recipe_names+. Used by DSL::IncludeRecipe
    def include_recipe(*recipe_names, current_cookbook: nil)
      result_recipes = Array.new
      recipe_names.flatten.each do |recipe_name|
        if result = load_recipe(recipe_name, current_cookbook: current_cookbook)
          result_recipes << result
        end
      end
      result_recipes
    end

    # Evaluates the recipe +recipe_name+. Used by DSL::IncludeRecipe
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

    def load_recipe_file(recipe_file)
      if !File.exist?(recipe_file)
        raise Chef::Exceptions::RecipeNotFound, "could not find recipe file #{recipe_file}"
      end

      Chef::Log.debug("Loading Recipe File #{recipe_file}")
      recipe = Chef::Recipe.new('@recipe_files', recipe_file, self)
      recipe.from_file(recipe_file)
      recipe
    end

    # Looks up an attribute file given the +cookbook_name+ and
    # +attr_file_name+. Used by DSL::IncludeAttribute
    def resolve_attribute(cookbook_name, attr_file_name)
      cookbook = cookbook_collection[cookbook_name]
      raise Chef::Exceptions::CookbookNotFound, "could not find cookbook #{cookbook_name} while loading attribute #{name}" unless cookbook

      attribute_filename = cookbook.attribute_filenames_by_short_filename[attr_file_name]
      raise Chef::Exceptions::AttributeNotFound, "could not find filename for attribute #{attr_file_name} in cookbook #{cookbook_name}" unless attribute_filename

      attribute_filename
    end

    # An Array of all recipes that have been loaded. This is stored internally
    # as a Hash, so ordering is predictable.
    #
    # Recipe names are given in fully qualified form, e.g., the recipe "nginx"
    # will be given as "nginx::default"
    #
    # To determine if a particular recipe has been loaded, use #loaded_recipe?
    def loaded_recipes
      @loaded_recipes.keys
    end

    # An Array of all attributes files that have been loaded. Stored internally
    # using a Hash, so order is predictable.
    #
    # Attribute file names are given in fully qualified form, e.g.,
    # "nginx::default" instead of "nginx".
    def loaded_attributes
      @loaded_attributes.keys
    end

    def loaded_fully_qualified_recipe?(cookbook, recipe)
      @loaded_recipes.has_key?("#{cookbook}::#{recipe}")
    end

    # Returns true if +recipe+ has been loaded, false otherwise. Default recipe
    # names are expanded, so `loaded_recipe?("nginx")` and
    # `loaded_recipe?("nginx::default")` are valid and give identical results.
    def loaded_recipe?(recipe)
      cookbook, recipe_name = Chef::Recipe.parse_recipe_name(recipe)
      loaded_fully_qualified_recipe?(cookbook, recipe_name)
    end

    def loaded_fully_qualified_attribute?(cookbook, attribute_file)
      @loaded_attributes.has_key?("#{cookbook}::#{attribute_file}")
    end

    def loaded_attribute(cookbook, attribute_file)
      @loaded_attributes["#{cookbook}::#{attribute_file}"] = true
    end

    ##
    # Cookbook File Introspection

    def has_template_in_cookbook?(cookbook, template_name)
      cookbook = cookbook_collection[cookbook]
      cookbook.has_template_for_node?(node, template_name)
    end

    def has_cookbook_file_in_cookbook?(cookbook, cb_file_name)
      cookbook = cookbook_collection[cookbook]
      cookbook.has_cookbook_file_for_node?(node, cb_file_name)
    end

    # Delegates to CookbookCompiler#unreachable_cookbook?
    # Used to raise an error when attempting to load a recipe belonging to a
    # cookbook that is not in the dependency graph. See also: CHEF-4367
    def unreachable_cookbook?(cookbook_name)
      @cookbook_compiler.unreachable_cookbook?(cookbook_name)
    end

    # Open a stream object that can be printed into and will dispatch to events
    #
    # == Arguments
    # options is a hash with these possible options:
    # - name: a string that identifies the stream to the user. Preferably short.
    #
    # Pass a block and the stream will be yielded to it, and close on its own
    # at the end of the block.
    def open_stream(options = {})
      stream = EventDispatch::EventsOutputStream.new(events, options)
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
    # 1. first call always wins (never change @reboot_info once set).
    # 2. last call always wins (happily change @reboot_info whenever).
    # 3. raise an exception on the first conflict.
    # 4. disable reboot after this run if anyone ever calls :cancel.
    # 5. raise an exception on any second call.
    # 6. ?
    def request_reboot(reboot_info)
      Chef::Log::info "Changing reboot status from #{@reboot_info.inspect} to #{reboot_info.inspect}"
      @reboot_info = reboot_info
    end

    def cancel_reboot
      Chef::Log::info "Changing reboot status from #{@reboot_info.inspect} to {}"
      @reboot_info = {}
    end

    def reboot_requested?
      @reboot_info.size > 0
    end

    private

    def loaded_recipe(cookbook, recipe)
      @loaded_recipes["#{cookbook}::#{recipe}"] = true
    end

  end
end
