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
    include Chef::Mixin::ConvertToClassName

    attr_reader :node
    attr_reader :resource
    attr_reader :action

    def initialize(node, resource)
      @node = node
      @resource = resource.to_sym
    end

    def resolve
      maybe_dynamic_resource_resolution ||
        maybe_chef_platform_lookup
    end

    def provided_by?(resource_class)
      !prioritized_handlers.include?(resource_class)
    end

    #
    # Resolve a resource by name.
    #
    # @param resource_name [Symbol] The resource DSL name (e.g. `:file`)
    # @param node [Chef::Node] The node on which the resource will run.
    #
    def self.resolve(resource_name, node: Chef.node)
      new(node, resource_name).resolve
    end

    protected

    # try dynamically finding a resource based on querying the resources to see what they support
    def maybe_dynamic_resource_resolution
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

    # try the old static lookup of resources by mangling name to resource klass
    def maybe_chef_platform_lookup
      Chef::Resource.resource_matching_short_name(resource)
    end

    def priority_map
      Chef::Platform::ResourcePriorityMap.instance
    end

    def prioritized_handlers
      @prioritized_handlers ||=
        priority_map.list_handlers(node, resource)
    end

    module Deprecated
      # return a deterministically sorted list of Chef::Resource subclasses
      def resources
        @resources ||= Chef::Resource.descendants
      end

      # this cut looks at if the resource can handle the resource type on the node
      def enabled_handlers
        @enabled_handlers ||=
          resources.select do |klass|
            klass.provides?(node, resource)
          end.sort {|a,b| a.to_s <=> b.to_s }
      end

      protected

      # If there are no providers for a DSL, we search through the
      def prioritized_handlers
        @prioritized_handlers ||= super || begin
          if !enabled_handlers.empty?
            Chef::Log.deprecation("#{resource} is marked as providing DSL #{resource}, but provides #{resource.inspect} was never called!")
            Chef::Log.deprecation("In Chef 13, this will break: you must call provides to mark the names you provide, even if you also override provides? yourself.")
          end
          enabled_handlers
        end
      end
    end
    prepend Deprecated
  end
end
