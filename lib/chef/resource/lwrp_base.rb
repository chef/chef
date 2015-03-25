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
        resource_class = nil
        rname = filename_to_qualified_string(cookbook_name, filename)

        class_name = convert_to_class_name(rname)
        if Resource.const_defined?(class_name, false)
          Chef::Log.info("#{class_name} light-weight resource is already initialized -- Skipping loading #{filename}!")
          Chef::Log.debug("Overriding already defined LWRPs is not supported anymore starting with Chef 12.")
          resource_class = Resource.const_get(class_name)
        else
          resource_class = Class.new(self)

          Chef::Resource.const_set(class_name, resource_class)
          resource_class.resource_name = rname
          resource_class.run_context = run_context
          resource_class.class_from_file(filename)

          Chef::Log.debug("Loaded contents of #{filename} into a resource named #{rname} defined in Chef::Resource::#{class_name}")
        end

        resource_class
      end

      # Set the resource name for this LWRP
      def self.resource_name(arg = NULL_ARG)
        if arg.equal?(NULL_ARG)
          @resource_name
        else
          @resource_name = arg
        end
      end

      class << self
        alias_method :resource_name=, :resource_name
      end

      # Define an attribute on this resource, including optional validation
      # parameters.
      def self.attribute(attr_name, validation_opts={})
        define_method(attr_name) do |arg=nil|
          set_or_return(attr_name.to_sym, arg, validation_opts)
        end
      end

      # Sets the default action
      def self.default_action(action_name=NULL_ARG)
        unless action_name.equal?(NULL_ARG)
          @actions ||= []
          if action_name.is_a?(Array)
            action = action_name.map { |arg| arg.to_sym }
            @actions = actions | action
            @default_action = action
          else
            action = action_name.to_sym
            @actions.push(action) unless @actions.include?(action)
            @default_action = action
          end
        end

        @default_action ||= from_superclass(:default_action)
      end

      # Adds +action_names+ to the list of valid actions for this resource.
      def self.actions(*action_names)
        if action_names.empty?
          defined?(@actions) ? @actions : from_superclass(:actions, []).dup
        else
          # BC-compat way for checking if actions have already been defined
          if defined?(@actions)
            @actions.push(*action_names)
          else
            @actions = action_names
          end
        end
      end

      # @deprecated
      def self.valid_actions(*args)
        Chef::Log.warn("`valid_actions' is deprecated, please use actions `instead'!")
        actions(*args)
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

      def self.lazy(&block)
        DelayedEvaluator.new(&block)
      end

      private

      # Get the value from the superclass, if it responds, otherwise return
      # +nil+. Since class instance variables are **not** inherited upon
      # subclassing, this is a required check to ensure Chef pulls the
      # +default_action+ and other DSL-y methods when extending LWRP::Base.
      def self.from_superclass(m, default = nil)
        return default if superclass == Chef::Resource::LWRPBase
        superclass.respond_to?(m) ? superclass.send(m) : default
      end

      # Default initializer. Sets the default action and allowed actions.
      def initialize(name, run_context=nil)
        super(name, run_context)

        # Raise an exception if the resource_name was not defined
        if self.class.resource_name.nil?
          raise Chef::Exceptions::InvalidResourceSpecification,
            "You must specify `resource_name'!"
        end

        @resource_name = self.class.resource_name.to_sym
        @action = self.class.default_action
        allowed_actions.push(self.class.actions).flatten!
      end

    end
  end
end
