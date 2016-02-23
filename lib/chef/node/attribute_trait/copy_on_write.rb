class Chef
  class Node
    class AttributeTrait
      module CopyOnWrite
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

        MUTATOR_METHODS.each do |method|
          define_method method do |*args|
            wrapped_object = safe_dup(wrapped_object)
            super(*args)
          end
        end
      end
    end
  end
end
