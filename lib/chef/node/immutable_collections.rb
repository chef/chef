#--
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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

require "chef/node/common_api"
require "chef/node/mixin/state_tracking"
require "chef/node/mixin/immutablize_array"
require "chef/node/mixin/immutablize_hash"

class Chef
  class Node
    module Immutablize
      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      def convert_value(value, path = nil)
        case value
        when Hash
          ImmutableMash.new({}, __root__, __node__, __precedence__, path)
        when Array
          ImmutableArray.new([], __root__, __node__, __precedence__, path)
        else
          safe_dup(value).freeze
        end
      end
    end

    # == ImmutableArray
    # ImmutableArray is used to implement Array collections when reading node
    # attributes.
    #
    # ImmutableArray acts like an ordinary Array, except:
    # * Methods that mutate the array are overridden to raise an error, making
    #   the collection more or less immutable.
    # * Since this class stores values computed from a parent
    #   Chef::Node::Attribute's values, it overrides all reader methods to
    #   detect staleness and raise an error if accessed when stale.
    class ImmutableArray < Array
      alias_method :internal_clear, :clear
      alias_method :internal_replace, :replace
      alias_method :internal_push, :<<
      alias_method :internal_to_a, :to_a
      alias_method :internal_each, :each
      private :internal_push, :internal_replace, :internal_clear, :internal_each
      protected :internal_to_a

      include Immutablize

      methods = Array.instance_methods - Object.instance_methods +
        [ :!, :!=, :<=>, :==, :===, :eql?, :to_s, :hash, :key, :has_key?, :inspect, :pretty_print, :pretty_print_inspect, :pretty_print_cycle, :pretty_print_instance_variables ]

      methods.each do |method|
        define_method method do |*args, &block|
          ensure_generated_cache!
          super(*args, &block)
        end
      end

      def each
        ensure_generated_cache!
        # aggressively pre generate the cache, works around ruby being too smart and fiddling with internals
        internal_each { |i| i.ensure_generated_cache! if i.respond_to?(:ensure_generated_cache!) }
        super
      end

      # because sometimes ruby gives us back Arrays or ImmutableArrays out of objects from things like #uniq or array slices
      def return_normal_array(array)
        if array.respond_to?(:internal_to_a, true)
          array.internal_to_a
        else
          array.to_a
        end
      end

      def uniq
        ensure_generated_cache!
        return_normal_array(super)
      end

      def initialize(array_data = [])
        # Immutable collections no longer have initialized state
      end

      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      def dup
        Array.new(map { |e| safe_dup(e) })
      end

      def to_a
        Array.new(map do |v|
          case v
          when ImmutableArray
            v.to_a
          when ImmutableMash
            v.to_h
          else
            safe_dup(v)
          end
        end)
      end

      alias_method :to_array, :to_a

      def [](*args)
        ensure_generated_cache!
        args.length > 1 ? return_normal_array(super) : super # correctly handle array slices
      end

      def reset
        @generated_cache = false
        @short_circuit_attr_level = nil
        internal_clear # redundant?
      end

      # @api private
      def ensure_generated_cache!
        generate_cache unless @generated_cache
        @generated_cache = true
      end

      # This can be set to e.g. [ :@default ] by the parent container to cause this container
      # to only use the default level and to bypass deep merging (the common case is either
      # default-level or automatic-level and we aren't doing any deep merging).  Right now it
      # "optimized" for the case where we're no longer merging anything and only tracking a
      # single level, and setting this to anything other than a size=1 array would behave
      # in a broken fashion.  That could be fixed, but the perf boost would likely not be
      # that large in the typical case.
      #
      # @api private
      attr_accessor :short_circuit_attr_levels

      private

      # deep merging of array attribute within normal and override where they are merged together
      def combined_components(components)
        combined_values = nil
        components.each do |component|
          values = __node__.attributes.instance_variable_get(component).read(*__path__)
          next unless values.is_a?(Array)
          @tracked_components << component
          combined_values ||= []
          combined_values += values
        end
        combined_values
      end

      def get_array(component)
        array = __node__.attributes.instance_variable_get(component).read(*__path__)
        if array.is_a?(Array)
          @tracked_components << component
          array
        end # else nil
      end

      def generate_cache
        internal_clear
        components = []
        @tracked_components = []
        if short_circuit_attr_levels
          components << get_array(short_circuit_attr_levels.first)
        else
          components << combined_components(Attribute::DEFAULT_COMPONENTS)
          components << get_array(:@normal)
          components << combined_components(Attribute::OVERRIDE_COMPONENTS)
          components << get_array(:@automatic)
        end
        highest = components.compact.last
        if highest.is_a?(Array)
          internal_replace( highest.each_with_index.map { |x, i| convert_value(x, __path__ + [ i ] ) } )
        end
        if @tracked_components.size == 1
          # tracked_components is accurate enough to tell us if we're not really merging
          internal_each do |key, value|
            value.short_circuit_attr_levels = @tracked_components if value.respond_to?(:short_circuit_attr_levels)
          end
        end
      end

      # needed for __path__
      def convert_key(key)
        key
      end

      prepend Chef::Node::Mixin::StateTracking
      prepend Chef::Node::Mixin::ImmutablizeArray
    end

    # == ImmutableMash
    # ImmutableMash implements Hash/Dict behavior for reading values from node
    # attributes.
    #
    # ImmutableMash acts like a Mash (Hash that is indifferent to String or
    # Symbol keys), with some important exceptions:
    # * Methods that mutate state are overridden to raise an error instead.
    # * Methods that read from the collection are overriden so that they check
    #   if the Chef::Node::Attribute has been modified since an instance of
    #   this class was generated. An error is raised if the object detects that
    #   it is stale.
    # * Values can be accessed in attr_reader-like fashion via method_missing.
    class ImmutableMash < Mash
      alias_method :internal_clear, :clear
      alias_method :internal_key?, :key? # FIXME: could bypass convert_key in Mash for perf
      alias_method :internal_each, :each

      include Immutablize
      include CommonAPI

      methods = Hash.instance_methods - Object.instance_methods +
        [ :!, :!=, :<=>, :==, :===, :eql?, :to_s, :hash, :key, :has_key?, :inspect, :pretty_print, :pretty_print_inspect, :pretty_print_cycle, :pretty_print_instance_variables ]

      methods.each do |method|
        define_method method do |*args, &block|
          ensure_generated_cache!
          super(*args, &block)
        end
      end

      # this is for deep_merge usage, chef users must never touch this API
      # @api private
      def internal_set(key, value)
        regular_writer(key, convert_value(value, __path__ + [ key ]))
      end

      def initialize(mash_data = {})
        # Immutable collections no longer have initialized state
      end

      alias :attribute? :has_key?

      # NOTE: #default and #default= are likely to be pretty confusing. For a
      # regular ruby Hash, they control what value is returned for, e.g.,
      #   hash[:no_such_key] #=> hash.default
      # Of course, 'default' has a specific meaning in Chef-land

      def dup
        h = Mash.new
        each_pair do |k, v|
          h[k] = safe_dup(v)
        end
        h
      end

      def to_h
        h = Hash.new
        each_pair do |k, v|
          h[k] =
            case v
            when ImmutableMash
              v.to_h
            when ImmutableArray
              v.to_a
            else
              safe_dup(v)
            end
        end
        h
      end

      alias_method :to_hash, :to_h

      def [](key)
        ensure_generated_cache!
        super
      end

      alias_method :to_hash, :to_h

      def reset
        @generated_cache = false
        @short_circuit_attr_level = nil
        internal_clear # redundant?
      end

      # @api private
      def ensure_generated_cache!
        generate_cache unless @generated_cache
        @generated_cache = true
      end

      # @api private
      attr_accessor :short_circuit_attr_levels

      private

      def generate_cache
        internal_clear
        components = short_circuit_attr_levels ? short_circuit_attr_levels : Attribute::COMPONENTS.reverse
        # tracked_components is not entirely accurate due to the short-circuit
        tracked_components = []
        components.each do |component|
          subhash = __node__.attributes.instance_variable_get(component).read(*__path__)
          unless subhash.nil? # FIXME: nil is used for not present
            tracked_components << component
            if subhash.kind_of?(Hash)
              subhash.keys.each do |key|
                next if internal_key?(key)
                internal_set(key, subhash[key])
              end
            else
              break
            end
          end
        end
        if tracked_components.size == 1
          # tracked_components is accurate enough to tell us if we're not really merging
          internal_each do |key, value|
            value.short_circuit_attr_levels = tracked_components if value.respond_to?(:short_circuit_attr_levels)
          end
        end
      end

      prepend Chef::Node::Mixin::StateTracking
      prepend Chef::Node::Mixin::ImmutablizeHash
    end
  end
end
