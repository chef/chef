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
        yes_or_no = run_context.definitions.has_key?(name)

        yes_or_no
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
        new_recipe
      end

      # Instantiates a resource (via #build_resource), then adds it to the
      # resource collection. Note that resource classes are looked up directly,
      # so this will create the resource you intended even if the method name
      # corresponding to that resource has been overridden.
      def declare_resource(type, name, created_at=nil, &resource_attrs_block)
        created_at ||= caller[0]

        resource = build_resource(type, name, created_at, &resource_attrs_block)

        run_context.resource_collection.insert(resource)
        resource
      end

      # Instantiate a resource of the given +type+ with the given +name+ and
      # attributes as given in the +resource_attrs_block+.
      #
      # The resource is NOT added to the resource collection.
      def build_resource(type, name, created_at=nil, &resource_attrs_block)
        created_at ||= caller[0]

        # Checks the new platform => short_name => resource mapping initially
        # then fall back to the older approach (Chef::Resource.const_get) for
        # backward compatibility
        resource_class = resource_class_for(type)

        raise ArgumentError, "You must supply a name when declaring a #{type} resource" if name.nil?

        resource = resource_class.new(name, run_context)
        resource.source_line = created_at
        # If we have a resource like this one, we want to steal its state
        # This behavior is very counter-intuitive and should be removed.
        # See CHEF-3694, https://tickets.opscode.com/browse/CHEF-3694
        # Moved to this location to resolve CHEF-5052, https://tickets.opscode.com/browse/CHEF-5052
        resource.load_prior_resource
        resource.cookbook_name = cookbook_name
        resource.recipe_name = recipe_name
        # Determine whether this resource is being created in the context of an enclosing Provider
        resource.enclosing_provider = self.is_a?(Chef::Provider) ? self : nil

        # XXX: This is very crufty, but it's required for resource definitions
        # to work properly :(
        resource.params = @params

        # Evaluate resource attribute DSL
        resource.instance_eval(&resource_attrs_block) if block_given?

        # Run optional resource hook
        resource.after_created

        resource
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

    end
  end
end

# We require this at the BOTTOM of this file to avoid circular requires (it is used
# at runtime but not load time)
require 'chef/resource'

# **DEPRECATED**
# This used to be part of chef/mixin/recipe_definition_dsl_core. Load the file to activate the deprecation code.
require 'chef/mixin/recipe_definition_dsl_core'
