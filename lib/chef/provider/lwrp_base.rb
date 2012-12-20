#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008-2012 Opscode, Inc.
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

require 'chef/provider'

class Chef
  class Provider

    # == Chef::Provider::LWRPBase
    # Base class from which LWRP providers inherit.
    class LWRPBase < Provider

      # Chef::Provider::LWRPBase::InlineResources
      # Implementation of inline resource convergence for LWRP providers. See
      # Provider::LWRPBase.use_inline_resources for a longer explanation.
      #
      # This code is restricted to a module so that it can be selectively
      # applied to providers on an opt-in basis.
      module InlineResources

        # Class methods for InlineResources. Overrides the `action` DSL method
        # with one that enables inline resource convergence.
        module ClassMethods
          # Defines an action method on the provider, using
          # recipe_eval_with_update_check to execute the given block.
          def action(name, &block)
            define_method("action_#{name}") do
              recipe_eval_with_update_check(&block)
            end
          end
        end

        # Executes the given block in a temporary run_context with its own
        # resource collection. After the block is executed, any resources
        # declared inside are converged, and if any are updated, the
        # new_resource will be marked updated.
        def recipe_eval_with_update_check(&block)
          saved_run_context = @run_context
          temp_run_context = @run_context.dup
          @run_context = temp_run_context
          @run_context.resource_collection = Chef::ResourceCollection.new

          return_value = instance_eval(&block)
          Chef::Runner.new(@run_context).converge
          return_value
        ensure
          @run_context = saved_run_context
          if temp_run_context.resource_collection.any? {|r| r.updated? }
            new_resource.updated_by_last_action(true)
          end
        end

      end

      extend Chef::Mixin::ConvertToClassName
      extend Chef::Mixin::FromFile

      include Chef::DSL::Recipe

      # These were previously provided by Chef::Mixin::RecipeDefinitionDSLCore.
      # They are not included by its replacment, Chef::DSL::Recipe, but
      # they may be used in existing LWRPs.
      include Chef::DSL::PlatformIntrospection
      include Chef::DSL::DataQuery

      def self.build_from_file(cookbook_name, filename, run_context)
        provider_name = filename_to_qualified_string(cookbook_name, filename)

        # Add log entry if we override an existing light-weight provider.
        class_name = convert_to_class_name(provider_name)

        if Chef::Provider.const_defined?(class_name)
          Chef::Log.info("#{class_name} light-weight provider already initialized -- overriding!")
        end

        provider_class = Class.new(self)
        provider_class.class_from_file(filename)

        class_name = convert_to_class_name(provider_name)
        Chef::Provider.const_set(class_name, provider_class)
        Chef::Log.debug("Loaded contents of #{filename} into a provider named #{provider_name} defined in Chef::Provider::#{class_name}")

        provider_class
      end

      # Enables inline evaluation of resources in provider actions.
      #
      # Without this option, any resources declared inside the LWRP are added
      # to the resource collection after the current position at the time the
      # action is executed. Because they are added to the primary resource
      # collection for the chef run, they can notify other resources outside
      # the LWRP, and potentially be notified by resources outside the LWRP
      # (but this is complicated by the fact that they don't exist until the
      # provider executes). In this mode, it is impossible to correctly set the
      # updated_by_last_action flag on the parent LWRP resource, since it
      # executes and returns before its component resources are run.
      #
      # With this option enabled, each action creates a temporary run_context
      # with its own resource collection, evaluates the action's code in that
      # context, and then converges the resources created. If any resources
      # were updated, then this provider's new_resource will be marked updated.
      #
      # In this mode, resources created within the LWRP cannot interact with
      # external resources via notifies, though notifications to other
      # resources within the LWRP will work. Delayed notifications are executed
      # at the conclusion of the provider's action, *not* at the end of the
      # main chef run.
      #
      # This mode of evaluation is experimental, but is believed to be a better
      # set of tradeoffs than the append-after mode, so it will likely become
      # the default in a future major release of Chef.
      #
      def self.use_inline_resources
        extend InlineResources::ClassMethods
        include InlineResources
      end

      # DSL for defining a provider's actions.
      def self.action(name, &block)
        define_method("action_#{name}") do
          instance_eval(&block)
        end
      end

      # no-op `load_current_resource`. Allows simple LWRP providers to work
      # without defining this method explicitly (silences
      # Chef::Exceptions::Override exception)
      def load_current_resource
      end

    end
  end
end
