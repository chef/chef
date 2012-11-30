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

    attr_reader :node, :cookbook_collection, :definitions

    # Needs to be settable so deploy can run a resource_collection independent
    # of any cookbooks.
    attr_accessor :resource_collection, :immediate_notification_collection, :delayed_notification_collection

    attr_reader :events

    attr_reader :loaded_recipes
    attr_reader :loaded_attributes

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

    def load(run_list_expansion)
      compiler = CookbookCompiler.new(self, run_list_expansion, events)
      compiler.compile
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

    def notifies_immediately(notification)
      nr = notification.notifying_resource
      if nr.instance_of?(Chef::Resource)
        @immediate_notification_collection[nr.name] << notification
      else
        @immediate_notification_collection[nr.to_s] << notification
      end
    end

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

    def include_recipe(*recipe_names)
      result_recipes = Array.new
      recipe_names.flatten.each do |recipe_name|
        if result = load_recipe(recipe_name)
          result_recipes << result
        end
      end
      result_recipes
    end

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

    def loaded_fully_qualified_recipe?(cookbook, recipe)
      @loaded_recipes.has_key?("#{cookbook}::#{recipe}")
    end

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
