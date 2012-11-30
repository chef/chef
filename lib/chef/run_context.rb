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

    # A Hash containing the immediate notifications triggered by resources
    # during the converge phase of the chef run.
    attr_accessor :immediate_notification_collection

    # A Hash containing the delayed (end of run) notifications triggered by
    # resources during the converge phase of the chef run.
    attr_accessor :delayed_notification_collection

    # Event dispatcher for this run.
    attr_reader :events

    # Creates a new Chef::RunContext object and populates its fields. This object gets
    # used by the Chef Server to generate a fully compiled recipe list for a node.
    #
    # === Returns
    # object<Chef::RunContext>:: Duh. :)
    def initialize(node, cookbook_collection, events)
      @node = node
      @cookbook_collection = cookbook_collection
      @resource_collection = Chef::ResourceCollection.new
      @immediate_notification_collection = Hash.new {|h,k| h[k] = []}
      @delayed_notification_collection = Hash.new {|h,k| h[k] = []}
      @definitions = Hash.new
      @loaded_recipes = {}
      @loaded_attributes = {}
      @events = events

      @node.run_context = self
    end

    # Triggers the compile phase of the chef run. Implemented by
    # Chef::RunContext::CookbookCompiler
    def load(run_list_expansion)
      compiler = CookbookCompiler.new(self, run_list_expansion, events)
      compiler.compile
    end

    # Adds an immediate notification to the
    # +immediate_notification_collection+. The notification should be a
    # Chef::Resource::Notification or duck type.
    def notifies_immediately(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        @immediate_notification_collection[nr.name] << notification
      else
        @immediate_notification_collection[nr.to_s] << notification
      end
    end

    # Adds a delayed notification to the +delayed_notification_collection+. The
    # notification should be a Chef::Resource::Notification or duck type.
    def notifies_delayed(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        @delayed_notification_collection[nr.name] << notification
      else
        @delayed_notification_collection[nr.to_s] << notification
      end
    end

    def immediate_notifications(resource)
      if resource.instance_of?(Chef::Resource)
        return @immediate_notification_collection[resource.name]
      else
        return @immediate_notification_collection[resource.to_s]
      end
    end

    def delayed_notifications(resource)
      if resource.instance_of?(Chef::Resource)
        return @delayed_notification_collection[resource.name]
      else
        return @delayed_notification_collection[resource.to_s]
      end
    end

    # Evaluates the recipes +recipe_names+. Used by DSL::IncludeRecipe
    def include_recipe(*recipe_names)
      result_recipes = Array.new
      recipe_names.flatten.each do |recipe_name|
        if result = load_recipe(recipe_name)
          result_recipes << result
        end
      end
      result_recipes
    end

    # Evaluates the recipe +recipe_name+. Used by DSL::IncludeRecipe
    def load_recipe(recipe_name)
      Chef::Log.debug("Loading Recipe #{recipe_name} via include_recipe")

      cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name)
      if loaded_fully_qualified_recipe?(cookbook_name, recipe_short_name)
        Chef::Log.debug("I am not loading #{recipe_name}, because I have already seen it.")
        false
      else
        loaded_recipe(cookbook_name, recipe_short_name)

        cookbook = cookbook_collection[cookbook_name]
        cookbook.load_recipe(recipe_short_name, self)
      end
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
    # as a Hash, so ordering is not preserved when using ruby 1.8.
    #
    # Recipe names are given in fully qualified form, e.g., the recipe "nginx"
    # will be given as "nginx::default"
    #
    # To determine if a particular recipe has been loaded, use #loaded_recipe?
    def loaded_recipes
      @loaded_recipes.keys
    end

    # An Array of all attributes files that have been loaded. Stored internally
    # using a Hash, so order is not preserved on ruby 1.8.
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

    private

    def loaded_recipe(cookbook, recipe)
      @loaded_recipes["#{cookbook}::#{recipe}"] = true
    end

  end
end
