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
      attr_reader :component
      attr_reader :source_location
      attr_reader :action
      attr_accessor :value
      attr_accessor :path

      def initialize(a_component, an_action = :set, a_source_location = nil)
        @component  = a_component
        @action      = an_action 
        if a_source_location 
          @source_location = a_source_location
        else
          # TODO: run callstack trace to determine source_location
        end
      end

    end

    class Attribute < Mash

      def find_path_to_entry(container)
        if container.respond_to?(:find_path_to_entry_ascent)           
          find_path_to_entry_ascent(container)
        else
          find_path_to_entry_descent(container)
        end
      end

      def find_path_to_entry_ascent(container)
        [ container.find_path_to_entry_ascent, container.component ]
      end

      def find_path_to_entry_descent(container, component=nil)
        # Container is a VividMash or a AttrArry, of which this object is the root.
        # Component is the precedence level - search in that VividMash, if known
        # Search for the container, and return the path and component to get to it.  

        # This is really stupid.
        components = component ? [ ('@' + component).to_sym ] : COMPONENTS
        components.each do |comp|
          # binding.pry
          starter_mash = instance_variable_get(comp)
          path = starter_mash.find_path_to_entry_descent(container)
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

        # Determine the attrpath location of the change
        path, component = find_path_to_entry_ascent(collection)

        entry = AttributeTraceEntry.new(component, :set_unless_ignore)
        entry.value = new_value

        # Path might be nil, meaning that we have a collection whose root is us, but is not yet present in one of our component VividMash.  This can happen when a hash at least two levels deep is being directly assigned and boosted to being a VividMash.  In that case, the only think we can do is go ahead and trace the change, but postpone adding it to the log for a bit.
        # TODO: does this happen in this case?
        if path.nil?
          @trace_queue.push entry
          # Nothing else we can do at this point - later pases may be able to resolve the path.
          return
        else
          entry.path = path + (path == '/' ? '' : '/') + key.to_s
        end

        flush_queue
        add_entry_to_trace_log(entry)

      end

      def trace_attribute_change(collection, key, new_value)
        # A setting was made with =

        if Chef::Config.trace_attributes == 'none' then return end
          
        # Determine the attrpath location of the change
        path, component = find_path_to_entry_ascent(collection)

        entry = AttributeTraceEntry.new(component, :set)
        entry.value = new_value

        # Path might be nil, meaning that we have a collection whose root is us, but is not yet present in one of our component VividMash.  This can happen when a hash at least two levels deep is being directly assigned and boosted to being a VividMash.  In that case, the only think we can do is go ahead and trace the change, but postpone adding it to the log for a bit.
        if path.nil?
          @trace_queue.push entry
          # Nothing else we can do at this point - later pases may be able to resolve the path.
          return
        else
          entry.path = path + (path == '/' ? '' : '/') + key.to_s
        end

        flush_queue
        add_entry_to_trace_log(entry)
      end

      

      def trace_attribute_clear(component)
        # the entire component-level Mash is about to be nuked

        if Chef::Config.trace_attributes == 'none' then return end
        
        entry = AttributeTraceEntry.new(component, :clear)
        entry.path = '/'

        flush_queue
        add_entry_to_trace_log(entry)
      end

      private

      def trace_this_path?(attrpath)
        return true if Chef::Config.trace_attributes == 'all'
        return Chef::Config.trace_attributes == attrpath
      end


      def add_entry_to_trace_log(entry)
        return unless trace_this_path?(entry.path)

        # Log a set event for each
        @trace_log[entry.path] ||= []
        @trace_log[entry.path].push entry

        child_action = entry.action == :clear ? :clear : :parent_clobber

        # Log a parent-clobber for all extant children of this key
        @trace_log.keys.find_all { |p| p.start_with?(entry.path) && p != entry.path }.each do |child_path|
          child_entry = AttributeTraceEntry.new(entry.component, child_action, entry.source_location)
          child_entry.path = child_path
          @trace_log[child_path].push child_entry 
        end
      end

      def flush_queue
        # OK, try to flush the queue 
        @trace_queue.reject! do |ent|
          # We know we can't find it by ascent :(
          path, component = find_path_to_entry_descent(ent.value)
          if path
            # Hooray it resolved
            ent.path = path
            add_entry_to_trace_log(ent)
            true
          else
            # No soup for you
            false
          end
        end
      end

    end
  end
end
