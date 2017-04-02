#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2015-2017, Chef Software Inc.
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
require "chef/platform/resource_priority_map"
require "chef/mixin/convert_to_class_name"

class Chef
  class ResourceResolver
    #
    # Resolve a resource by name.
    #
    # @param resource_name [Symbol] The resource DSL name (e.g. `:file`).
    # @param node [Chef::Node] The node against which to resolve. `nil` causes
    #   platform filters to be ignored.
    #
    def self.resolve(resource_name, node: nil, canonical: nil)
      new(node, resource_name, canonical: canonical).resolve
    end

    #
    # Resolve a list of all resources that implement the given DSL (in order of
    # preference).
    #
    # @param resource_name [Symbol] The resource DSL name (e.g. `:file`).
    # @param node [Chef::Node] The node against which to resolve. `nil` causes
    #   platform filters to be ignored.
    # @param canonical [Boolean] `true` or `false` to match canonical or
    #   non-canonical values only. `nil` to ignore canonicality.
    #
    def self.list(resource_name, node: nil, canonical: nil)
      new(node, resource_name, canonical: canonical).list
    end

    include Chef::Mixin::ConvertToClassName

    # @api private
    attr_reader :node
    # @api private
    attr_reader :resource_name
    # @api private
    attr_reader :action
    # @api private
    attr_reader :canonical

    #
    # Create a resolver.
    #
    # @param node [Chef::Node] The node against which to resolve. `nil` causes
    #   platform filters to be ignored.
    # @param resource_name [Symbol] The resource DSL name (e.g. `:file`).
    # @param canonical [Boolean] `true` or `false` to match canonical or
    #   non-canonical values only. `nil` to ignore canonicality.  Default: `nil`
    #
    # @api private use Chef::ResourceResolver.resolve or .list instead.
    def initialize(node, resource_name, canonical: nil)
      @node = node
      @resource_name = resource_name.to_sym
      @canonical = canonical
    end

    # @api private use Chef::ResourceResolver.resolve instead.
    def resolve
      # log this so we know what resources will work for the generic resource on the node (early cut)
      Chef::Log.debug "Resources for generic #{resource_name} resource enabled on node include: #{prioritized_handlers}"

      handler = prioritized_handlers.first

      if handler
        Chef::Log.debug "Resource for #{resource_name} is #{handler}"
      else
        Chef::Log.debug "Dynamic resource resolver FAILED to resolve a resource for #{resource_name}"
      end

      handler
    end

    # @api private
    def list
      Chef::Log.debug "Resources for generic #{resource_name} resource enabled on node include: #{prioritized_handlers}"
      prioritized_handlers
    end

    #
    # Whether this DSL is provided by the given resource_class.
    #
    # Does NOT call provides? on the resource (it is assumed this is being
    # called *from* provides?).
    #
    # @api private
    def provided_by?(resource_class)
      potential_handlers.include?(resource_class)
    end

    #
    # Whether the given handler attempts to provide the resource class at all.
    #
    # @api private
    def self.includes_handler?(resource_name, resource_class)
      handler_map.list(nil, resource_name).include?(resource_class)
    end

    protected

    def self.priority_map
      Chef.resource_priority_map
    end

    def self.handler_map
      Chef.resource_handler_map
    end

    def priority_map
      Chef.resource_priority_map
    end

    def handler_map
      Chef.resource_handler_map
    end

    # @api private
    def potential_handlers
      handler_map.list(node, resource_name, canonical: canonical).uniq
    end

    def enabled_handlers
      potential_handlers.select { |handler| !overrode_provides?(handler) || handler.provides?(node, resource_name) }
    end

    def prioritized_handlers
      @prioritized_handlers ||= begin
        enabled_handlers = self.enabled_handlers

        prioritized = priority_map.list(node, resource_name, canonical: canonical).flatten(1)
        prioritized &= enabled_handlers # Filter the priority map by the actual enabled handlers
        prioritized |= enabled_handlers # Bring back any handlers that aren't in the priority map, at the *end* (ordered set)
        prioritized
      end
    end

    def overrode_provides?(handler)
      handler.method(:provides?).owner != Chef::Resource.method(:provides?).owner
    end
  end
end
