
require "chef/mixin/descendants_tracker"

class Chef
  module Mixin
    module Provides
      # TODO no longer needed, remove or deprecate?
      include Chef::Mixin::DescendantsTracker

      def provides(short_name, opts = {})
        raise NotImplementedError, :provides
      end

      # Check whether this resource provides the resource_name DSL for the given
      # node.  TODO remove this when we stop checking unregistered things.
      # FIXME: yard with @yield
      def provides?(node, resource)
        raise NotImplementedError, :provides?
      end

      # Get the list of recipe DSL this resource is responsible for on the given
      # node.
      def provided_as(node)
        node_map.list(node)
      end
    end
  end
end
