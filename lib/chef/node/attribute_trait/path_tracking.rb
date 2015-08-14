class Chef
  class Node
    class AttributeTrait
      module PathTracking
        attr_accessor :__path

        def initialize(path: nil, **args)
          super(**args)
          @__path = path
        end

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

        def new_decorator(**args)
          args[:path] = __path
          super(**args)
        end
      end
    end
  end
end
