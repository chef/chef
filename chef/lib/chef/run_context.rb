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
require 'chef/node'
require 'chef/role'
require 'chef/log'
require 'chef/dsl/attribute'

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

    end

    def load(run_list_expansion)
      load_libraries

      load_lwrps
      load_attributes
      load_resource_definitions

      # Precendence rules state that roles' attributes come after
      # cookbooks. Now we've loaded attributes from cookbooks with
      # load_attributes, apply the expansion attributes (loaded from
      # roles) to the node.
      @node.apply_expansion_attributes(run_list_expansion)

      @events.recipe_load_start(run_list_expansion.recipes.size)
      run_list_expansion.recipes.each do |recipe|
        begin
          include_recipe(recipe)
        rescue Chef::Exceptions::RecipeNotFound => e
          @events.recipe_not_found(e)
          raise
        rescue Exception => e
          path = resolve_recipe(recipe)
          @events.recipe_file_load_failed(path, e)
          raise
        end
      end
      @events.recipe_load_complete
    end

    def resolve_recipe(recipe_name)
      cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name)
      cookbook = cookbook_collection[cookbook_name]
      cookbook.recipe_filenames_by_name[recipe_short_name]
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

    def loaded_attribute?

    end

    def loaded_attribute(cookbook, attribute_file)
      @loaded_attributes["#{cookbook}::#{recipe}"] = true
    end

    private

    def loaded_recipe(cookbook, recipe)
      @loaded_recipes["#{cookbook}::#{recipe}"] = true
    end

    def load_libraries
      @events.library_load_start(count_files_by_segment(:libraries))

      foreach_cookbook_load_segment(:libraries) do |cookbook_name, filename|
        begin
          Chef::Log.debug("Loading cookbook #{cookbook_name}'s library file: #{filename}")
          Kernel.load(filename)
          @events.library_file_loaded(filename)
        rescue Exception => e
          # TODO wrap/munge exception to highlight syntax/name/no method errors.
          @events.library_file_load_failed(filename, e)
          raise
        end
      end

      @events.library_load_complete
    end

    def load_lwrps
      lwrp_file_count = count_files_by_segment(:providers) + count_files_by_segment(:resources)
      @events.lwrp_load_start(lwrp_file_count)
      load_lwrp_providers
      load_lwrp_resources
      @events.lwrp_load_complete
    end

    def load_lwrp_providers
      foreach_cookbook_load_segment(:providers) do |cookbook_name, filename|
        begin
          Chef::Log.debug("Loading cookbook #{cookbook_name}'s providers from #{filename}")
          Chef::Provider.build_from_file(cookbook_name, filename, self)
          @events.lwrp_file_loaded(filename)
        rescue Exception => e
          # TODO: wrap exception with helpful info
          @events.lwrp_file_load_failed(filename, e)
          raise
        end
      end
    end

    def load_lwrp_resources
      foreach_cookbook_load_segment(:resources) do |cookbook_name, filename|
        begin
          Chef::Log.debug("Loading cookbook #{cookbook_name}'s resources from #{filename}")
          Chef::Resource.build_from_file(cookbook_name, filename, self)
          @events.lwrp_file_loaded(filename)
        rescue Exception => e
          @events.lwrp_file_load_failed(filename, e)
          raise
        end
      end
    end

    def load_attributes
      @events.attribute_load_start(count_files_by_segment(:attributes))
      foreach_cookbook_load_segment(:attributes) do |cookbook_name, filename|
        begin
          Chef::Log.debug("Node #{@node.name} loading cookbook #{cookbook_name}'s attribute file #{filename}")
          attr_file_basename = ::File.basename(filename, ".rb")
          attribute_dsl = Chef::DSL::Attribute.new(node, self)
          attribute_dsl.eval_attribute(cookbook_name, attr_file_basename)
        rescue Exception => e
          @events.attribute_file_load_failed(filename, e)
          raise
        end
      end
      @events.attribute_load_complete
    end

    def load_resource_definitions
      @events.definition_load_start(count_files_by_segment(:definitions))
      foreach_cookbook_load_segment(:definitions) do |cookbook_name, filename|
        begin
          Chef::Log.debug("Loading cookbook #{cookbook_name}'s definitions from #{filename}")
          resourcelist = Chef::ResourceDefinitionList.new
          resourcelist.from_file(filename)
          definitions.merge!(resourcelist.defines) do |key, oldval, newval|
            Chef::Log.info("Overriding duplicate definition #{key}, new definition found in #{filename}")
            newval
          end
          @events.definition_file_loaded(filename)
        rescue Exception => e
          @events.definition_file_load_failed(filename, e)
        end
      end
      @events.definition_load_complete
    end

    def count_files_by_segment(segment)
      cookbook_collection.inject(0) do |count, ( cookbook_name, cookbook )|
        count + cookbook.segment_filenames(segment).size
      end
    end

    def foreach_cookbook_load_segment(segment, &block)
      cookbook_collection.each do |cookbook_name, cookbook|
        segment_filenames = cookbook.segment_filenames(segment)
        segment_filenames.each do |segment_filename|
          block.call(cookbook_name, segment_filename)
        end
      end
    end

  end
end
