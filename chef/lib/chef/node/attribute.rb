#--
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

require 'chef/node/immutable_collections'
require 'chef/node/attribute_collections'
require 'chef/mixin/deep_merge'
require 'chef/log'

class Chef

    class ImmutableAttributeModification < NoMethodError
    end

    class StaleAttributeRead < StandardError
    end



  class Node

    # == Attribute
    # Attribute implements a nested key-value (Hash) and flat collection
    # (Array) data structure supporting multiple levels of precedence, such
    # that a given key may have multiple values internally, but will only
    # return the highest precedence value when reading.
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
        @set_unless_present = false

        @normal = VividMash.new(self, normal)
        @default = VividMash.new(self, default)
        @override = VividMash.new(self, override)
        @automatic = VividMash.new(self, automatic)

        @merged_attributes = nil
      end

      def set_unless_value_present=(setting)
        @set_unless_present = setting
      end

      def reset_cache
        @serial_number += 1
        @merged_attributes = nil
      end

      def reset
        @serial_number += 1
        @merged_attributes = nil
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
        @set_unless_present
      end

      def stale_subtree?(serial_number)
        serial_number != @serial_number
      end

    end

  end
end
