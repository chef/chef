#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/provider"
require "chef/dsl/recipe"
require "chef/dsl/include_recipe"

class Chef
  class Provider

    # == Chef::Provider::LWRPBase
    # Base class from which LWRP providers inherit.
    class LWRPBase < Provider

      include Chef::DSL::Recipe

      # These were previously provided by Chef::Mixin::RecipeDefinitionDSLCore.
      # They are not included by its replacement, Chef::DSL::Recipe, but
      # they may be used in existing LWRPs.
      include Chef::DSL::DataQuery

      # Allow include_recipe from within LWRP provider code
      include Chef::DSL::IncludeRecipe

      # no-op `load_current_resource`. Allows simple LWRP providers to work
      # without defining this method explicitly (silences
      # Chef::Exceptions::Override exception)
      def load_current_resource
      end

      # class methods
      class <<self
        include Chef::Mixin::ConvertToClassName
        include Chef::Mixin::FromFile

        def build_from_file(cookbook_name, filename, run_context)
          if LWRPBase.loaded_lwrps[filename]
            Chef::Log.debug("LWRP provider #{filename} from cookbook #{cookbook_name} has already been loaded!  Skipping the reload.")
            return loaded_lwrps[filename]
          end

          resource_name = filename_to_qualified_string(cookbook_name, filename)

          # We load the class first to give it a chance to set its own name
          provider_class = Class.new(self)
          provider_class.provides resource_name.to_sym
          provider_class.class_from_file(filename)

          # Respect resource_name set inside the LWRP
          provider_class.instance_eval do
            define_singleton_method(:to_s) do
              "LWRP provider #{resource_name} from cookbook #{cookbook_name}"
            end
            define_singleton_method(:inspect) { to_s }
          end

          Chef::Log.debug("Loaded contents of #{filename} into provider #{resource_name} (#{provider_class})")

          LWRPBase.loaded_lwrps[filename] = true

          provider_class
        end

        protected

        def loaded_lwrps
          @loaded_lwrps ||= {}
        end
      end
    end
  end
end
