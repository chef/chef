require 'chef/node/attribute_traits'

class Chef
  class Node
    class UnMethodChain
      include AttributeTrait::Base
      include AttributeTrait::PathTracking

      attr_accessor :wrapped_object
      attr_accessor :__method_to_call

      def initialize(wrapped_object: {}, method_to_call: nil)
        @wrapped_object = wrapped_object
        @__method_to_call = method_to_call
      end

      def [](key)
        super
        self
      end

      def []=(key, value)
        super
        wrapped_object.public_send(__method_to_call, *__path, value)
      end
    end
  end
end
