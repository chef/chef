require 'chef/node_map'

class Chef
  class Platform
    class PriorityMap < Chef::NodeMap
      def priority(resource_name, priority_array, *filter)
        set_priority_array(resource_name.to_sym, priority_array, *filter)
      end
      
      # @api private
      def get_priority_array(node, key)
        get(node, key)
      end

      # @api private
      def set_priority_array(key, priority_array, *filter, &block)
        priority_array = Array(priority_array)
        set(key, priority_array, *filter, &block)
        priority_array
      end

      # @api private
      def list_handlers(node, key, **filters)
        list(node, key, **filters).flatten(1).uniq
      end

      #
      # Priority maps have one extra precedence: priority arrays override "provides,"
      # and "provides" lines with identical filters sort by class name (ascending).
      #
      def compare_matchers(key, new_matcher, matcher)
        # Priority arrays come before "provides"
        if new_matcher[:value].is_a?(Array) != matcher[:value].is_a?(Array)
          return new_matcher[:value].is_a?(Array) ? -1 : 1
        end

        cmp = super
        if cmp == 0
          # Sort by class name (ascending) as well, if all other properties
          # are exactly equal
          if new_matcher[:value].is_a?(Class) && !new_matcher[:override]
            cmp = compare_matcher_properties(new_matcher, matcher) { |m| m[:value].name }
            if cmp < 0
              Chef::Log.warn "You are overriding #{key} on #{new_matcher[:filters].inspect} with #{new_matcher[:value].inspect}: used to be #{matcher[:value].inspect}. Use override: true if this is what you intended."
            elsif cmp > 0
              Chef::Log.warn "You declared a new resource #{new_matcher[:value].inspect} for resource #{key}, but it comes alphabetically after #{matcher[:value].inspect} and has the same filters (#{new_matcher[:filters].inspect}), so it will not be used. Use override: true if you want to use it for #{key}."
            end
          end
        end
        cmp
      end
    end
  end
end
