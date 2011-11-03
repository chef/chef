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
require 'chef/mixin/convert_to_class_name'
require 'chef/mixin/language'

#--
# UGH. this is a circular require that will cause an uninitialized constant
# error, but this file really does depend on Chef::Recipe. oh well.
# require 'chef/recipe'

class Chef
  module Mixin
    module RecipeDefinitionDSLCore

      include Chef::Mixin::ConvertToClassName
      include Chef::Mixin::Language

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
          resource_class = Chef::Resource.find_resource_for_node(run_context.node, method_symbol)

          super unless resource_class
          raise ArgumentError, "You must supply a name when declaring a #{method_symbol} resource" unless args.size > 0

          # If we have a resource like this one, we want to steal its state
          args << run_context
          resource = resource_class.new(*args)
          resource.load_prior_resource
          resource.cookbook_name = cookbook_name
          resource.recipe_name = @recipe_name
          resource.params = @params
          resource.source_line = caller[0]
          # Determine whether this resource is being created in the context of an enclosing Provider
          resource.enclosing_provider = self.is_a?(Chef::Provider) ? self : nil
          resource.instance_eval(&block) if block

          run_context.resource_collection.insert(resource)
          resource
        end
      end

    end
  end
end
