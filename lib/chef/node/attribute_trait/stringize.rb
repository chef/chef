class Chef
  class Node
    class AttributeTrait
      module Stringize

        def []=(key, value)
          super(convert_key(key), value)
        end

        def [](key)
          super(convert_key(key))
        end

        def key?(key)
          super(convert_key(key))
        end

        alias_method :include?, :key?
        alias_method :has_key?, :key?
        alias_method :member?, :key?

        def delete(key)
          super(convert_key(key))
        end

        protected

        def convert_key(key)
          key.kind_of?(Symbol) ? key.to_s : key
        end
      end
    end
  end
end
