class Chef
  class Node
    class AttributeTrait
      module Autovivize

        def self.included(base)
          base.mixins << :autovivize
        end

        def initialize(wrapped_object: {})
          super(wrapped_object: wrapped_object)
        end

        def [](key)
          if self.is_a?(Hash) && !key?(key)
            new_decorator(wrapped_object: regular_writer(key, {}))
          else
            super
          end
        end
      end
    end
  end
end
