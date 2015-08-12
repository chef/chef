class Chef
  class Node
    class AttributeTrait
      module PathTracking
        attr_accessor :__path

        def initialize(**args)
          @__path = []
          super
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
