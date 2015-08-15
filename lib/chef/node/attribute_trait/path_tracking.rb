class Chef
  class Node
    class AttributeTrait
      module PathTracking
        attr_accessor :__path
        attr_accessor :__next_path
        attr_accessor :__precedence
        attr_accessor :__node

        def initialize(path: nil, precedence: nil, node: nil, **args)
          super(**args)
          @__path = path
          @__precedence = precedence
          @__node = node
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
          __attribute_changed(__precedence, __next_path, value)
        end

        private

        def __attribute_changed(*args)
          __node.run_context.events.attribute_changed(*args) if __have_valid_events?
        end

        def __have_valid_events?
          __node && __node.respond_to?(:run_context) && __node.run_context  && __node.run_context.events
        end

        def new_decorator(**args)
          args[:path] = __next_path
          args[:precedence] = __precedence
          args[:node] = __node
          super(**args)
        end
      end
    end
  end
end
