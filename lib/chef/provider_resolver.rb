#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

require 'chef/exceptions'
require 'chef/platform/provider_priority_map'

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
        maybe_dynamic_provider_resolution(resource, action)
    end

    def provided_by?(provider_class)
      prioritized_handlers.include?(provider_class)
    end

    private

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource)
      return nil unless resource.provider
      resource.provider
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      Chef::Log.debug "Providers for generic #{resource.resource_name} resource enabled on node include: #{enabled_handlers}"

      # Get all the handlers in the priority bucket
      handlers = prioritized_handlers

      # Narrow it down to handlers that return `true` to `provides?`
      # TODO deprecate this and don't bother calling--the fact that they said
      # `provides` should be enough.  But we need to do it right now because
      # some classes implement additional handling.
      enabled_handlers = prioritized_handlers.select { |handler| handler.provides?(node, resource) }

      # Narrow it down to handlers that return `true` to `supports?`
      # TODO deprecate this and allow actions to be passed as a filter to
      # `provides` so we don't have to have two separate things.
      supported_handlers = handlers.select { |handler| handler.supports?(resource, action) }
      if supported_handlers.empty?
        # if none of the providers specifically support the resource, we still need to pick one of the providers that are
        # enabled on the node to handle the why-run use case. FIXME we should only do this in why-run mode then.
        Chef::Log.debug "No providers responded true to `supports?` for action #{action} on resource #{resource}, falling back to enabled handlers so we can return something anyway."
        handler = enabled_handlers.first
      else
        handler = supported_handlers.first
      end

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

    def provider_priority_map
      Chef::Platform::ProviderPriorityMap.instance
    end

    def prioritized_handlers
      @prioritized_handlers ||=
        provider_priority_map.list_handlers(node, resource.resource_name).flatten(1).uniq
    end

    module Deprecated
      # return a deterministically sorted list of Chef::Provider subclasses
      def providers
        @providers ||= Chef::Provider.descendants
      end

      # this cut looks at if the provider can handle the resource type on the node
      def enabled_handlers
        @enabled_handlers ||=
          providers.select do |klass|
            # NB: this is different from resource_resolver which must pass a resource_name
            # FIXME: deprecate this and normalize on passing resource_name here
            klass.provides?(node, resource)
          end.sort {|a,b| a.to_s <=> b.to_s }
      end

      # this cut looks at if the provider can handle the specific resource and action
      def supported_handlers
        @supported_handlers ||=
          enabled_handlers.select do |klass|
            klass.supports?(resource, action)
          end
      end

      # If there are no providers for a DSL, we search through the
      def prioritized_handlers
        @prioritized_handlers ||= super || begin
          result = providers.select { |handler| handler.provides?(node, resource) }.sort_by(:name)
          if !result.empty?
            Chef::Log.deprecation("#{resource.resource_name.to_sym} is marked as providing DSL #{method_symbol}, but provides #{resource.resource_name.to_sym.inspect} was never called!")
            Chef::Log.deprecation("In Chef 13, this will break: you must call provides to mark the names you provide, even if you also override provides? yourself.")
          end
          result
        end
      end
    end
    prepend Deprecated
  end
end
