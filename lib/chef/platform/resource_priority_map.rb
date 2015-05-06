require 'singleton'

class Chef
  class Platform
    class ResourcePriorityMap
      include Singleton

      def get_priority_array(node, resource_name)
        priority_map.get(node, resource_name.to_sym)
      end

      def set_priority_array(resource_name, priority_array, *filter)
        priority resource_name.to_sym, Array(priority_array), *filter
      end

      def priority(*args)
        priority_map.set(*args)
      end

      # @api private
      def list_handlers(*args)
        priority_map.list(*args).flatten(1).uniq
      end

      private

      def priority_map
        require 'chef/node_map'
        @priority_map ||= Chef::NodeMap.new
      end
    end
  end
end
