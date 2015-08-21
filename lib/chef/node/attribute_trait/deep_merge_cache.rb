require 'chef/node/attribute_trait/path_tracking'

class Chef
  class Node
    class AttributeTrait
      module DeepMergeCache
        include PathTracking

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
          cache = __deep_merge_cache.regular_reader(*__path)

          cache_val = cache && cache[key] && cache[key][:__deep_merge_cache]
          return cache_val if cache_val

          if is_a?(Chef::Node::Attribute)
            val = super
            cache[key] = Chef::Node::Mash.new(wrapped_object: {}) unless cache.include?(key)
            cache[key].regular_writer(:__deep_merge_cache, val)
            return val
          else
            super
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

        def new_decorator(**args)
          args[:deep_merge_cache] = __deep_merge_cache
          super(**args)
        end
      end
    end
  end
end
