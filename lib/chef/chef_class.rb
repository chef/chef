#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

# NOTE: This class is not intended for internal use by the chef-client code.  Classes in
# chef-client should still have objects like the node and run_context injected into them
# via their initializers.  This class is still global state and will complicate writing
# unit tests for internal Chef objects.  It is intended to be used only by recipe code.

# NOTE: When adding require lines here you are creating tight coupling on a global that may be
# included in many different situations and ultimately that ends in tears with circular requires.
# Note the way that the run_context, provider_priority_map and resource_priority_map are "dependency
# injected" into this class by other objects and do not reference the class symbols in those files
# directly and we do not need to require those files here.

require "chef/platform/provider_priority_map"
require "chef/platform/resource_priority_map"
require "chef/platform/provider_handler_map"
require "chef/platform/resource_handler_map"
require "chef/deprecated"
require "chef/event_dispatch/dsl"
require "chef/deprecated"

class Chef
  class << self

    #
    # Public API
    #

    #
    # Get the node object
    #
    # @return [Chef::Node] node object of the chef-client run
    #
    attr_reader :node

    #
    # Get the run context
    #
    # @return [Chef::RunContext] run_context of the chef-client run
    #
    attr_reader :run_context

    # Register an event handler with user specified block
    #
    # @return[Chef::EventDispatch::Base] handler object
    def event_handler(&block)
      dsl = Chef::EventDispatch::DSL.new("Chef client DSL")
      dsl.instance_eval(&block)
    end

    # Get the array of providers associated with a resource_name for the current node
    #
    # @param resource_name [Symbol] name of the resource as a symbol
    #
    # @return [Array<Class>] Priority Array of Provider Classes to use for the resource_name on the node
    #
    def get_provider_priority_array(resource_name)
      result = provider_priority_map.get_priority_array(node, resource_name.to_sym)
      result = result.dup if result
      result
    end

    #
    # Get the array of resources associated with a resource_name for the current node
    #
    # @param resource_name [Symbol] name of the resource as a symbol
    #
    # @return [Array<Class>] Priority Array of Resource Classes to use for the resource_name on the node
    #
    def get_resource_priority_array(resource_name)
      result = resource_priority_map.get_priority_array(node, resource_name.to_sym)
      result = result.dup if result
      result
    end

    #
    # Set the array of providers associated with a resource_name for the current node
    #
    # @param resource_name [Symbol] name of the resource as a symbol
    # @param priority_array [Class, Array<Class>] Class or Array of Classes to set as the priority for resource_name on the node
    # @param filter [Hash] Chef::Nodearray-style filter
    #
    # @return [Array<Class>] Modified Priority Array of Provider Classes to use for the resource_name on the node
    #
    def set_provider_priority_array(resource_name, priority_array, *filter, &block)
      result = provider_priority_map.set_priority_array(resource_name.to_sym, priority_array, *filter, &block)
      result = result.dup if result
      result
    end

    #
    # Get the array of resources associated with a resource_name for the current node
    #
    # @param resource_name [Symbol] name of the resource as a symbol
    # @param priority_array [Class, Array<Class>] Class or Array of Classes to set as the priority for resource_name on the node
    # @param filter [Hash] Chef::Nodearray-style filter
    #
    # @return [Array<Class>] Modified Priority Array of Resource Classes to use for the resource_name on the node
    #
    def set_resource_priority_array(resource_name, priority_array, *filter, &block)
      result = resource_priority_map.set_priority_array(resource_name.to_sym, priority_array, *filter, &block)
      result = result.dup if result
      result
    end

    #
    # Dependency Injection API (Private not Public)
    # [ in the ruby sense these have to be public methods, but they are
    #   *NOT* for public consumption ]
    #

    #
    # Sets the resource_priority_map
    #
    # @param resource_priority_map [Chef::Platform::ResourcePriorityMap]
    #
    # @api private
    def set_resource_priority_map(resource_priority_map)
      @resource_priority_map = resource_priority_map
    end

    #
    # Sets the provider_priority_map
    #
    # @param provider_priority_map [Chef::Platform::providerPriorityMap]
    #
    # @api private
    def set_provider_priority_map(provider_priority_map)
      @provider_priority_map = provider_priority_map
    end

    #
    # Sets the node object
    #
    # @api private
    # @param node [Chef::Node]
    def set_node(node)
      @node = node
    end

    #
    # Sets the run_context object
    #
    # @param run_context [Chef::RunContext]
    #
    # @api private
    def set_run_context(run_context)
      @run_context = run_context
    end

    #
    # Resets the internal state
    #
    # @api private
    def reset!
      @run_context = nil
      @node = nil
      @provider_priority_map = nil
      @resource_priority_map = nil
      @provider_handler_map = nil
      @resource_handler_map = nil
    end

    # @api private
    def provider_priority_map
      # these slurp in the resource+provider world, so be exceedingly lazy about requiring them
      @provider_priority_map ||= Chef::Platform::ProviderPriorityMap.instance
    end

    # @api private
    def resource_priority_map
      @resource_priority_map ||= Chef::Platform::ResourcePriorityMap.instance
    end

    # @api private
    def provider_handler_map
      @provider_handler_map ||= Chef::Platform::ProviderHandlerMap.instance
    end

    # @api private
    def resource_handler_map
      @resource_handler_map ||= Chef::Platform::ResourceHandlerMap.instance
    end

    #
    # Emit a deprecation message.
    #
    # @param type The message to send. This should be a symbol, referring to
    #   a class defined in Chef::Deprecated
    # @param message  An explicit message to display, rather than the generic one
    #   associated with the deprecation.
    # @param location The location. Defaults to the caller who called you (since
    #   generally the person who triggered the check is the one that needs to be
    #   fixed).
    #
    # @example
    #     Chef.deprecated(:my_deprecation, message: "This is deprecated!")
    #
    # @api private this will likely be removed in favor of an as-yet unwritten
    #      `Chef.log`
    def deprecated(type, message, location = nil)
      location ||= Chef::Log.caller_location
      deprecation = Chef::Deprecated.create(type, message, location)
      # `run_context.events` is the primary deprecation target if we're in a
      # run. If we are not yet in a run, print to `Chef::Log`.
      if run_context && run_context.events
        run_context.events.deprecation(deprecation, location)
      else
        Chef::Log.deprecation(deprecation, location)
      end
    end

    def log_deprecation(message, location = nil)
      location ||= Chef::Log.caller_location
      Chef.deprecated(:generic, message, location)
    end
  end

  # @api private Only for test dependency injection; not evenly implemented as yet.
  def self.path_to(path)
    path
  end

  reset!
end
