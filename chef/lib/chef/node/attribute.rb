#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/mixin/deep_merge'
require 'chef/log'

class Chef

    class InvalidAttributeSetterContext < ArgumentError
    end

    class ImmutableAttributeModification < NoMethodError
    end

    class StaleAttributeRead < StandardError
    end

    module Immutablize
      def immutablize(root, value)
        case value
        when Hash
          ImmutableMash.new(root, value)
        when Array
          ImmutableArray.new(root, value)
        else
          value
        end
      end
    end

    class ImmutableArray < Array
      include Immutablize

      attr_reader :root

      alias :internal_push :<<
      private :internal_push

      DISALLOWED_MUTATOR_METHODS = [
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

      READER_METHODS =
      [
        :&,
        :*,
        :+,
        :-,
        :[],
        :all?,
        :any?,
        :assoc,
        :at,
        :chunk,
        :collect,
        :collect_concat,
        :combination,
        :compact,
        :concat,
        :count,
        :cycle,
        :detect,
        :drop,
        :drop_while,
        :each,
        :each_cons,
        :each_entry,
        :each_index,
        :each_slice,
        :each_with_index,
        :each_with_object,
        :empty?,
        :entries,
        :fetch,
        :find,
        :find_all,
        :find_index,
        :first,
        :flat_map,
        :flatten,
        :grep,
        :group_by,
        :include?,
        :index,
        :inject,
        :join,
        :last,
        :length,
        :map,
        :max,
        :max_by,
        :member?,
        :min,
        :min_by,
        :minmax,
        :minmax_by,
        :none?,
        :one?,
        :pack,
        :partition,
        :permutation,
        :product,
        :rassoc,
        :reduce,
        :reject,
        :repeated_combination,
        :repeated_permutation,
        :reverse,
        :reverse_each,
        :rindex,
        :rotate,
        :sample,
        :select,
        :shelljoin,
        :shuffle,
        :size,
        :slice,
        :slice_before,
        :sort,
        :sort_by,
        :take,
        :take_while,
        :to_a,
        :to_ary,
        :to_set,
        :transpose,
        :uniq,
        :values_at,
        :zip,
        :|
      ]

      def initialize(root, array_data)
        @root = root
        @serial_number = root.serial_number
        array_data.each do |value|
          internal_push(immutablize(root, value))
        end
      end

      # Redefine all of the methods that mutate a Hash to raise an error when called.
      # This is the magic that makes this object "Immutable"
      DISALLOWED_MUTATOR_METHODS.each do |mutator_method_name|
        # Ruby 1.8 blocks can't have block arguments, so we must use string eval:
        class_eval(<<-METHOD_DEFN)
          def #{mutator_method_name}(*args, &block)
            msg = "Node attributes are read-only when you do not specify which precedence level to set. " +
            %Q(To set an attribute use code like `node.default["key"] = "value"')
            raise ImmutableAttributeModification, msg
          end
        METHOD_DEFN
      end

      READER_METHODS.each do |reader|
        class_eval(<<-METHOD_DEFN)
          def #{reader}(*args, &block)
            if root.stale_subtree?(@serial_number)
              raise StaleAttributeRead, "Node attributes have been modified since this value was read. Get an updated value by reading from node, e.g., `node[:key]`"
            end
            super
          end
        METHOD_DEFN
      end

      def dup
        Array.new(self)
      end
    end

    class ImmutableMash < Mash

      include Immutablize

      attr_reader :root

      alias :internal_set :[]=
      private :internal_set

      DISALLOWED_MUTATOR_METHODS = [
        :[]=,
        :clear,
        :collect!,
        :default=,
        :default_proc=,
        :delete,
        :delete_if,
        :keep_if,
        :map!,
        :merge!,
        :update,
        :reject!,
        :replace,
        :select!,
        :shift
      ]

      READER_METHODS = [
        :[],
        :all?,
        :any?,
        :assoc,
        :chunk,
        :collect,
        :collect_concat,
        :count,
        :cycle,
        :detect,
        :drop,
        :drop_while,
        :each,
        :each_cons,
        :each_entry,
        :each_key,
        :each_pair,
        :each_slice,
        :each_value,
        :each_with_index,
        :each_with_object,
        :empty?,
        :entries,
        :except,
        :fetch,
        :find,
        :find_all,
        :find_index,
        :first,
        :flat_map,
        :flatten,
        :grep,
        :group_by,
        :has_key?,
        :has_value?,
        :include?,
        :index,
        :inject,
        :invert,
        :key,
        :key?,
        :keys,
        :length,
        :map,
        :max,
        :max_by,
        :member?,
        :merge,
        :min,
        :min_by,
        :minmax,
        :minmax_by,
        :none?,
        :one?,
        :partition,
        :rassoc,
        :reduce,
        :reject,
        :reverse_each,
        :select,
        :size,
        :slice_before,
        :sort,
        :sort_by,
        :store,
        :symbolize_keys,
        :take,
        :take_while,
        :to_a,
        :to_hash,
        :to_set,
        :value?,
        :values,
        :values_at,
        :zip
      ]

      def initialize(root, mash_data)
        @serial_number = root.serial_number
        @root = root
        mash_data.each do |key, value|
          internal_set(key, immutablize(root, value))
        end
      end

      alias :attribute? :has_key?

      # Redefine all of the methods that mutate a Hash to raise an error when called.
      # This is the magic that makes this object "Immutable"
      DISALLOWED_MUTATOR_METHODS.each do |mutator_method_name|
        # Ruby 1.8 blocks can't have block arguments, so we must use string eval:
        class_eval(<<-METHOD_DEFN)
        def #{mutator_method_name}(*args, &block)
          msg = "Node attributes are read-only when you do not specify which precedence level to set. " +
          %Q(To set an attribute use code like `node.default["key"] = "value"')
          raise ImmutableAttributeModification, msg
        end
        METHOD_DEFN
      end

      READER_METHODS.each do |reader_method|
        class_eval(<<-METHOD_DEFN)
          def #{reader_method}(*args, &block)
            if root.stale_subtree?(@serial_number)
              raise StaleAttributeRead, "Node attributes have been modified since this value was read. Get an updated value by reading from node, e.g., `node[:key]`"
            end
            super
          end
        METHOD_DEFN
      end

      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol)
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        # This will raise a ImmutableAttributeModification error:
        elsif symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      # Mash uses #convert_value to mashify values on input.
      # Since we're handling this ourselves, override it to be a no-op
      def convert_value(value)
        value
      end

      # NOTE: #default and #default= are likely to be pretty confusing. For a
      # regular ruby Hash, they control what value is returned for, e.g.,
      #   hash[:no_such_key] #=> hash.default
      # Of course, 'default' has a specific meaning in Chef-land

      def dup
        Mash.new(self)
      end
    end


  class Node
    class AttrProperties
      attr_accessor :set_unless_present

      def set_unless?
        !!@set_unless_present
      end

    end

    # == AttrArray
    # AttrArray is identical to Array, except that it keeps a reference to the
    # "root" (Chef::Node::Attribute) object, and will trigger a cache
    # invalidation on that object when mutated.
    class AttrArray < Array

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

      # For all of the methods that may mutate an Array, we override them to
      # also invalidate the cached merged_attributes on the root
      # Node::Attribute object.
      MUTATOR_METHODS.each do |mutator|
        class_eval(<<-METHOD_DEFN)
          def #{mutator}(*args, &block)
            root.reset_cache
            super
          end
        METHOD_DEFN
      end

      attr_reader :root

      def initialize(root, data)
        @root = root
        super(data)
      end

    end

    # == VividMash
    # VividMash is identical to a Mash, with a few exceptions:
    # * It has a reference to the root Chef::Node::Attribute to which it
    #   belongs, and will trigger cache invalidation on that object when
    #   mutated.
    # * It auto-vivifies, that is a reference to a missing element will result
    #   in the creation of a new VividMash for that key. (This only works when
    #   using the element reference method, `[]` -- other methods, such as
    #   #fetch, work as normal).
    # * It supports a set_unless flag (via the root Attribute object) which
    #   allows `||=` style behavior (`||=` does not work with
    #   auto-vivification). This is only implemented for #[]=; methods such as
    #   #store work as normal.
    # * attr_accessor style element set and get are supported via method_missing
    class VividMash < Mash
      attr_reader :root

      # Methods that mutate a VividMash. Each of them is overridden so that it
      # also invalidates the cached merged_attributes on the root Attribute
      # object.
      MUTATOR_METHODS = [
        :clear,
        :delete,
        :delete_if,
        :keep_if,
        :merge!,
        :update,
        :reject!,
        :replace,
        :select!,
        :shift
      ]

      # For all of the mutating methods on Mash, override them so that they
      # also invalidate the cached `merged_attributes` on the root Attribute
      # object.
      MUTATOR_METHODS.each do |mutator|
        class_eval(<<-METHOD_DEFN)
          def #{mutator}(*args, &block)
            root.reset_cache
            super
          end
        METHOD_DEFN
      end

      def initialize(root, data={})
        @root = root
        super(data)
      end

      def [](key)
        value = super
        if !key?(key)
          value = self.class.new(root)
          self[key] = value
        else
          value
        end
      end

      def []=(key, value)
        if set_unless? && key?(key)
          self[key]
        else
          root.reset_cache
          super
        end
      end

      alias :attribute? :has_key?

      def method_missing(symbol, *args)
        if args.empty?
          self[symbol]
        elsif symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'. To set an attribute, use `#{symbol}=value' instead."
        end
      end

      def set_unless?
        @root.set_unless?
      end

      def convert_key(key)
        super
      end

      # Mash uses #convert_value to mashify values on input.
      # We override it here to convert hash or array values to VividMash or
      # AttrArray for consistency and to ensure that the added parts of the
      # attribute tree will have the correct cache invalidation behavior.
      def convert_value(value)
        case value
        when VividMash
          value
        when Hash
          VividMash.new(root, value)
        when Array
          AttrArray.new(root, value)
        else
          value
        end
      end

    end

    class Attribute < Mash

      include Immutablize

      include Enumerable

      COMPONENTS = [:@default, :@normal, :@override, :@automatic].freeze
      COMPONENT_ACCESSORS = {:default   => :@default,
                             :normal    => :@normal,
                             :override  => :@override,
                             :automatic => :@automatic
                            }

      attr_accessor :properties
      attr_reader :serial_number

      [:all?,
       :any?,
       :assoc,
       :chunk,
       :collect,
       :collect_concat,
       :compare_by_identity,
       :compare_by_identity?,
       :count,
       :cycle,
       :detect,
       :drop,
       :drop_while,
       :each,
       :each_cons,
       :each_entry,
       :each_key,
       :each_pair,
       :each_slice,
       :each_value,
       :each_with_index,
       :each_with_object,
       :empty?,
       :entries,
       :except,
       :fetch,
       :find,
       :find_all,
       :find_index,
       :first,
       :flat_map,
       :flatten,
       :grep,
       :group_by,
       :has_value?,
       :include?,
       :index,
       :inject,
       :invert,
       :key,
       :keys,
       :length,
       :map,
       :max,
       :max_by,
       :merge,
       :min,
       :min_by,
       :minmax,
       :minmax_by,
       :none?,
       :one?,
       :partition,
       :rassoc,
       :reduce,
       :reject,
       :reverse_each,
       :select,
       :size,
       :slice_before,
       :sort,
       :sort_by,
       :store,
       :symbolize_keys,
       :take,
       :take_while,
       :to_a,
       :to_hash,
       :to_set,
       :value?,
       :values,
       :values_at,
       :zip].each do |delegated_method|
         class_eval(<<-METHOD_DEFN)
            def #{delegated_method}(*args, &block)
              merged_attributes.send(:#{delegated_method}, *args, &block)
            end
         METHOD_DEFN
       end

      def initialize(normal, default, override, automatic)
        @serial_number = 0

        @properties = AttrProperties.new
        @normal = VividMash.new(self, normal)
        @default = VividMash.new(self, default)
        @override = VividMash.new(self, override)
        @automatic = VividMash.new(self, automatic)

        @merged_attributes = nil
      end

      def set_unless_value_present=(setting)
        @properties.set_unless_present = setting
      end

      def reset_cache
        @serial_number += 1
        @merged_attributes = nil
      end

      def reset
        @serial_number += 1
        @merged_attributes = nil
      end

      def reset_for_read
      end

      def default
        @default
      end

      def default=(new_data)
        reset
        @default = new_data
      end

      def normal
        @normal
      end

      def normal=(new_data)
        reset
        @normal = new_data
      end

      def override
        @override
      end

      def override=(new_data)
        reset
        @override = new_data
      end

      def automatic
        @automatic
      end

      def automatic=(new_data)
        reset
        @automatic = new_data
      end

      def merged_attributes
        @merged_attributes ||= begin
          resolved_attrs = COMPONENTS.inject(Mash.new) do |merged, component_ivar|
            component_value = instance_variable_get(component_ivar)
            Chef::Mixin::DeepMerge.merge(merged, component_value)
          end
          immutablize(self, resolved_attrs)
        end
      end

      def [](key)
        merged_attributes[key]
      end

      def []=(key, value)
        merged_attributes[key] = value
      end

      def has_key?(key)
        COMPONENTS.any? do |component_ivar|
          instance_variable_get(component_ivar).has_key?(key)
        end
      end

      alias :attribute? :has_key?
      alias :member? :has_key?
      alias :include? :has_key?
      alias :key? :has_key?

      alias :each_attribute :each

      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol)
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        elsif symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      def inspect
        "#<#{self.class} " << (COMPONENTS + [:@merged_attributes, :@properties]).map{|iv|
          "#{iv}=#{instance_variable_get(iv).inspect}"
        }.join(', ') << ">"
      end

      def set_unless?
        properties.set_unless?
      end

      def stale_subtree?(serial_number)
        serial_number != @serial_number
      end

    end

  end
end
