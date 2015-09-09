
require 'chef/exceptions'

class Chef
  class Node
    class AttributeTrait
      module Immutable
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
          value = super
          if value.is_a?(Hash) || value.is_a?(Array)
            value
          else
            safe_dup(value).freeze
          end
        end

        def dup
          if is_a?(Array)
            to_a
          elsif is_a?(Hash)
            to_h
          else
            safe_dup
          end
        end
      end
    end
  end
end
