class Chef
  class Node
    class AttributeTrait
      module Autovivize
        def [](key)
          if !key?(key)
            self[key] = self.class.new(wrapped_object: {})
          else
            super
          end
        end
      end
    end
  end
end
