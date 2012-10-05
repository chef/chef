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
  class Node

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

      # NOTE: #default and #default= are likely to be pretty confusing. For a
      # regular ruby Hash, they control what value is returned for, e.g.,
      #   hash[:no_such_key] #=> hash.default
      # Of course, 'default' has a specific meaning in Chef-land

      def dup
        Mash.new(self)
      end
    end

    class AttrProperties
      attr_accessor :auto_vivify_on_read
      attr_accessor :set_unless_present

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
        end
        value
      end

      alias :attribute? :has_key?

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

      def auto_vivify_on_read?
        @properties.auto_vivify_on_read?
      end

    end

    class Attribute2 < Mash

      include Immutablize

      include Enumerable

      COMPONENTS = [:@default, :@normal, :@override, :@automatic].freeze
      COMPONENT_ACCESSORS = {:default   => :@default,
                             :normal    => :@normal,
                             :override  => :@override,
                             :automatic => :@automatic
                            }

      attr_accessor :normal,
                    :default,
                    :override,
                    :automatic,
                    :set_unless_value_present,
                    :set_type,
                    :properties

      def initialize(normal, default, override, automatic)
        @properties = AttrProperties.new
        @normal = VividMash.new(properties, normal)
        @default = VividMash.new(properties, default)
        @override = VividMash.new(properties, override)
        @automatic = VividMash.new(properties, automatic)

        @auto_vivifiy_on_read = false
        @set_unless_value_present = false
        @set_type = nil
        @has_been_read = false
        @merged_attributes = nil
      end

      def reset
        @merged_attributes = nil
      end

      def auto_vivify_on_read
        @properties.auto_vivify_on_read?
      end

      def auto_vivify_on_read=(setting)
        @properties.auto_vivify_on_read = setting
      end

      def default
        @merged_attributes = nil
        @default
      end

      def normal
        @merged_attributes = nil
        @normal
      end

      def override
        @merged_attributes = nil
        @override
      end

      def automatic
        @merged_attributes = nil
        @automatic
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
          value = Mash.new
          set_type_hash[key] = value
        end

        value
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

      def setting_a_value?
        !@set_type.nil?
      end

      def set_type_hash
        if ivar = COMPONENT_ACCESSORS[@set_type]
          instance_variable_get(ivar)
        else
          raise InvalidAttributeSetterContext, "Cannot set an attribute without first specifying the precedence"
        end
      end

      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol) || setting_a_value?
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        elsif setting_a_value? and symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      def inspect
        "#<#{self.class} " << COMPONENTS.map{|iv|
          "#{iv}=#{instance_variable_get(iv)}"
        }.join(', ') << ">"
      end
    end

    class Attribute

      class ImmutableAttribute < NoMethodError
      end

      HIDDEN_ATTRIBUES = [:@override, :@attribute, :@default, :@normal, :@automatic]

      attr_accessor :normal,
                    :default,
                    :override,
                    :automatic,
                    :current_normal,
                    :current_default,
                    :current_override,
                    :current_automatic,
                    :auto_vivifiy_on_read,
                    :set_unless_value_present,
                    :set_type

      include Enumerable

      def initialize(normal, default, override, automatic, state=[])
        @normal = normal
        @current_normal = normal
        @default = default
        @current_default = default
        @override = override
        @current_override = override
        @automatic = automatic
        @current_automatic = automatic
        @current_nesting_level = state
        @auto_vivifiy_on_read = false
        @set_unless_value_present = false
        @set_type = nil
        @has_been_read = false
      end

      def set_type_hash
        case @set_type
        when :normal
          @normal
        when :override
          @override
        when :default
          @default
        when :automatic
          @automatic
        end
      end

      # Reset our internal current_nesting_level to the top of every tree
      def reset
        @current_normal = @normal
        @current_default = @default
        @current_override = @override
        @current_automatic = @automatic
        @has_been_read = false
        @current_nesting_level = []
      end

      def [](key)
        @current_nesting_level << key

        # We set this to so that we can cope with ||= as a setting.
        # See the comments in []= for more details.
        @has_been_read = true

        # If we have a set type, our destiny is to write
        if @set_type
          a_value = @set_type == :automatic ? value_or_descend(current_automatic, key, auto_vivifiy_on_read) : nil
          o_value = @set_type == :override ? value_or_descend(current_override, key, auto_vivifiy_on_read) : nil
          n_value = @set_type == :normal ? value_or_descend(current_normal, key, auto_vivifiy_on_read) : nil
          d_value = @set_type == :default ? value_or_descend(current_default, key, auto_vivifiy_on_read) : nil

          determine_value(a_value, o_value, n_value, d_value)
        # Our destiny is only to read, so we get the full list.
        else
          a_value = value_or_descend(current_automatic, key)
          o_value = value_or_descend(current_override, key)
          n_value = value_or_descend(current_normal, key)
          d_value = value_or_descend(current_default, key)

          determine_value(a_value, o_value, n_value, d_value)
        end
      end

      def has_key?(key)
        return true if component_has_key?(@default,key)
        return true if component_has_key?(@automatic,key)
        return true if component_has_key?(@normal,key)
        return true if component_has_key?(@override,key)
        false
      end

      alias :attribute? :has_key?
      alias :include?   :has_key?
      alias :key?       :has_key?
      alias :member?    :has_key?

      def each(&block)
        get_keys.each do |key|
          value = determine_value(
            get_value(automatic, key),
            get_value(override, key),
            get_value(normal, key),
            get_value(default, key)
          )
          block.call([key, value])
        end
      end

      def each_pair(&block)
        get_keys.each do |key|
          value = determine_value(
            get_value(automatic, key),
            get_value(override, key),
            get_value(normal, key),
            get_value(default, key)
          )
          block.call(key, value)
        end
      end

      def each_attribute(&block)
        get_keys.each do |key|
          value = determine_value(
            get_value(automatic, key),
            get_value(override, key),
            get_value(normal, key),
            get_value(default, key)
          )
          block.call(key, value)
        end
      end

      def each_key(&block)
        get_keys.each do |key|
          block.call(key)
        end
      end

      def each_value(&block)
        get_keys.each do |key|
          value = determine_value(
            get_value(automatic, key),
            get_value(override, key),
            get_value(normal, key),
            get_value(default, key)
          )
          block.call(value)
        end
      end

      def empty?
        get_keys.empty?
      end

      def fetch(key, default_value=nil, &block)
        if get_keys.include? key
          determine_value(
            get_value(automatic, key),
            get_value(override, key),
            get_value(normal, key),
            get_value(default, key)
          )
        elsif default_value
          default_value
        elsif block_given?
          block.call(key)
        else
          raise IndexError, "Key #{key} does not exist"
        end
      end

      # Writing this method hurts me a little bit.
      #
      # TODO: Refactor all this stuff so this kind of horror is no longer needed
      #
      # We have invented a new kind of duck-typing, we call it Madoff typing.
      # We just lie and hope we die before you recognize our scheme. :)
      def kind_of?(klass)
        if klass == Hash || klass == Mash || klass == Chef::Node::Attribute
          true
        else
          false
        end
      end

      def has_value?(value)
        self.any? do |k,v|
          value == v
        end
      end

      alias :value? :has_value?

      def index(value)
        index = self.find do |h|
          value == h[1]
        end
        index.first if index.is_a? Array || nil
      end

      def values
        self.collect { |h| h[1] }
      end

      def size
        self.collect{}.length
      end

      alias :length :size

      def get_keys
        keys
      end

      def keys
        tkeys = current_automatic ? current_automatic.keys : []
        [ current_override, current_normal, current_default ].each do |attr_hash|
          if attr_hash
            attr_hash.keys.each do |key|
              tkeys << key unless tkeys.include?(key)
            end
          end
        end
        tkeys
      end

      def get_value(data_hash, key)
        last = nil

        if @current_nesting_level.length == 0
          if data_hash.has_key?(key) && ! data_hash[key].nil?
            return data_hash[key]
          else
            return nil
          end
        end

        0.upto(@current_nesting_level.length) do |i|
          if i == 0
            last = auto_vivifiy(data_hash, @current_nesting_level[i])
          elsif i == @current_nesting_level.length
            fk = last[@current_nesting_level[i - 1]]
            if fk.has_key?(key) && ! fk[key].nil?
              return fk[key]
            else
              return nil
            end
          else
            last = auto_vivifiy(last[@current_nesting_level[i - 1]], @current_nesting_level[i])
          end
        end
      end

      def hash_and_not_cna?(to_check)
        (! to_check.kind_of?(Chef::Node::Attribute)) && to_check.respond_to?(:has_key?)
      end

      def determine_value(a_value, o_value, n_value, d_value)
        if hash_and_not_cna?(a_value)
          value = {}
          value = Chef::Mixin::DeepMerge.merge(value, d_value) if hash_and_not_cna?(d_value)
          value = Chef::Mixin::DeepMerge.merge(value, n_value) if hash_and_not_cna?(n_value)
          value = Chef::Mixin::DeepMerge.merge(value, o_value) if hash_and_not_cna?(o_value)
          value = Chef::Mixin::DeepMerge.merge(value, a_value)
          value
        elsif hash_and_not_cna?(o_value)
          value = {}
          value = Chef::Mixin::DeepMerge.merge(value, d_value) if hash_and_not_cna?(d_value)
          value = Chef::Mixin::DeepMerge.merge(value, n_value) if hash_and_not_cna?(n_value)
          value = Chef::Mixin::DeepMerge.merge(value, o_value)
          value
        elsif hash_and_not_cna?(n_value)
          value = {}
          value = Chef::Mixin::DeepMerge.merge(value, d_value) if hash_and_not_cna?(d_value)
          value = Chef::Mixin::DeepMerge.merge(value, n_value)
          value
        elsif hash_and_not_cna?(d_value)
          d_value
        else
          return a_value if ! a_value.nil?
          return o_value if ! o_value.nil?
          return n_value if ! n_value.nil?
          return d_value if ! d_value.nil?
          return nil
        end
      end

      def []=(key, value)
        if @set_type.nil?
          # @set_type = :normal
          raise ImmutableAttribute, "Attributes may only be set by specifying the precedence level, e.g., node.normal[:foo] = 'bar'"
        elsif @set_type == false
          raise "WTF"
        end

        if set_unless_value_present
          if get_value(set_type_hash, key) != nil
            Chef::Log.debug("Not setting #{@current_nesting_level.join("/")}/#{key} to #{value.inspect} because it has a #{@set_type} value already")
            return false
          end
        end

        # If we have been read, and the key we are writing is the same
        # as our parent, we have most like been ||='ed.  So we need to
        # just rewind a bit.
        #
        # In practice, these objects are single use - this is just
        # supporting one more single-use style.
        @current_nesting_level.pop if @has_been_read && @current_nesting_level.last == key

        set_value(set_type_hash, key, value)
        value
      end

      def set_value(data_hash, key, value)
        last = nil

        # If there is no current_nesting_level, just set the value
        if @current_nesting_level.length == 0
          data_hash[key] = value
          return data_hash
        end

        # Walk all the previous places we have been
        0.upto(@current_nesting_level.length) do |i|
          # If we are the first, we are top level, and should vivifiy the data_hash
          if i == 0
            last = auto_vivifiy(data_hash, @current_nesting_level[i])
          # If we are one past the last current_nesting_level, we are adding a key to that hash with a value
          elsif i == @current_nesting_level.length
            last[@current_nesting_level[i - 1]][key] = value
          # Otherwise, we're auto-vivifiy-ing an interim mash
          else
            last = auto_vivifiy(last[@current_nesting_level[i - 1]], @current_nesting_level[i])
          end
        end
        data_hash
      end

      def auto_vivifiy_on_read?
        auto_vivifiy_on_read
      end

      def auto_vivifiy(data_hash, key)
        if data_hash.has_key?(key)
          unless data_hash[key].respond_to?(:has_key?)
            raise ArgumentError, "You tried to set a nested key, where the parent is not a hash-like object: #{@current_nesting_level.join("/")}/#{key} " unless auto_vivifiy_on_read
          end
        else
          data_hash[key] = Mash.new
        end
        data_hash
      end

      def value_or_descend(data_hash, key, auto_vivifiy=false)
        if auto_vivifiy
          hash_to_vivifiy = auto_vivifiy(data_hash, key)
          data_hash[key] = hash_to_vivifiy[key]
        else
          return nil if data_hash == nil
          return nil unless data_hash.has_key?(key)
        end

        if data_hash[key].respond_to?(:has_key?)
          cna = Chef::Node::Attribute.new(@normal, @default, @override, @automatic, @current_nesting_level)
          cna.current_normal = current_normal.nil? ? Mash.new : current_normal[key]
          cna.current_default   = current_default.nil? ? Mash.new : current_default[key]
          cna.current_override  = current_override.nil? ? Mash.new : current_override[key]
          cna.current_automatic  = current_automatic.nil? ? Mash.new : current_automatic[key]
          cna.auto_vivifiy_on_read = auto_vivifiy_on_read
          cna.set_unless_value_present = set_unless_value_present
          cna.set_type = set_type
          cna
        else
          data_hash[key]
        end
      end

      # Fetches or sets the value, depending on if any arguments are given.
      # ==== Fetching
      # If no arguments are given, fetches the value:
      #   node.network
      #   => {network data}
      # Getters will find either a string or symbol key.
      # ==== Setting
      # If arguments are given, a value will be set. Both normal setter and DSL
      # style setters are allowed:
      #   node.foo = "bar"
      #   node.foo("bar")
      # Both set node[:foo] = "bar"
      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol)
            self[symbol]
          elsif key?(symbol.to_s)
            self[symbol.to_s]
          elsif auto_vivifiy_on_read?
            self[symbol] = Mash.new
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        elsif symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1] || symbol
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      def inspect
        determine_value(current_automatic, current_override, current_normal, current_default)

        "#<#{self.class} " << instance_variables.map{|iv|
          iv.to_s + '=' + (HIDDEN_ATTRIBUES.include?(iv.to_sym) ? "{...}" : instance_variable_get(iv).inspect)
        }.join(', ') << ">"
      end

      def to_hash
        result = determine_value(current_automatic, current_override, current_normal, current_default)
        if result.class == Hash
          result
        else
          result.to_hash
        end
      end

      def delete(key)
        [@automatic, @override, @normal, @default].inject(nil) do |return_value, attrs|
          deleted_value = delete_from_component(attrs, key)
          return_value || deleted_value
        end
      end

      def delete_from_component(component_attrs, key)
        # get the Hash-like object at the current nesting level:
        nested_attrs = value_at_current_nesting(component_attrs, key)

        if nested_attrs.respond_to?(:delete)
          nested_attrs.delete(key)
        else
          nil
        end
      end

      def component_has_key?(component_attrs,key)
        # get the Hash-like object at the current nesting level:
        nested_attrs = value_at_current_nesting(component_attrs, key)
        nested_attrs.respond_to?(:key?) && nested_attrs.key?(key)
      end

      def value_at_current_nesting(component_attrs, key)
        @current_nesting_level.inject(component_attrs) do |subtree, intermediate_key|
          # if the intermediate value isn't a hash or doesn't have the intermediate key,
          # it can't have the bottom-level key we're looking for.
          (subtree.respond_to?(:key?) && subtree[intermediate_key]) or (return false)
        end
      end

    end
  end
end
