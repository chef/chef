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

    def initialize(node)
      @node = node
    end

    # return a deterministically sorted list of Chef::Provider subclasses
    def providers
      Chef::Provider.descendants.sort {|a,b| a.to_s <=> b.to_s }
    end

    def resolve(resource, action)
      maybe_explicit_provider(resource) ||
        maybe_dynamic_provider_resolution(resource, action) ||
        maybe_chef_platform_lookup(resource)
    end

    private

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource)
      return nil unless resource.provider
      resource.provider
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      # this cut only depends on the node value and is going to be static for all nodes
      # will contain all providers that could possibly support a resource on a node
      enabled_handlers = providers.select do |klass|
        klass.provides?(node, resource)
      end

      # log this so we know what providers will work for the generic resource on the node (early cut)
      Chef::Log.debug "providers for generic #{resource.resource_name} resource enabled on node include: #{enabled_handlers}"

      # ask all the enabled providers if they can actually support the resource
      supported_handlers = enabled_handlers.select do |klass|
        klass.supports?(resource, action)
      end

      # what providers were excluded by machine state (late cut)
      Chef::Log.debug "providers that refused resource #{resource} were: #{enabled_handlers - supported_handlers}"
      Chef::Log.debug "providers that support resource #{resource} include: #{supported_handlers}"

      handlers = supported_handlers.empty? ? enabled_handlers : supported_handlers

      if handlers.count >= 2
        priority_list = [ get_provider_priority_map(resource.resource_name, node) ].flatten.compact

        handlers = handlers.sort_by { |x| i = priority_list.index x; i.nil? ? Float::INFINITY : i }

        handlers = [ handlers.first ]
      end

      Chef::Log.debug "providers that survived replacement include: #{handlers}"

      raise Chef::Exceptions::AmbiguousProviderResolution.new(resource, handlers) if handlers.count >= 2

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
