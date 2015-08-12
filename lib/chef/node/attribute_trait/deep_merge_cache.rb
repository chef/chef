class Chef
  class Node
    class AttributeTrait
      module DeepMergeCache
        attr_accessor :__deep_merge_cache

        def initialize(deep_merge_cache: Chef::Node::Mash.new(wrapped_object: {}), **args)
          super(**args)
          @__deep_merge_cache = deep_merge_cache
        end

        def [](key)
          if __deep_merge_cache.key?(key) && __deep_merge_cache[key][:__deep_merge_cache]
            return __deep_merge_cache[key].regular_reader(:__deep_merge_cache)
          end

          if is_a?(Hash) && self.class.deep_merge_cache_population
            val = super
            __deep_merge_cache[key] = Chef::Node::Mash.new(wrapped_object: {}) unless __deep_merge_cache.key?(key)
            __deep_merge_cache[key].regular_writer(:__deep_merge_cache, val)
            val.__deep_merge_cache = __deep_merge_cache[key] if val.is_a?(DeepMergeCache)
            return val
          else
            val = super
            val.__deep_merge_cache = __deep_merge_cache[key] if val.is_a?(DeepMergeCache)
            return val
          end
        end

        def []=(key, value)
          super
#          if is_a?(Hash) && self.class.deep_merge_cache_invalidation
#            unless key == :__deep_merge_cache
#              self[:__deep_merge_cache] = nil
#            end
#          end
        end
      end
    end
  end
end

# FIXME: dep inject the mash
#require 'chef/node/mash'
