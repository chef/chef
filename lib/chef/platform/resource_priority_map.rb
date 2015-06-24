require 'singleton'
require 'chef/platform/priority_map'

class Chef
  class Platform
    # @api private
    class ResourcePriorityMap < Chef::Platform::PriorityMap
      include Singleton

      # @api private
      def get_priority_array(node, resource_name, canonical: nil)
        super(node, resource_name.to_sym, canonical: canonical)
      end

    end
  end
end
