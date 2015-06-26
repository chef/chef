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

require 'chef/resource'
require 'chef/resource_resolver'
require 'chef/node'
require 'chef/log'
require 'chef/exceptions'
require 'chef/mixin/convert_to_class_name'
require 'chef/mixin/from_file'
require 'chef/mixin/params_validate' # for DelayedEvaluator

class Chef
  class Resource

    # == Chef::Resource::LWRPBase
    # Base class for LWRP resources. Adds DSL sugar on top of Chef::Resource,
    # so attributes, default action, etc. can be defined with pleasing syntax.
    class LWRPBase < Resource

      # Class methods
      class <<self

        include Chef::Mixin::ConvertToClassName
        include Chef::Mixin::FromFile

        attr_accessor :loaded_lwrps

        def build_from_file(cookbook_name, filename, run_context)
          if LWRPBase.loaded_lwrps[filename]
            Chef::Log.info("LWRP resource #{filename} from cookbook #{cookbook_name} has already been loaded!  Skipping the reload.")
            return loaded_lwrps[filename]
          end

          resource_name = filename_to_qualified_string(cookbook_name, filename)

          # We load the class first to give it a chance to set its own name
          deprecated_resource_class = Class.new(self).tap do |resource_class|
            resource_class.resource_name(nil)
            resource_class.run_context = run_context
            resource_class.instance_eval do
              define_method(:initialize) do |*args, &block|
                Chef::Log::deprecation("Deprecated Thing") if chef_deprecated_access
                super(*args, &block)
              end
              define_method(:chef_deprecated_access) do
                true
              end
            end

            resource_class.class_from_file(filename)

            # Make a useful string for the class (rather than <Class:312894723894>)
            resource_class.instance_eval do
              define_singleton_method(:to_s) do
                "LWRP resource #{resource_name} from cookbook #{cookbook_name}"
              end
              define_singleton_method(:inspect) { to_s }
            end
          end

          resource_class = Class.new(deprecated_resource_class).tap do |resource_class|
            resource_class.resource_name(resource_name.to_sym)
            resource_class.run_context = run_context
            resource_class.instance_eval do
              define_method(:chef_deprecated_access) do
                false
              end
            end
            resource_class.class_eval do
              define_singleton_method(:===) do |instance|
                super(instance) || instance.class <= deprecated_resource_class
              end
            end
          end

          deprecated_resource_class.class_eval do
            define_method(:kind_of?) do |klass|
              super(klass) || klass == resource_class
            end
            define_method(:is_a?) do |klass|
              super(klass) || klass == resource_class
            end
          end

          Chef::Log.debug("Loaded contents of #{filename} into resource #{resource_name} (#{resource_class})")

          LWRPBase.loaded_lwrps[filename] = true

          # Create the deprecated Chef::Resource::LwrpFoo class
          Chef::Resource.register_deprecated_lwrp_class(deprecated_resource_class, convert_to_class_name(resource_name))
          resource_class
        end

        alias :attribute :property

        # Adds +action_names+ to the list of valid actions for this resource.
        # Does not include superclass's action list when appending.
        def actions(*action_names)
          action_names = action_names.flatten
          if !action_names.empty? && !@allowed_actions
            self.allowed_actions = ([ :nothing ] + action_names).uniq
          else
            allowed_actions(*action_names)
          end
        end
        alias :actions= :allowed_actions=

        # @deprecated
        def valid_actions(*args)
          Chef::Log.warn("`valid_actions' is deprecated, please use allowed_actions `instead'!")
          allowed_actions(*args)
        end

        # Set the run context on the class. Used to provide access to the node
        # during class definition.
        attr_accessor :run_context

        def node
          run_context ? run_context.node : nil
        end

        def lazy(&block)
          DelayedEvaluator.new(&block)
        end

        protected

        def loaded_lwrps
          @loaded_lwrps ||= {}
        end

        private

        # Get the value from the superclass, if it responds, otherwise return
        # +nil+. Since class instance variables are **not** inherited upon
        # subclassing, this is a required check to ensure Chef pulls the
        # +default_action+ and other DSL-y methods when extending LWRP::Base.
        def from_superclass(m, default = nil)
          return default if superclass == Chef::Resource::LWRPBase
          superclass.respond_to?(m) ? superclass.send(m) : default
        end
      end
    end
  end
end
