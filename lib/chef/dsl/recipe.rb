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

require 'chef/mixin/convert_to_class_name'
require 'chef/exceptions'
require 'chef/resource_builder'

class Chef
  module DSL

    # == Chef::DSL::Recipe
    # Provides the primary recipe DSL functionality for defining Chef resource
    # objects via method calls.
    module Recipe

      include Chef::Mixin::ShellOut
      include Chef::Mixin::ConvertToClassName

      def method_missing(method_symbol, *args, &block)
        # If we have a definition that matches, we want to use that instead.  This should
        # let you do some really crazy over-riding of "native" types, if you really want
        # to.
        if has_resource_definition?(method_symbol)
          evaluate_resource_definition(method_symbol, *args, &block)
        elsif have_resource_class_for?(method_symbol)
          # Otherwise, we're rocking the regular resource call route.
          declare_resource(method_symbol, args[0], caller[0], &block)
        else
          begin
            super
          rescue NoMethodError
            raise NoMethodError, "No resource or method named `#{method_symbol}' for #{describe_self_for_error}"
          rescue NameError
            raise NameError, "No resource, method, or local variable named `#{method_symbol}' for #{describe_self_for_error}"
          end
        end
      end

      def has_resource_definition?(name)
        run_context.definitions.has_key?(name)
      end

      # Processes the arguments and block as a resource definition.
      def evaluate_resource_definition(definition_name, *args, &block)

        # This dupes the high level object, but we still need to dup the params
        new_def = run_context.definitions[definition_name].dup

        new_def.params = new_def.params.dup
        new_def.node = run_context.node
        # This sets up the parameter overrides
        new_def.instance_eval(&block) if block

        new_recipe = Chef::Recipe.new(cookbook_name, recipe_name, run_context)
        new_recipe.params = new_def.params
        new_recipe.params[:name] = args[0]
        new_recipe.instance_eval(&new_def.recipe)
      end

      # Instantiates a resource (via #build_resource), then adds it to the
      # resource collection. Note that resource classes are looked up directly,
      # so this will create the resource you intended even if the method name
      # corresponding to that resource has been overridden.
      def declare_resource(type, name, created_at=nil, &resource_attrs_block)
        created_at ||= caller[0]

        resource = build_resource(type, name, created_at, &resource_attrs_block)

        run_context.resource_collection.insert(resource, resource_type: type, instance_name: name)
        resource
      end

      # Instantiate a resource of the given +type+ with the given +name+ and
      # attributes as given in the +resource_attrs_block+.
      #
      # The resource is NOT added to the resource collection.
      def build_resource(type, name, created_at=nil, &resource_attrs_block)
        created_at ||= caller[0]

        Chef::ResourceBuilder.new(
          type:                type,
          name:                name,
          created_at:          created_at,
          params:              @params,
          run_context:         run_context,
          cookbook_name:       cookbook_name,
          recipe_name:         recipe_name,
          enclosing_provider:  self.is_a?(Chef::Provider) ? self :  nil
        ).build(&resource_attrs_block)
      end

      def resource_class_for(snake_case_name)
        Chef::Resource.resource_for_node(snake_case_name, run_context.node)
      end

      def have_resource_class_for?(snake_case_name)
        not resource_class_for(snake_case_name).nil?
      rescue NameError
        false
      end

      def describe_self_for_error
        if respond_to?(:name)
          %Q[`#{self.class.name} "#{name}"']
        elsif respond_to?(:recipe_name)
          %Q[`#{self.class.name} "#{recipe_name}"']
        else
          to_s
        end
      end

      def exec(args)
        raise Chef::Exceptions::ResourceNotFound, "exec was called, but you probably meant to use an execute resource.  If not, please call Kernel#exec explicitly.  The exec block called was \"#{args}\""
      end

    end
  end
end

# We require this at the BOTTOM of this file to avoid circular requires (it is used
# at runtime but not load time)
require 'chef/resource'

# **DEPRECATED**
# This used to be part of chef/mixin/recipe_definition_dsl_core. Load the file to activate the deprecation code.
require 'chef/mixin/recipe_definition_dsl_core'
