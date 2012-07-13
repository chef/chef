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
require 'chef/mixin/language_include_recipe'

class Chef
  # == Chef::RunContext
  # Value object that loads and tracks the context of a Chef run
  class RunContext

    # Used to load the node's recipes after expanding its run list
    include Chef::Mixin::LanguageIncludeRecipe

    attr_reader :node, :cookbook_collection, :definitions

    # Needs to be settable so deploy can run a resource_collection independent
    # of any cookbooks.
    attr_accessor :resource_collection, :immediate_notification_collection, :delayed_notification_collection

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
      @events = events

      # TODO: 5/18/2010 cw/timh - See note on Chef::Node's
      # cookbook_collection attr_accessor
      node.cookbook_collection = cookbook_collection
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
          # TODO: timh/cw, 5-14-2010: It's distasteful to be including
          # the DSL in a class outside the context of the DSL
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

    private

    def load_libraries
      @events.library_load_start(count_files_by_segment(:libraries))

      foreach_cookbook_load_segment(:libraries) do |cookbook_name, filename|
        begin
          Chef::Log.debug("Loading cookbook #{cookbook_name}'s library file: #{filename}")
          Kernel.load(filename)
          @events.library_file_loaded(filename)
        rescue Exception => e
          # TODO wrap/munge exception to highlight syntax/name/no method errors.
          @events.library_load_failed(filename, e)
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
          @node.from_file(filename)
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
