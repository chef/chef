class Chef
  class Node
    class AttributeTrait
      module SetUnless
        def []=(key, value)
          key?(key) ? self[key] : wrapped_object[key] = value
        end
      end
    end
  end
end
