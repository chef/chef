require "chef/node/attribute_trait/path_tracking"
require "chef/node/attribute_trait/root_tracking"

class Chef
  class Node
    class AttributeTrait
      module CopyOnWrite
        include PathTracking
        include RootTracking

        attr_accessor :__duped

        def initialize(duped: false, **args)
          super(**args)
          @__duped = duped
          if __root == self
            # this is a hack so that we can mutate the top level object without taking the
            # expense of duplicating it all.  at some lazy dup'ing at any level of the tree would
            # be awesome if its possible.
            @wrapped_object = wrapped_object.dup  # this should be a Hash so its intended to be non-deep
          end
        end

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
          :unshift,
        ]

        def wrapped_object
          __path.inject(__root.instance_variable_get(:@wrapped_object)) { |memo, key| memo[key] }
        end

        MUTATOR_METHODS.each do |method|
          define_method method do |*args, &block|
            __root.__maybe_dup
            super(*args, &block)
          end
        end

        def []=(key, value)
          if __root == self
            # hacky way to connect up to the hack in the initializer, we don't have to dup
            # because we already did a shallow dup.
            @wrapped_object[key] = value
          else
            # we're in some subtree so we have to dup the whole thing if we haven't already
            __root.__maybe_dup
            super(key, value)
          end
        end

        protected

        def __maybe_dup
          unless __duped
            @wrapped_object = dup
            @__duped = true
          end
        end
      end
    end
  end
end
