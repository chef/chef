#
# Author:: Daniel DeLeo (<dan@chef.io>)
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
#

autoload :Set, "set"
require_relative "../log"
require_relative "../recipe"
require_relative "../resource/lwrp_base"
require_relative "../provider/lwrp_base"
require_relative "../resource_definition_list"

class Chef
  class RunContext

    # Implements the compile phase of the chef run by loading/eval-ing files
    # from cookbooks in the correct order and in the correct context.
    class CookbookCompiler
      attr_reader :events
      attr_reader :run_list_expansion
      attr_reader :logger
      attr_reader :run_context

      def initialize(run_context, run_list_expansion, events)
        @run_context = run_context
        @events = events
        @run_list_expansion = run_list_expansion
        @cookbook_order = nil
        @logger = run_context.logger.with_child(subsystem: "cookbook_compiler")
      end

      # Chef::Node object for the current run.
      def node
        run_context.node
      end

      # Chef::CookbookCollection object for the current run
      def cookbook_collection
        run_context.cookbook_collection
      end

      # Resource Definitions from the compiled cookbooks. This is populated by
      # calling #compile_resource_definitions (which is called by #compile)
      def definitions
        run_context.definitions
      end

      # The global waiver_collection hanging off of the run_context, used by
      # compile_compliance and the compliance phase that runs inspec
      #
      # @returns [Chef::Compliance::WaiverCollection]
      #
      def waiver_collection
        run_context.waiver_collection
      end

      # The global input_collection hanging off of the run_context, used by
      # compile_compliance and the compliance phase that runs inspec
      #
      # @returns [Chef::Compliance::inputCollection]
      #
      def input_collection
        run_context.input_collection
      end

      # The global profile_collection hanging off of the run_context, used by
      # compile_compliance and the compliance phase that runs inspec
      #
      # @returns [Chef::Compliance::ProfileCollection]
      #
      def profile_collection
        run_context.profile_collection
      end

      # Run the compile phase of the chef run. Loads files in the following order:
      # * Libraries
      # * Ohai
      # * Compliance Profiles/Waivers
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
        compile_compliance
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
          logger.debug("Cookbooks to compile: #{ordered_cookbooks.inspect}")
          ordered_cookbooks
        end
      end

      # Loads library files from cookbooks according to #cookbook_order.
      def compile_libraries
        events.library_load_start(count_files_by_segment(:libraries))
        cookbook_order.each do |cookbook|
          eager_load_libraries = cookbook_collection[cookbook].metadata.eager_load_libraries
          if eager_load_libraries == true # actually true, not truthy
            load_libraries_from_cookbook(cookbook)
          else
            $LOAD_PATH.unshift File.expand_path("libraries", cookbook_collection[cookbook].root_dir)
            if eager_load_libraries # we have a String or Array<String> and not false
              load_libraries_from_cookbook(cookbook, eager_load_libraries)
            end
          end
        end
        events.library_load_complete
      end

      # Loads Ohai Plugins from cookbooks, and ensure any old ones are
      # properly cleaned out
      def compile_ohai_plugins
        ohai_plugin_count = count_files_by_segment(:ohai)
        events.ohai_plugin_load_start(ohai_plugin_count)
        FileUtils.rm_rf(Chef::Config[:ohai_segment_plugin_path])

        cookbook_order.each do |cookbook|
          load_ohai_plugins_from_cookbook(cookbook)
        end

        # Doing a full ohai system check is costly, so only do so if we've loaded additional plugins
        if ohai_plugin_count > 0
          # FIXME(log): figure out what the ohai logger looks like here
          ohai = Ohai::System.new.run_additional_plugins(Chef::Config[:ohai_segment_plugin_path])
          node.consume_ohai_data(ohai)
        end

        events.ohai_plugin_load_complete
      end

      # Loads the compliance segment files from the cookbook into the collections
      # hanging off of the run_context, for later use in the compliance phase
      # inspec run.
      #
      def compile_compliance
        events.compliance_load_start
        events.profiles_load_start
        cookbook_order.each do |cookbook|
          load_profiles_from_cookbook(cookbook)
        end
        events.profiles_load_complete
        events.inputs_load_start
        cookbook_order.each do |cookbook|
          load_inputs_from_cookbook(cookbook)
        end
        events.inputs_load_complete
        events.waivers_load_start
        cookbook_order.each do |cookbook|
          load_waivers_from_cookbook(cookbook)
        end
        events.waivers_load_complete
        events.compliance_load_complete
      end

      # Loads attributes files from cookbooks. Attributes files are loaded
      # according to #cookbook_order; within a cookbook, +default.rb+ is loaded
      # first, then the remaining attributes files in lexical sort order.
      def compile_attributes
        events.attribute_load_start(count_files_by_segment(:attributes, "attributes.rb"))
        cookbook_order.each do |cookbook|
          load_attributes_from_cookbook(cookbook)
        end
        events.attribute_load_complete
      end

      # Loads LWRPs according to #cookbook_order. Providers are loaded before
      # resources on a cookbook-wise basis.
      def compile_lwrps
        lwrp_file_count = count_files_by_segment(:providers) + count_files_by_segment(:resources)
        events.lwrp_load_start(lwrp_file_count)
        cookbook_order.each do |cookbook|
          load_lwrps_from_cookbook(cookbook)
        end
        events.lwrp_load_complete
      end

      # Loads resource definitions according to #cookbook_order
      def compile_resource_definitions
        events.definition_load_start(count_files_by_segment(:definitions))
        cookbook_order.each do |cookbook|
          load_resource_definitions_from_cookbook(cookbook)
        end
        events.definition_load_complete
      end

      # Iterates over the expanded run_list, loading each recipe in turn.
      def compile_recipes
        events.recipe_load_start(run_list_expansion.recipes.size)
        run_list_expansion.recipes.each do |recipe|

          path = resolve_recipe(recipe)
          run_context.load_recipe(recipe)
          events.recipe_file_loaded(path, recipe)
        rescue Chef::Exceptions::RecipeNotFound => e
          events.recipe_not_found(e)
          raise
        rescue Exception => e
          events.recipe_file_load_failed(path, e, recipe)
          raise

        end
        events.recipe_load_complete
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
        root_alias = cookbook_collection[cookbook_name].files_for(:root_files).find { |record| record[:name] == "root_files/attributes.rb" }
        default_file = list_of_attr_files.find { |path| File.basename(path) == "default.rb" }
        if root_alias
          if default_file
            logger.error("Cookbook #{cookbook_name} contains both attributes.rb and and attributes/default.rb, ignoring attributes/default.rb")
            list_of_attr_files.delete(default_file)
          end
          # The actual root_alias path decoding is handled in CookbookVersion#attribute_filenames_by_short_filename
          load_attribute_file(cookbook_name.to_s, "default")
        elsif default_file
          list_of_attr_files.delete(default_file)
          load_attribute_file(cookbook_name.to_s, default_file)
        end

        list_of_attr_files.each do |filename|
          next unless File.extname(filename) == ".rb"

          load_attribute_file(cookbook_name.to_s, filename)
        end
      end

      def load_attribute_file(cookbook_name, filename)
        logger.trace("Node #{node.name} loading cookbook #{cookbook_name}'s attribute file #{filename}")
        attr_file_basename = ::File.basename(filename, ".rb")
        node.include_attribute("#{cookbook_name}::#{attr_file_basename}")
      rescue Exception => e
        events.attribute_file_load_failed(filename, e)
        raise
      end

      def load_libraries_from_cookbook(cookbook_name, globs = "**/*.rb")
        each_file_in_cookbook_by_segment(cookbook_name, :libraries, globs) do |filename|

          logger.trace("Loading cookbook #{cookbook_name}'s library file: #{filename}")
          Kernel.require(filename)
          events.library_file_loaded(filename)
        rescue Exception => e
          events.library_file_load_failed(filename, e)
          raise

        end
      end

      def load_lwrps_from_cookbook(cookbook_name)
        files_in_cookbook_by_segment(cookbook_name, :providers).each do |filename|
          next unless File.extname(filename) == ".rb"
          next if File.basename(filename).match?(/^_/)

          load_lwrp_provider(cookbook_name, filename)
        end
        files_in_cookbook_by_segment(cookbook_name, :resources).each do |filename|
          next unless File.extname(filename) == ".rb"
          next if File.basename(filename).match?(/^_/)

          load_lwrp_resource(cookbook_name, filename)
        end
      end

      def load_lwrp_provider(cookbook_name, filename)
        logger.trace("Loading cookbook #{cookbook_name}'s providers from #{filename}")
        Chef::Provider::LWRPBase.build_from_file(cookbook_name, filename, self)
        events.lwrp_file_loaded(filename)
      rescue Exception => e
        events.lwrp_file_load_failed(filename, e)
        raise
      end

      def load_lwrp_resource(cookbook_name, filename)
        logger.trace("Loading cookbook #{cookbook_name}'s resources from #{filename}")
        Chef::Resource::LWRPBase.build_from_file(cookbook_name, filename, self)
        events.lwrp_file_loaded(filename)
      rescue Exception => e
        events.lwrp_file_load_failed(filename, e)
        raise
      end

      def load_ohai_plugins_from_cookbook(cookbook_name)
        target = Chef::Config[:ohai_segment_plugin_path]
        files_in_cookbook_by_segment(cookbook_name, :ohai).each do |filename|
          next unless File.extname(filename) == ".rb"

          logger.trace "Loading Ohai plugin: #{filename} from #{cookbook_name}"
          target_name = File.join(target, cookbook_name.to_s, File.basename(filename))

          FileUtils.mkdir_p(File.dirname(target_name))
          FileUtils.cp(filename, target_name)
        end
      end

      # Load the compliance segment files from a single cookbook
      #
      def load_profiles_from_cookbook(cookbook_name)
        # This identifies profiles by their inspec.yml file, we recurse into subdirs so the profiles may be deeply
        # nested in a subdir structure for organization.  You could have profiles inside of profiles but
        # since that is not coherently defined, you should not.
        #
        each_file_in_cookbook_by_segment(cookbook_name, :compliance, [ "profiles/**/inspec.{yml,yaml}" ]) do |filename|
          profile_collection.from_file(filename, cookbook_name)
        end
      end

      def load_waivers_from_cookbook(cookbook_name)
        # This identifies waiver files as any yaml files under the waivers subdir.  We recurse into subdirs as well
        # so that waivers may be nested in subdirs for organization.  Any other files are ignored.
        #
        each_file_in_cookbook_by_segment(cookbook_name, :compliance, [ "waivers/**/*.{yml,yaml}" ]) do |filename|
          waiver_collection.from_file(filename, cookbook_name)
        end
      end

      def load_inputs_from_cookbook(cookbook_name)
        # This identifies input files as any yaml files under the inputs subdir.  We recurse into subdirs as well
        # so that inputs may be nested in subdirs for organization.  Any other files are ignored.
        #
        each_file_in_cookbook_by_segment(cookbook_name, :compliance, [ "inputs/**/*.{yml,yaml}" ]) do |filename|
          input_collection.from_file(filename, cookbook_name)
        end
      end

      def load_resource_definitions_from_cookbook(cookbook_name)
        files_in_cookbook_by_segment(cookbook_name, :definitions).each do |filename|
          next unless File.extname(filename) == ".rb"

          begin
            logger.trace("Loading cookbook #{cookbook_name}'s definitions from #{filename}")
            resourcelist = Chef::ResourceDefinitionList.new
            resourcelist.from_file(filename)
            definitions.merge!(resourcelist.defines) do |key, oldval, newval|
              logger.info("Overriding duplicate definition #{key}, new definition found in #{filename}")
              newval
            end
            events.definition_file_loaded(filename)
          rescue Exception => e
            events.definition_file_load_failed(filename, e)
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
          count + cookbook_by_name[1].segment_filenames(segment).size + (root_alias ? cookbook_by_name[1].files_for(:root_files).count { |record| record[:name] == root_alias } : 0)
        end
      end

      # Lists the local paths to files in +cookbook+ of type +segment+
      # (attribute, recipe, etc.), sorted lexically.
      def files_in_cookbook_by_segment(cookbook, segment)
        cookbook_collection[cookbook].files_for(segment).map { |record| record[:full_path] }.sort
      end

      # Iterates through all files in given cookbook segment, yielding the full path to the file
      # if it matches one of the given globs.  Returns matching files in lexical sort order.  Supports
      # extended globbing.  The segment should not be included in the glob.
      #
      def each_file_in_cookbook_by_segment(cookbook, segment, globs)
        cookbook_collection[cookbook].files_for(segment).sort_by { |record| record[:path] }.each do |record|
          Array(globs).each do |glob|
            target = record[:path].delete_prefix("#{segment}/")
            if File.fnmatch(glob, target, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH)
              yield record[:full_path]
              break
            end
          end
        end
      end

      # Yields the name, as a symbol, of each cookbook depended on by
      # +cookbook_name+ in lexical sort order.
      def each_cookbook_dep(cookbook_name, &block)
        cookbook = cookbook_collection[cookbook_name]
        cookbook.metadata.dependencies.keys.sort.map(&:to_sym).each(&block)
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
