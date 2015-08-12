class Chef
  class Node
    class AttributeTrait
      module Autovivize

        def initialize(wrapped_object: {}, **args)
          super(wrapped_object: wrapped_object, **args)
        end

        def [](key)
          if is_a?(Hash) && !key?(key)
            self.class.new(wrapped_object: regular_writer(key, {}), convert_value: false)
          else
            super
          end
        end
      end
    end
  end
end
