
require 'chef/exceptions'

class Chef
  class Node
    class AttributeTrait
      module Immutablize

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
            raise Chef::Exceptions::ImmutableAttributeModification
          end
        end

        def [](key)
          # FIXME: this get overridden by Cell and never gets called
          if value.is_a?(Hash) || value.is_a?(Array)
            value
          else
            value.dup.freeze
          end
        end

        def to_a
          Marshal.load(Marshal.dump(super))
        end

        def to_hash
          Marshal.load(Marshal.dump(super))
        end
      end
    end
  end
end
