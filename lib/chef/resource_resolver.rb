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

    # return a deterministically sorted list of Chef::Resource subclasses
    def resources
      @resources ||= Chef::Resource.descendants
    end

    def resolve
      maybe_dynamic_resource_resolution ||
        maybe_chef_platform_lookup
    end

    # this cut looks at if the resource can handle the resource type on the node
    def enabled_handlers
      @enabled_handlers ||=
        resources.select do |klass|
          klass.provides?(node, resource)
        end.sort {|a,b| a.to_s <=> b.to_s }
    end

    private

    # try dynamically finding a resource based on querying the resources to see what they support
    def maybe_dynamic_resource_resolution      # log this so we know what resources will work for the generic resource on the node (early cut)
      Chef::Log.debug "resources for generic #{resource} resource enabled on node include: #{enabled_handlers}"

      # if none of the resources specifically support the resource, we still need to pick one of the resources that are
      # enabled on the node to handle the why-run use case.
      handlers = enabled_handlers

      if handlers.size >= 2
        # this magic stack ranks the resources by where they appear in the resource_priority_map
        priority_list = [ get_priority_array(node, resource) ].flatten.compact
        handlers = handlers.sort_by { |x| i = priority_list.index x; i.nil? ? Float::INFINITY : i }
        if priority_list.index(handlers.first).nil?
          # if we had more than one and we picked one with a precidence of infinity that means that the resource_priority_map
          # entry for this resource is missing -- we should probably raise here and force resolution of the ambiguity.
          Chef::Log.warn "Ambiguous resource precedence: #{handlers}, please use Chef.set_resource_priority_array to provide determinism"
        end
        handlers = handlers[0..0]
      end

      Chef::Log.debug "resources that survived replacement include: #{handlers}"

      raise Chef::Exceptions::AmbiguousResourceResolution.new(resource, handlers) if handlers.count >= 2

      Chef::Log.debug "dynamic resource resolver FAILED to resolve a resource" if handlers.empty?

      return nil if handlers.empty?

      handlers[0]
    end

    # try the old static lookup of resources by mangling name to resource klass
    def maybe_chef_platform_lookup
      Chef::Resource.resource_matching_short_name(resource)
    end

    # dep injection hooks
    def get_priority_array(node, resource_name)
      resource_priority_map.get_priority_array(node, resource_name)
    end

    def resource_priority_map
      Chef::Platform::ResourcePriorityMap.instance
    end
  end
end
