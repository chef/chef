class Chef
  class Node
    class AttributeTrait
      module ConvertValue

        def initialize(wrapped_object: nil)
          super(wrapped_object: convert_value(wrapped_object))
        end

        # This avoids the dup of value in #[]=
        def regular_writer(key, value)
          super(convert_key(key), value)
        end

        def []=(key, value)
          super(convert_key(key), convert_value(value))
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

        def update(other_hash)
          other_has.each { |k, v| self[key] = value }
          self
        end

        def fetch(key, *args, &block)
          super(convert_key(key), *args, &block)
        end

        def values_at(*indicies)
          indicies.collect { |key| self[convert_key(key)] }
        end

        def merge(hash)
          self.dup.update(hash)
        end

        def except(*keys)
          super(*keys.map {|k| convert_key(k)})
        end

        def self.from_hash(hash)
          new(wrapped_object: hash)
        end

        protected

        def convert_key(key)
          key
        end

        def convert_value(value)
          value
        end
      end
    end
  end
end
