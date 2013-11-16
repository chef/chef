class Mash
  def update(other_hash)
    other_hash.each_pair { |key, value| self[key] = value }
    self
  end
end

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

      def find_path_to_entry(container, component=nil)
        # Container is a VividMash or a AttrArry, of which this object is the root.
        # Component is the precedence level - search in that VividMash, if known
        # Search for the container, and return the path and component to get to it.  

        # This is really stupid.
        components = component ? [ ('@' + component).to_sym ] : COMPONENTS
        components.each do |comp|
          binding.pry
          starter_mash = instance_variable_get(comp)
          path = starter_mash.find_path_to_entry(container)
          if path 
            return [ path, comp.to_s.sub('@', '') ]
          end
        end
        return nil
      end

      def trace_attribute_ignored_unless(collection, key, new_value)
        if Chef::Config.trace_attributes == 'none' then return end
          
        # A setting was attempted with ||= or set_unless, but a value already 
        # existed so the mutation was ignored

        # Determine the attrpath location of the ignored change
        path, component = find_path_to_entry(collection)
        path = path + '/' + key
        return unless trace_this_path?(path)
        
        binding.pry
        # Run a source trace to determine current location

        # Find out which paths we are interested in
        # Log a clear event for each
      end

      def trace_attribute_change(collection, key, new_value)
        if Chef::Config.trace_attributes == 'none' then return end
          
        # A setting was made with =
       
        # Determine the attrpath location of the change
        path, component = find_path_to_entry(collection)
        path = path + '/' + key
        return unless trace_this_path?(path)

        binding.pry
        # Run a source trace to determine current location
        # precedence, origin = source_trace_heuristics(component)

        # Log a set event for each
      end

      private

      def trace_this_path?(attrpath)
        return true if Chef::Config.trace_attributes == 'all'
        return Chef::Config.trace_attributes == attrpath
      end

      def trace_attribute_clear(component)
        if Chef::Config.trace_attributes == 'none' then return end
        
        # the entire component-level Mash is about to be nuked

        binding.pry

        # Run a source trace to determine current location
        # Iterate over the paths in it
        # Find out which paths we are interested in
        # Log a clear event for each
      end


    end
  end
end
