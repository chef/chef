require 'chef/property'

class Chef
  class Property
    class CapabilityHash < Chef::Property
      # - After supports(:a, :b); supports(:c), the result is supports == { a: true, b: true, c: true }
      # - After supports({ x: 1, y: 2 }), supports == { x: 1, y: 2 }
      # - After supports({}) or supports, supports remains unchanged. There is no way to nil out supports.
      # The additivity and the fact that supports({}) does a get both seem wrong, but we preserve them for now. Chef 13 likely.
      def call(resource, value)
        if value.is_a?(Array)
          result = get(resource)
          value.each { |arg| result[arg] = true }
          result
        elsif value == NOT_PASSED || !value.any?
          get(resource)
        else
          set(resource, value)
        end
      end
    end
  end
end
