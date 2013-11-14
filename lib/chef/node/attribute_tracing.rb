class Chef

  class Config
    default :trace_attributes, 'none'

    config_attr_writer :trace_attributes do |path|
      if ['none', 'all'].include?(path) then
        path
      elsif path.match(%r{^/(\w+)(/\w+)*$})
        path
      else
        raise Chef::Exceptions::ConfigurationError, "'trace_attributes' setting should be either 'none', 'all', or a path like /foo/bar"
      end
    end
  end

  class Node
    class Attribute < Mash

      private

      def trace_attribute_change(level, new_data)
        # Determine trace mode
        # if none, return
        # Determine attr path
        # Run trace to determine assignment location
        # If trace mode is log
        #   emit log message
        # if trace mode is store
        #   add to internal tracelog
      end
    end
  end
end
