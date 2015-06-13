class Chef
  class Node
    class AttributeTrait
      module SetUnlessize
        def []=(key, value)
          key?(key) ? self[key] : wrapped_object[key] = value
        end
      end
    end
  end
end
