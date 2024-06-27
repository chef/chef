module ChefUtils
  module DSL
    module Backend
      include Internal

      # Determine if the backend is local
      #
      # @param [Chef::Node] node the node to check
      #
      # @return [Boolean]
      #
      def local_mode?
        node["platform_backend"] == "local"
      end

      # Determine if the backend is remote
      #
      # @param [Chef::Node] node the node to check
      #
      # @return [Boolean]
      #
      def target_mode?
        node["platform_backend"] != "local"
      end
    end
  end
end
