#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "set"
require "chef/log"
require "chef/recipe"
require "chef/resource/lwrp_base"
require "chef/provider/lwrp_base"
require "chef/resource_definition_list"

class Chef
  class RunContext

    # Implements the compile phase of the chef run by loading/eval-ing files
    # from cookbooks in the correct order and in the correct context.
    class CookbookCompiler
      attr_reader :events
      attr_reader :run_list_expansion

      def initialize(run_context, run_list_expansion, events)
        @run_context = run_context
        @events = events
        @run_list_expansion = run_list_expansion
        @cookbook_order = nil
      end

      # Chef::Node object for the current run.
      def node
        @run_context.node
      end

      # Chef::CookbookCollection object for the current run
      def cookbook_collection
        @run_context.cookbook_collection
      end

      # Resource Definitions from the compiled cookbooks. This is populated by
      # calling #compile_resource_definitions (which is called by #compile)
      def definitions
        @run_context.definitions
      end

      # Run the compile phase of the chef run. Loads files in the following order:
      # * Libraries
      # * Ohai
      # * Attributes
      # * LWRPs
      # * Resource Definitions
      # * Recipes
      #
      # Recipes are loaded in precisely the order specified by the expanded run_list.
      #
      # Other files are loaded in an order derived from the expanded run_list
      # and the dependencies declared by cookbooks' metadata. See
      # #cookbook_order for more information.
      def compile
        compile_libraries
        compile_ohai_plugins
        compile_attributes
        compile_lwrps
        compile_resource_definitions
        compile_recipes
      end

      # Extracts the cookbook names from the expanded run list, then iterates
      # over the list, recursing through dependencies to give a run_list
      # ordered array of cookbook names with no duplicates. Dependencies appear
      # before the cookbook(s) that depend on them.
      def cookbook_order
        @cookbook_order ||= begin
          ordered_cookbooks = []
          seen_cookbooks = {}
          run_list_expansion.recipes.each do |recipe|
            cookbook = Chef::Recipe.parse_recipe_name(recipe).first
            add_cookbook_with_deps(ordered_cookbooks, seen_cookbooks, cookbook)
          end
          Chef::Log.debug("Cookbooks to compile: #{ordered_cookbooks.inspect}")
          ordered_cookbooks
        end
      end

      # Loads library files from cookbooks according to #cookbook_order.
      def compile_libraries
        @events.library_load_start(count_files_by_segment(:libraries))
        cookbook_order.each do |cookbook|
          load_libraries_from_cookbook(cookbook)
        end
        @events.library_load_complete
      end

      # Loads Ohai Plugins from cookbooks, and ensure any old ones are
      # properly cleaned out
      def compile_ohai_plugins
        ohai_plugin_count = count_files_by_segment(:ohai)
        @events.ohai_plugin_load_start(ohai_plugin_count)
        FileUtils.rm_rf(Chef::Config[:ohai_segment_plugin_path])

        cookbook_order.each do |cookbook|
          load_ohai_plugins_from_cookbook(cookbook)
        end

        # Doing a full ohai system check is costly, so only do so if we've loaded additional plugins
        if ohai_plugin_count > 0
          ohai = Ohai::System.new.run_additional_plugins(Chef::Config[:ohai_segment_plugin_path])
          node.consume_ohai_data(ohai)
        end

        @events.ohai_plugin_load_complete
      end

      # Loads attributes files from cookbooks. Attributes files are loaded
      # according to #cookbook_order; within a cookbook, +default.rb+ is loaded
      # first, then the remaining attributes files in lexical sort order.
      def compile_attributes
        @events.attribute_load_start(count_files_by_segment(:attributes, "attributes.rb"))
        cookbook_order.each do |cookbook|
          load_attributes_from_cookbook(cookbook)
        end
        @events.attribute_load_complete
      end

      # Loads LWRPs according to #cookbook_order. Providers are loaded before
      # resources on a cookbook-wise basis.
      def compile_lwrps
        lwrp_file_count = count_files_by_segment(:providers) + count_files_by_segment(:resources)
        @events.lwrp_load_start(lwrp_file_count)
        cookbook_order.each do |cookbook|
          load_lwrps_from_cookbook(cookbook)
        end
        @events.lwrp_load_complete
      end

      # Loads resource definitions according to #cookbook_order
      def compile_resource_definitions
        @events.definition_load_start(count_files_by_segment(:definitions))
        cookbook_order.each do |cookbook|
          load_resource_definitions_from_cookbook(cookbook)
        end
        @events.definition_load_complete
      end

      # Iterates over the expanded run_list, loading each recipe in turn.
      def compile_recipes
        @events.recipe_load_start(run_list_expansion.recipes.size)
        run_list_expansion.recipes.each do |recipe|
          begin
            path = resolve_recipe(recipe)
            @run_context.load_recipe(recipe)
            @events.recipe_file_loaded(path, recipe)
          rescue Chef::Exceptions::RecipeNotFound => e
            @events.recipe_not_found(e)
            raise
          rescue Exception => e
            @events.recipe_file_load_failed(path, e, recipe)
            raise
          end
        end
        @events.recipe_load_complete
      end

      # Whether or not a cookbook is reachable from the set of cookbook given
      # by the run_list plus those cookbooks' dependencies.
      def unreachable_cookbook?(cookbook_name)
        !reachable_cookbooks.include?(cookbook_name)
      end

      # All cookbooks in the dependency graph, returned as a Set.
      def reachable_cookbooks
        @reachable_cookbooks ||= Set.new(cookbook_order)
      end

      private

      def load_attributes_from_cookbook(cookbook_name)
        list_of_attr_files = files_in_cookbook_by_segment(cookbook_name, :attributes).dup
        root_alias = cookbook_collection[cookbook_name].files_for(:root_files).find { |record| record[:name] == "attributes.rb" }
        default_file = list_of_attr_files.find { |path| File.basename(path) == "default.rb" }
        if root_alias
          if default_file
            Chef::Log.error("Cookbook #{cookbook_name} contains both attributes.rb and and attributes/default.rb, ignoring attributes/default.rb")
            list_of_attr_files.delete(default_file)
          end
          # The actual root_alias path decoding is handled in CookbookVersion#attribute_filenames_by_short_filename
          load_attribute_file(cookbook_name.to_s, "default")
        elsif default_file
          list_of_attr_files.delete(default_file)
          load_attribute_file(cookbook_name.to_s, default_file)
        end

        list_of_attr_files.each do |filename|
          load_attribute_file(cookbook_name.to_s, filename)
        end
      end

      def load_attribute_file(cookbook_name, filename)
        Chef::Log.debug("Node #{node.name} loading cookbook #{cookbook_name}'s attribute file #{filename}")
        attr_file_basename = ::File.basename(filename, ".rb")
        node.include_attribute("#{cookbook_name}::#{attr_file_basename}")
      rescue Exception => e
        @events.attribute_file_load_failed(filename, e)
        raise
      end

      def load_libraries_from_cookbook(cookbook_name)
        files_in_cookbook_by_segment(cookbook_name, :libraries).each do |filename|
          next unless File.extname(filename) == ".rb"
          begin
            Chef::Log.debug("Loading cookbook #{cookbook_name}'s library file: #{filename}")
            Kernel.load(filename)
            @events.library_file_loaded(filename)
          rescue Exception => e
            @events.library_file_load_failed(filename, e)
            raise
          end
        end
      end

      def load_lwrps_from_cookbook(cookbook_name)
        files_in_cookbook_by_segment(cookbook_name, :providers).each do |filename|
          load_lwrp_provider(cookbook_name, filename)
        end
        files_in_cookbook_by_segment(cookbook_name, :resources).each do |filename|
          load_lwrp_resource(cookbook_name, filename)
        end
      end

      def load_lwrp_provider(cookbook_name, filename)
        Chef::Log.debug("Loading cookbook #{cookbook_name}'s providers from #{filename}")
        Chef::Provider::LWRPBase.build_from_file(cookbook_name, filename, self)
        @events.lwrp_file_loaded(filename)
      rescue Exception => e
        @events.lwrp_file_load_failed(filename, e)
        raise
      end

      def load_lwrp_resource(cookbook_name, filename)
        Chef::Log.debug("Loading cookbook #{cookbook_name}'s resources from #{filename}")
        Chef::Resource::LWRPBase.build_from_file(cookbook_name, filename, self)
        @events.lwrp_file_loaded(filename)
      rescue Exception => e
        @events.lwrp_file_load_failed(filename, e)
        raise
      end

      def load_ohai_plugins_from_cookbook(cookbook_name)
        target = Chef::Config[:ohai_segment_plugin_path]
        files_in_cookbook_by_segment(cookbook_name, :ohai).each do |filename|
          next unless File.extname(filename) == ".rb"

          Chef::Log.debug "Loading Ohai plugin: #{filename} from #{cookbook_name}"
          target_name = File.join(target, cookbook_name.to_s, File.basename(filename))

          FileUtils.mkdir_p(File.dirname(target_name))
          FileUtils.cp(filename, target_name)
        end
      end

      def load_resource_definitions_from_cookbook(cookbook_name)
        files_in_cookbook_by_segment(cookbook_name, :definitions).each do |filename|
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
            raise
          end
        end
      end

      # Builds up the list of +ordered_cookbooks+ by first recursing through the
      # dependencies of +cookbook+, and then adding +cookbook+ to the list of
      # +ordered_cookbooks+. A cookbook is skipped if it appears in
      # +seen_cookbooks+, otherwise it is added to the set of +seen_cookbooks+
      # before its dependencies are processed.
      def add_cookbook_with_deps(ordered_cookbooks, seen_cookbooks, cookbook)
        return false if seen_cookbooks.key?(cookbook)

        seen_cookbooks[cookbook] = true
        each_cookbook_dep(cookbook) do |dependency|
          add_cookbook_with_deps(ordered_cookbooks, seen_cookbooks, dependency)
        end
        ordered_cookbooks << cookbook
      end

      def count_files_by_segment(segment, root_alias = nil)
        cookbook_collection.inject(0) do |count, cookbook_by_name|
          count + cookbook_by_name[1].segment_filenames(segment).size + (root_alias ? cookbook_by_name[1].files_for(:root_files).select { |record| record[:name] == root_alias }.size : 0)
        end
      end

      # Lists the local paths to files in +cookbook+ of type +segment+
      # (attribute, recipe, etc.), sorted lexically.
      def files_in_cookbook_by_segment(cookbook, segment)
        cookbook_collection[cookbook].files_for(segment).map { |record| record[:full_path] }.sort
      end

      # Yields the name, as a symbol, of each cookbook depended on by
      # +cookbook_name+ in lexical sort order.
      def each_cookbook_dep(cookbook_name, &block)
        cookbook = cookbook_collection[cookbook_name]
        cookbook.metadata.dependencies.keys.sort.map { |x| x.to_sym }.each(&block)
      end

      # Given a +recipe_name+, finds the file associated with the recipe.
      def resolve_recipe(recipe_name)
        cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name)
        cookbook = cookbook_collection[cookbook_name]
        cookbook.recipe_filenames_by_name[recipe_short_name]
      end

    end

  end
end
