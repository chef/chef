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
require 'chef/mixin/convert_to_class_name'

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
    def resource
      Chef::Log.deprecation("Chef::ResourceResolver.resource deprecated.  Use resource_name instead.")
      resource_name
    end
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
      Chef::Log.debug "Resources for generic #{resource_name} resource enabled on node include: #{enabled_handlers}"

      handler = enabled_handlers.first

      if handler
        Chef::Log.debug "Resource for #{resource_name} is #{handler}"
      else
        Chef::Log.debug "Dynamic resource resolver FAILED to resolve a resource for #{resource_name}"
      end

      handler
    end

    # @api private
    def list
      Chef::Log.debug "Resources for generic #{resource_name} resource enabled on node include: #{enabled_handlers}"
      enabled_handlers
    end

    #
    # Whether this DSL is provided by the given resource_class.
    #
    # @api private
    def provided_by?(resource_class)
      potential_handlers.include?(resource_class)
    end

    protected

    def priority_map
      Chef::Platform::ResourcePriorityMap.instance
    end

    # @api private
    def potential_handlers
      priority_map.list_handlers(node, resource_name, canonical: canonical).flatten(1).uniq
    end

    def enabled_handlers
      potential_handlers.select { |handler| handler.method(:provides?).owner == Chef::Resource || handler.provides?(node, resource_name) }
    end

    module Deprecated
      # return a deterministically sorted list of Chef::Resource subclasses
      def resources
        Chef::Resource.sorted_descendants
      end

      def enabled_handlers
        @enabled_handlers ||= begin
          handlers = potential_handlers
          if handlers.empty?
            warn = true
            handlers = resources
          end
          handlers.select do |handler|
            if handler.method(:provides?).owner == Chef::Resource
              true
            elsif handler.provides?(node, resource_name)
              if warn
                Chef::Log.deprecation("#{handler}.provides? returned true when asked if it provides DSL #{resource_name}, but provides #{resource_name.inspect} was never called!")
                Chef::Log.deprecation("In Chef 13, this will break: you must call provides to mark the names you provide, even if you also override provides? yourself.")
              end
              true
            end
          end
        end
      end
    end
    prepend Deprecated
  end
end
