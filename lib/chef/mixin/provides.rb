
require 'chef/mixin/descendants_tracker'

class Chef
  module Mixin
    module Provides
      # TODO no longer needed, remove or deprecate?
      include Chef::Mixin::DescendantsTracker

      def provides(short_name, opts={}, &block)
        provides_priority_map.priority(short_name, self, opts, &block)
      end

      # Check whether this resource provides the resource_name DSL for the given
      # node.
      def provides?(node, short_name)
        provides_priority_map.list(node, short_name).include?(self)
      end

      def provides_priority_map
        raise NotImplementedError, :provides_priority_map
      end

      # Get the list of recipe DSL this resource is responsible for on the given
      # node.
      def provided_as(node)
        node_map.list(node)
      end
    end
  end
end
