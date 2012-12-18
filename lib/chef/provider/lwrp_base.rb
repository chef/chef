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
