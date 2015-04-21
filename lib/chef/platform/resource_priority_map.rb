class Chef
  class Platform
    class ResourcePriorityMap
      include Singleton

      def initialize
        load_default_map
      end

      def get_priority_array(node, resource_name)
        priority_map.get(node, resource_name.to_sym)
      end

      def set_priority_array(resource_name, priority_array, *filter)
        priority resource_name.to_sym, priority_array.to_a, *filter
      end

      def priority(*args)
        priority_map.set(*args)
      end

      private

      def load_default_map
        require 'chef/resources'

        # MacOSX
        priority :package, Chef::Resource::HomebrewPackage, os: "darwin"
      end

      def priority_map
        require 'chef/node_map'
        @priority_map ||= Chef::NodeMap.new
      end
    end
  end
end
