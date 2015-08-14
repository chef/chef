class Chef
  class Node
    class AttributeTrait
      module PathTracking
        attr_accessor :__path
        attr_accessor :__next_path

        def initialize(path: nil, **args)
          super(**args)
          @__path = path
        end

        def __path
          @__path ||= []
        end

        def [](key)
          @__next_path = __path + [ convert_key(key) ]
          super
        end

        def []=(key, value)
          @__next_path = __path + [ convert_key(key) ]
          super
        end

        private

        def new_decorator(**args)
          args[:path] = __next_path
          super(**args)
        end
      end
    end
  end
end
