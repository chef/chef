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

    class AttributeTraceEntry
      attr_reader :precedence
      attr_reader :type
      attr_accessor :location
      attr_reader :action

      def initialize(a_precedence, a_type, a_location = nil, an_action = :set)
        @precedence  = a_precedence
        @type        = a_type
        @location    = a_location
        @action      = an_action 
      end

    end

    class Attribute < Mash

      private

      def trace_attribute_change(level, new_data)
        if Chef::Config.trace_attributes == 'none' then return end
          
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
