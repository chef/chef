#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
require 'chef/platform/resource_priority_map'

class Chef
  class ResourceResolver
    include Chef::Mixin::ConvertToClassName

    attr_reader :node
    attr_reader :resource
    attr_reader :action
    attr_reader :canonical

    def initialize(node, resource, canonical: nil)
      @node = node
      @resource = resource.to_sym
      @canonical = canonical
    end

    def resolve
      # log this so we know what resources will work for the generic resource on the node (early cut)
      Chef::Log.debug "Resources for generic #{resource} resource enabled on node include: #{enabled_handlers}"

      handler = prioritized_handlers.first

      if handler
        Chef::Log.debug "Resource for #{resource} is #{handler}"
      else
        Chef::Log.debug "Dynamic resource resolver FAILED to resolve a resource for #{resource}"
      end

      handler
    end

    def provided_by?(resource_class)
      !prioritized_handlers.include?(resource_class)
    end

    #
    # Resolve a resource by name.
    #
    # @param resource_name [Symbol] The resource DSL name (e.g. `:file`)
    # @param node [Chef::Node] The node on which the resource will run. If not
    #   passed, will return the first match.
    # @param canonical [Boolean] Whether to restrict the search to the canonical
    #   name (the one set by `resource_name`)
    #
    def self.resolve(resource_name, node: Chef.node, canonical: false)
      new(node, resource_name, canonical: canonical).resolve
    end

    protected

    def priority_map
      Chef::Platform::ResourcePriorityMap.instance
    end

    def prioritized_handlers
      @prioritized_handlers ||=
        priority_map.list_handlers(node, resource, canonical: nil)
    end

    module Deprecated
      # return a deterministically sorted list of Chef::Resource subclasses
      # @deprecated Now prioritized_handlers does its own work (more efficiently)
      def resources
        Chef::Resource.sorted_descendants
      end

      # A list of all handlers
      # @deprecated Now prioritized_handlers does its own work
      def enabled_handlers
        resources.select { |klass| klass.provides?(node, resource) }
      end

      protected

      # If there are no providers for a DSL, we search through the
      def prioritized_handlers
        @prioritized_handlers ||= super ||
          resources.select do |klass|
            # Don't bother calling provides? unless it's overriden. We already
            # know prioritized_handlers
            if klass.method(:provides?).owner != Chef::Resource && klass.provides?(node, resource)
              Chef::Log.deprecation("Resources #{provided.join(", ")} are marked as providing DSL #{resource}, but provides #{resource.inspect} was never called!")
              Chef::Log.deprecation("In Chef 13, this will break: you must call provides to mark the names you provide, even if you also override provides? yourself.")
              true
            end
          end
      end
    end
    prepend Deprecated
  end
end
