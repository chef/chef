class Chef
  class Node
    class AttributeTrait
      module Autovivify
        def initialize(wrapped_object: nil, **args)
          super
          @wrapped_object = {} if @wrapped_object.nil?
        end

        def [](key)
          if is_a?(Hash) && !key?(key)
            new_decorator(wrapped_object: regular_writer(key, {}))
          else
            super
          end
        end
      end
    end
  end
end
