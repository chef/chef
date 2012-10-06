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

    module Immutablize
      def immutablize(value)
        case value
        when Hash
          ImmutableMash.new(value)
        when Array
          ImmutableArray.new(value)
        else
          value
        end
      end
    end

    class ImmutableArray < Array
      include Immutablize

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
        :shift!,
        :slice!,
        :sort!,
        :sort_by!,
        :uniq!,
        :unshift
      ]

      def initialize(array_data)
        array_data.each do |value|
          internal_push(immutablize(value))
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

      def dup
        Array.new(self)
      end
    end

    class ImmutableMash < Mash

      include Immutablize

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
        :shift!
      ]

      def initialize(mash_data)
        mash_data.each do |key, value|
          internal_set(key, immutablize(value))
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
      attr_accessor :auto_vivify_on_read
      attr_accessor :set_unless_present
      attr_accessor :set_type

      def auto_vivify_on_read?
        !!@auto_vivify_on_read
      end

      def set_unless?
        !!@set_unless_present
      end

    end

    class VividMash < Mash
      attr_reader :properties

      def initialize(properties, data={})
        @properties = properties
        super(data)
      end

      def [](key)
        value = super
        if value.nil? && auto_vivify_on_read?
          value = self.class.new(properties)
          self[key] = value
        else
          value
        end
      end

      def []=(key, value)
        if set_unless? && key?(key)
          self[key]
        else
          super
        end
      end

      alias :attribute? :has_key?

      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol) or setting_a_value? && auto_vivify_on_read?
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

      def set_unless?
        @properties.set_unless?
      end

      def auto_vivify_on_read?
        @properties.auto_vivify_on_read?
      end

      def setting_a_value?
        !properties.set_type.nil?
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
        @properties = AttrProperties.new
        @normal = VividMash.new(properties, normal)
        @default = VividMash.new(properties, default)
        @override = VividMash.new(properties, override)
        @automatic = VividMash.new(properties, automatic)

        @merged_attributes = nil
      end

      def set_type=(set_type)
        @properties.set_type = set_type
      end

      def set_unless_value_present=(setting)
        @properties.set_unless_present = setting
      end

      def reset
        @merged_attributes = nil
        @properties.set_type = nil
        @properties.auto_vivify_on_read = nil
      end

      def reset_for_read
        @properties.set_type = nil
        @properties.auto_vivify_on_read = nil
      end

      def auto_vivify_on_read
        @properties.auto_vivify_on_read?
      end

      def auto_vivify_on_read=(setting)
        @properties.auto_vivify_on_read = setting
      end

      def default
        reset
        properties.set_type = :default
        @default
      end

      def default=(new_data)
        reset
        @default = new_data
      end

      def normal
        reset
        properties.set_type = :normal
        @normal
      end

      def normal=(new_data)
        reset
        @normal = new_data
      end

      def override
        reset
        properties.set_type = :override
        @override
      end

      def override=(new_data)
        reset
        @override = new_data
      end

      def automatic
        reset
        properties.set_type = :automatic
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
          immutablize(resolved_attrs)
        end
      end

      def [](key)
        return merged_attributes[key] unless setting_a_value?
        value = set_type_hash[key]
        if value.nil? && auto_vivify_on_read?
          value = VividMash.new({})
          set_type_hash[key] = value
        end

        value
      end

      def []=(key, value)
        set_type_hash[key] = value
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


      def set_type_hash
        if ivar = COMPONENT_ACCESSORS[@properties.set_type]
          instance_variable_get(ivar)
        else
          raise InvalidAttributeSetterContext, "Cannot set an attribute without first specifying the precedence. " +
            %Q(To set an attribute, use code like `node.default["key"] = "value"')
        end
      end

      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol) or setting_a_value? && auto_vivify_on_read?
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        elsif symbol.to_s =~ /=$/
          if setting_a_value?
            key_to_set = symbol.to_s[/^(.+)=$/, 1]
            self[key_to_set] = (args.length == 1 ? args[0] : args)
          else
            raise InvalidAttributeSetterContext, "Cannot set an attribute without first specifying the precedence. " +
            %Q(To set an attribute, use code like `node.default["key"] = "value"')
          end
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      def inspect
        "#<#{self.class} " << (COMPONENTS + [:@merged_attributes, :@properties]).map{|iv|
          "#{iv}=#{instance_variable_get(iv).inspect}"
        }.join(', ') << ">"
      end

      def auto_vivify_on_read?
        @properties.auto_vivify_on_read?
      end

      def setting_a_value?
        !properties.set_type.nil?
      end

    end

  end
end
