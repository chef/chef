class Chef
  class Node
    class AttributeTrait
      module ConvertValue

        def initialize(wrapped_object: nil)
          super(wrapped_object: convert_value(wrapped_object))
        end

        def regular_writer(*path, value)
          path = path.map { |key| convert_key(key) }
          super(*path, value)
        end

        def regular_reader(*path)
          path = path.map { |key| convert_key(key) }
          super(*path)
        end

        def []=(key, value)
          super(convert_key(key), convert_value(value))
        end

        def [](key)
          super(convert_key(key))
        end

        def key?(key)
          wrapped_object.key?(convert_key(key))
        end

        alias_method :include?, :key?
        alias_method :has_key?, :key?
        alias_method :member?, :key?

        def delete(key)
          super(convert_key(key))
        end

        def update(other_hash)
          other_hash.each { |k, v| self[convert_key(k)] = convert_value(v) }
          self
        end

        alias_method :merge!, :update

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
