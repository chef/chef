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
  class ProviderResolver

    attr_reader :node
    attr_reader :resource
    attr_reader :action

    def initialize(node, resource, action)
      @node = node
      @resource = resource
      @action = action
    end

    # return a deterministically sorted list of Chef::Provider subclasses
    def providers
      @providers ||= Chef::Provider.descendants.sort {|a,b| a.to_s <=> b.to_s }
    end

    def resolve
      maybe_explicit_provider(resource) ||
        maybe_dynamic_provider_resolution(resource, action) ||
        maybe_chef_platform_lookup(resource)
    end

    # this cut looks at if the provider can handle the resource type on the node
    def enabled_handlers
      @enabled_handlers ||=
        providers.select do |klass|
          klass.provides?(node, resource)
        end
    end

    # this cut looks at if the provider can handle the specific resource and action
    def supported_handlers
      @supported_handlers ||=
        enabled_handlers.select do |klass|
          klass.supports?(resource, action)
        end
    end

    private

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource)
      return nil unless resource.provider
      resource.provider
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      # log this so we know what providers will work for the generic resource on the node (early cut)
      Chef::Log.debug "providers for generic #{resource.resource_name} resource enabled on node include: #{enabled_handlers}"

      # what providers were excluded by machine state (late cut)
      Chef::Log.debug "providers that refused resource #{resource} were: #{enabled_handlers - supported_handlers}"
      Chef::Log.debug "providers that support resource #{resource} include: #{supported_handlers}"

      # if none of the providers specifically support the resource, we still need to pick one of the providers that are
      # enabled on the node to handle the why-run use case.
      handlers = supported_handlers.empty? ? enabled_handlers : supported_handlers
      Chef::Log.debug "no providers supported the resource, falling back to enabled handlers" if supported_handlers.empty?

      if handlers.count >= 2
        # this magic stack ranks the providers by where they appear in the provider_priority_map, it is mostly used
        # to pick amongst N different ways to start init scripts on different debian/ubuntu systems.
        priority_list = [ get_provider_priority_map(resource.resource_name, node) ].flatten.compact
        handlers = handlers.sort_by { |x| i = priority_list.index x; i.nil? ? Float::INFINITY : i }
        handlers = [ handlers.first ]
      end

      Chef::Log.debug "providers that survived replacement include: #{handlers}"

      raise Chef::Exceptions::AmbiguousProviderResolution.new(resource, handlers) if handlers.count >= 2

      Chef::Log.debug "dynamic provider resolver FAILED to resolve a provider" if handlers.empty?

      return nil if handlers.empty?

      handlers[0]
    end

    # try the old static lookup of providers by platform
    def maybe_chef_platform_lookup(resource)
      Chef::Platform.find_provider_for_node(node, resource)
    end

    # dep injection hooks
    def get_provider_priority_map(resource_name, node)
      provider_priority_map.get(node, resource_name)
    end

    def provider_priority_map
      Chef::Platform::ProviderPriorityMap.instance.priority_map
    end
  end
end
