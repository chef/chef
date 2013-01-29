#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/resource'
require 'chef/resource_platform_map'
require 'chef/mixin/convert_to_class_name'

class Chef
  module DSL

    # == Chef::DSL::Recipe
    # Provides the primary recipe DSL functionality for defining Chef resource
    # objects via method calls.
    module Recipe

      include Chef::Mixin::ConvertToClassName

      def method_missing(method_symbol, *args, &block)
        # If we have a definition that matches, we want to use that instead.  This should
        # let you do some really crazy over-riding of "native" types, if you really want
        # to.
        if run_context.definitions.has_key?(method_symbol)
          # This dupes the high level object, but we still need to dup the params
          new_def = run_context.definitions[method_symbol].dup
          new_def.params = new_def.params.dup
          new_def.node = run_context.node
          # This sets up the parameter overrides
          new_def.instance_eval(&block) if block
          new_recipe = Chef::Recipe.new(cookbook_name, @recipe_name, run_context)
          new_recipe.params = new_def.params
          new_recipe.params[:name] = args[0]
          new_recipe.instance_eval(&new_def.recipe)
        else
          # Otherwise, we're rocking the regular resource call route.

          # Checks the new platform => short_name => resource mapping initially
          # then fall back to the older approach (Chef::Resource.const_get) for
          # backward compatibility
          resource_class = Chef::Resource.resource_for_node(method_symbol, run_context.node)

          super unless resource_class
          raise ArgumentError, "You must supply a name when declaring a #{method_symbol} resource" unless args.size > 0

          # If we have a resource like this one, we want to steal its state
          args << run_context
          resource = resource_class.new(*args)
          resource.source_line = caller[0]
          resource.load_prior_resource
          resource.cookbook_name = cookbook_name
          resource.recipe_name = @recipe_name
          resource.params = @params
          # Determine whether this resource is being created in the context of an enclosing Provider
          resource.enclosing_provider = self.is_a?(Chef::Provider) ? self : nil
          # Evaluate resource attribute DSL
          resource.instance_eval(&block) if block

          # Run optional resource hook
          resource.after_created

          run_context.resource_collection.insert(resource)
          resource
        end
      end

    end
  end
end

# **DEPRECATED**
# This used to be part of chef/mixin/recipe_definition_dsl_core. Load the file to activate the deprecation code.
require 'chef/mixin/recipe_definition_dsl_core'
