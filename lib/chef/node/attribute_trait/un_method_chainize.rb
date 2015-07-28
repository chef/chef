class Chef
  class Node
    class AttributeTrait
      module UnMethodChainize
        attr_accessor :wrapped_object
        attr_accessor :__path
        attr_accessor :__method_to_call

        def initialize(wrapped_object: {}, method_to_call: nil)
          @wrapped_object = wrapped_object
          @__path = []
          @__method_to_call = method_to_call
        end

        def [](key)
          __path.push(key)
          self
        end

        def []=(key, value)
          __path.push(key)
          wrapped_object.public_send(__method_to_call, *__path, value)
        end

        def self.included(base)
          base.extend(UnMethodChainizeClassMethods)
        end

        module UnMethodChainizeClassMethods
          def new_decorator(wrapped_object: nil, method_to_call: nil)
            dec = allocate
            dec.wrapped_object = wrapped_object
            dec.__method_to_call = method_to_call
            dec.__path = []
            dec
          end
        end
      end
    end
  end
end
