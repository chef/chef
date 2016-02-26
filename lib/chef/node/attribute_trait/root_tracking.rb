class Chef
  class Node
    class AttributeTrait
      module RootTracking
        attr_accessor :__root

        def initialize(root: nil, **args)
          super(**args)
          @__root = root || self
        end

        private

        def new_decorator(**args)
          args[:root] = __root
          super(**args)
        end
      end
    end
  end
end
