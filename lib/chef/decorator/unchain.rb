class Chef
  class Decorator < SimpleDelegator
    #
    # This decorator unchains method call chains and turns them into method calls
    # with variable args.  So this:
    #
    #   node.set_unless["foo"]["bar"] = "baz"
    #
    # Can become:
    #
    #   node.set_unless("foo", "bar", "baz")
    #
    # While this is a decorator it is not a Decorator and does not inherit because
    # it deliberately does not need or want the method_missing magic.  It is not legal
    # to call anything on the intermediate values and only supports method chaining with
    # #[] until the chain comes to an end with #[]=, so does not behave like a hash or
    # array...  e.g.
    #
    #   node.default['foo'].keys is legal
    #   node.set_unless['foo'].keys is not legal now or ever
    #
    class Unchain
      attr_accessor :__path__
      attr_accessor :__method__

      def initialize(obj, method)
        @__path__        = []
        @__method__      = method
        @delegate_sd_obj = obj
      end

      def [](key)
        __path__.push(key)
        self
      end

      def []=(key, value)
        __path__.push(key)
        @delegate_sd_obj.public_send(__method__, *__path__, value)
      end
    end
  end
end
