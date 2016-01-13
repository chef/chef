
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
          :unshift,
        ]

        MUTATOR_METHODS.each do |method|
          define_method method do |*args|
            raise Chef::Exceptions::ImmutableAttributeModification
          end
        end

        def to_a
          if is_a?(Array)
            dup
          else
            a = []
            each do |value|
              if value.is_a?(Hash)
                a.push(value.to_h)
              elsif value.is_a?(Array)
                a.push(value.to_a)
              else
                a.push(safe_dup(value))
              end
            end
            a
          end
        end

        def to_h
          if is_a?(Hash)
            dup
          else
            h = {}
            each do |elem|
              unless elem.is_a?(Array)
                raise TypeError "wrong element type, expected Array"
              end
              h[safe_dup(elem[0])] = safe_dup(elem[1])
            end
            h
          end
        end

        def to_ary
          if is_a?(Array)
            dup
          else
            # should raise NoMethodError
            wrapped_object.to_ary
          end
        end

        def to_hash
          if is_a?(Hash)
            dup
          else
            # should raise NoMethodError
            wrapped_object.to_hash
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

      end
    end
  end
end
