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

class Chef
  class Resource

    # == Chef::Resource::LWRPBase
    # Base class for LWRP resources. Adds DSL sugar on top of Chef::Resource,
    # so attributes, default action, etc. can be defined with pleasing syntax.
    class LWRPBase < Resource

      NULL_ARG = Object.new

      extend Chef::Mixin::ConvertToClassName
      extend Chef::Mixin::FromFile

      # Evaluates the LWRP resource file and instantiates a new Resource class.
      def self.build_from_file(cookbook_name, filename, run_context)
        rname = filename_to_qualified_string(cookbook_name, filename)

        # Add log entry if we override an existing light-weight resource.
        class_name = convert_to_class_name(rname)
        overriding = Chef::Resource.const_defined?(class_name)
        Chef::Log.info("#{class_name} light-weight resource already initialized -- overriding!") if overriding

        resource_class = Class.new(self)

        resource_class.resource_name = rname
        resource_class.run_context = run_context
        resource_class.class_from_file(filename)

        Chef::Resource.const_set(class_name, resource_class)
        Chef::Log.debug("Loaded contents of #{filename} into a resource named #{rname} defined in Chef::Resource::#{class_name}")

        resource_class
      end

      # Set the resource snake_case name. Should only be called via
      # build_from_file.
      def self.resource_name=(resource_name)
        @resource_name = resource_name
      end

      # Returns the resource snake_case name
      def self.resource_name
        @resource_name
      end

      # Define an attribute on this resource, including optional validation
      # parameters.
      def self.attribute(attr_name, validation_opts={})
        # Ruby 1.8 doesn't support default arguments to blocks, but we have to
        # use define_method with a block to capture +validation_opts+.
        # Workaround this by defining two methods :(
        class_eval(<<-SHIM, __FILE__, __LINE__)
          def #{attr_name}(arg=nil)
            _set_or_return_#{attr_name}(arg)
          end
        SHIM

        define_method("_set_or_return_#{attr_name.to_s}".to_sym) do |arg|
          set_or_return(attr_name.to_sym, arg, validation_opts)
        end
      end

      # Sets the default action
      def self.default_action(action_name=NULL_ARG)
        unless action_name.equal?(NULL_ARG)
          valid_actions.push(action_name)
          @default_action = action_name
        end
        @default_action
      end

      # Adds +action_names+ to the list of valid actions for this resource.
      def self.actions(*action_names)
        valid_actions.push(*action_names)
      end

      def self.valid_actions
        @valid_actions ||= []
      end

      # Set the run context on the class. Used to provide access to the node
      # during class definition.
      def self.run_context=(run_context)
        @run_context = run_context
      end

      def self.run_context
        @run_context
      end

      def self.node
        run_context.node
      end

      # Default initializer. Sets the default action and allowed actions.
      def initialize(name, run_context=nil)
        super(name, run_context)
        @resource_name = self.class.resource_name.to_sym
        @action = self.class.default_action
        allowed_actions.push(self.class.valid_actions).flatten!
      end

    end
  end
end
