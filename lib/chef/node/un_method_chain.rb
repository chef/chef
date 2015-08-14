class Chef
  class Node
    class UnMethodChain
      attr_accessor :__path
      attr_accessor :__method_to_call
      attr_accessor :__wrapped_object

      def initialize(wrapped_object: nil, method_to_call: nil)
        @__path = []
        @__method_to_call = method_to_call
        @__wrapped_object = wrapped_object
      end

      def [](key)
        __path.push(key)
        self
      end

      def []=(key, value)
        __path.push(key)
        __wrapped_object.public_send(__method_to_call, *__path, value)
      end
    end
  end
end
