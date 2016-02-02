#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright 2014-2016, Richard Manyanza.
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

require "chef/exceptions"
require "chef/platform/priority_map"

class Chef
  #
  # Provider Resolution
  # ===================
  #
  # Provider resolution is the process of taking a Resource object and an
  # action, and determining the Provider class that should be instantiated to
  # handle the action.
  #
  # If the resource has its `provider` set, that is used.
  #
  # Otherwise, we take the lists of Providers that have registered as
  # providing the DSL through `provides :dsl_name, <filters>` or
  # `Chef.set_resource_priority_array :dsl_name, <filters>`.  We filter each
  # list of Providers through:
  #
  # 1. The filters it was registered with (such as `os: 'linux'` or
  #    `platform_family: 'debian'`)
  # 2. `provides?(node, resource)`
  # 3. `supports?(resource, action)`
  #
  # Anything that passes the filter and returns `true` to provides and supports,
  # is considered a match.  The first matching Provider in the *most recently
  # registered list* is selected and returned.
  #
  class ProviderResolver

    attr_reader :node
    attr_reader :resource
    attr_reader :action

    def initialize(node, resource, action)
      @node = node
      @resource = resource
      @action = action
    end

    def resolve
      maybe_explicit_provider(resource) ||
        maybe_dynamic_provider_resolution(resource, action) ||
        maybe_chef_platform_lookup(resource)
    end

    # Does NOT call provides? on the resource (it is assumed this is being
    # called *from* provides?).
    def provided_by?(provider_class)
      potential_handlers.include?(provider_class)
    end

    def enabled_handlers
      @enabled_handlers ||= potential_handlers.select { |handler| !overrode_provides?(handler) || handler.provides?(node, resource) }
    end

    # TODO deprecate this and allow actions to be passed as a filter to
    # `provides` so we don't have to have two separate things.
    # @api private
    def supported_handlers
      enabled_handlers.select { |handler| handler.supports?(resource, action) }
    end

    private

    def potential_handlers
      handler_map.list(node, resource.resource_name).uniq
    end

    # The list of handlers, with any in the priority_map moved to the front
    def prioritized_handlers
      @prioritized_handlers ||= begin
        supported_handlers = self.supported_handlers
        if supported_handlers.empty?
          # if none of the providers specifically support the resource, we still need to pick one of the providers that are
          # enabled on the node to handle the why-run use case. FIXME we should only do this in why-run mode then.
          Chef::Log.debug "No providers responded true to `supports?` for action #{action} on resource #{resource}, falling back to enabled handlers so we can return something anyway."
          supported_handlers = enabled_handlers
        end

        prioritized = priority_map.list(node, resource.resource_name).flatten(1)
        prioritized &= supported_handlers # Filter the priority map by the actual enabled handlers
        prioritized |= supported_handlers # Bring back any handlers that aren't in the priority map, at the *end* (ordered set)
        prioritized
      end
    end

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource)
      return nil unless resource.provider
      resource.provider
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      Chef::Log.debug "Providers for generic #{resource.resource_name} resource enabled on node include: #{enabled_handlers}"

      handler = prioritized_handlers.first

      if handler
        Chef::Log.debug "Provider for action #{action} on resource #{resource} is #{handler}"
      else
        Chef::Log.debug "Dynamic provider resolver FAILED to resolve a provider for action #{action} on resource #{resource}"
      end

      handler
    end

    # try the old static lookup of providers by platform
    def maybe_chef_platform_lookup(resource)
      Chef::Platform.find_provider_for_node(node, resource)
    end

    def priority_map
      Chef.provider_priority_map
    end

    def handler_map
      Chef.provider_handler_map
    end

    def overrode_provides?(handler)
      handler.method(:provides?).owner != Chef::Provider.method(:provides?).owner
    end

    module Deprecated
      # return a deterministically sorted list of Chef::Provider subclasses
      def providers
        @providers ||= Chef::Provider.descendants
      end

      def enabled_handlers
        @enabled_handlers ||= begin
          handlers = super
          if handlers.empty?
            # Look through all providers, and find ones that return true to provides.
            # Don't bother with ones that don't override provides?, since they
            # would have been in enabled_handlers already if that were so. (It's a
            # perf concern otherwise.)
            handlers = providers.select { |handler| overrode_provides?(handler) && handler.provides?(node, resource) }
            handlers.each do |handler|
              Chef.log_deprecation("#{handler}.provides? returned true when asked if it provides DSL #{resource.resource_name}, but provides #{resource.resource_name.inspect} was never called!")
              Chef.log_deprecation("In Chef 13, this will break: you must call provides to mark the names you provide, even if you also override provides? yourself.")
            end
          end
          handlers
        end
      end
    end
    prepend Deprecated
  end
end
