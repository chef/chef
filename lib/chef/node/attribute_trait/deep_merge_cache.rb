require 'chef/node/attribute_trait/path_tracking'

class Chef
  class Node
    class AttributeTrait
      module DeepMergeCache
        include PathTracking

        MUTATOR_METHODS = [
          :<<,
          :[]=,
          :clear,
          :collect!,
          :compact!,
          :default=,
          :default_proc=,
          :delete,
          :delete_at,
          :delete_if,
          :fill,
          :flatten!,
          :insert,
          :keep_if,
          :map!,
          :merge!,
          :pop,
          :push,
          :update,
          :reject!,
          :reverse!,
          :replace,
          :select!,
          :shift,
          :slice!,
          :sort!,
          :sort_by!,
          :uniq!,
          :unshift
        ]

        MUTATOR_METHODS.each do |method|
          define_method method do |*args|
            if is_a?(Chef::Node::VividMash)
              # FIXME: should probably add some kind of safe_regular_reader that doesn't rescue Exceptions
              cache = __deep_merge_cache.regular_reader(*__path) rescue nil
              if cache && cache[:__deep_merge_cache]
                cache.delete(:__deep_merge_cache)
              end
            end
            super(*args)
          end
        end

        attr_accessor :__deep_merge_cache

        def initialize(deep_merge_cache: nil, **args)
          super(**args)
          @__deep_merge_cache = deep_merge_cache
        end

        def __deep_merge_cache
          @__deep_merge_cache ||=
            begin
              require 'chef/node/mash'
              Chef::Node::Mash.new(wrapped_object: {})
            end
        end

        def [](key)
          if is_a?(Chef::Node::Attribute)
            cache_val = __deep_merge_cache.regular_reader(*__path, key, :__deep_merge_cache) rescue nil
            if cache_val
              return cache_val.respond_to?(:wrapped_object) ? cache_val.wrapped_object : cache_val
            end
            cache = __deep_merge_cache.regular_reader(*__path) rescue nil

            val = super
            if cache
              cache.regular_writer(key, {}) unless cache.include?(key)
              cache[key].regular_writer(:__deep_merge_cache, val)
            end
            return val
          else
            super
          end
        end

        def []=(key, value)
          if is_a?(Chef::Node::VividMash)
            # FIXME: should probably add some kind of safe_regular_reader that doesn't rescue Exceptions
            cache = __deep_merge_cache.regular_reader(*__path) rescue nil
            if cache && cache[key] && cache[key].key?(:__deep_merge_cache)
              cache[key].delete(:__deep_merge_cache)
            end
          end
          super
        end

        def new_decorator(**args)
          args[:deep_merge_cache] = __deep_merge_cache
          super(**args)
        end
      end
    end
  end
end
