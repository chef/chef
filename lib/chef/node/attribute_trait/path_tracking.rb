class Chef
  class Node
    class AttributeTrait
      module PathTracking
        attr_accessor :__path

        def __path
          @__path ||= []
        end

        def [](key)
          __path.push(key)
          super
        end

        def []=(key, value)
          __path.push(key)
          super
        end
      end
    end
  end
end
