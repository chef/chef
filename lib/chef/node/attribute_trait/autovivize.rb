class Chef
  class Node
    class AttributeTrait
      module Autovivize
        def initialize(wrapped_object: {})
          super(wrapped_object: wrapped_object)
        end

        def [](key)
          if self.is_a?(Hash) && !key?(key)
            new_decorator(regular_writer(key, {}))
          else
            super
          end
        end
      end
    end
  end
end
