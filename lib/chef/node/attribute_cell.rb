require "chef/node/attribute_constants"
require "chef/node/vivid_mash"
require "chef/node/immutable_mash"

class Chef
  class Node
    class AttributeCell

      #
      # There are dangerous and unpredictable ways to use the internals of this API:
      #
      # 1.  Mutating an interior hash/array into a bare value (particularly nil)
      # 2.  Using individual setters/getters at anything other than the top level (always use
      #     node.default['foo'] not node['foo'].default)
      #

      include AttributeConstants

      attr_accessor :default
      attr_accessor :env_default
      attr_accessor :role_default
      attr_accessor :force_default
      attr_accessor :normal
      attr_accessor :override
      attr_accessor :role_override
      attr_accessor :env_override
      attr_accessor :force_override
      attr_accessor :automatic
      attr_accessor :__node
      attr_accessor :__deep_merge_cache

      def to_json(*opts)
        raise "BUG: should not be called"
      end

      def to_ffi_yajl(*opts)
        raise "BUG: should not be called"
      end

      def to_ary
        merged_object(decorated: false).to_ary
      end

      def to_a
        merged_object(deocrated: false).to_a
      end

      def to_hash
        merged_object(decorated: false).to_hash
      end

      def to_h
        merged_object(decorated: false).to_h
      end

      def for_json
        merged_object(decorated: false).for_json
      end

      def initialize(default: nil, env_default: nil, role_default: nil, force_default: nil,
                     normal: nil,
                     override: nil, role_override: nil, env_override: nil, force_override: nil,
                     automatic: nil,
                     node: nil,
                     deep_merge_cache: nil)
        @__node = node
        @__deep_merge_cache = deep_merge_cache
        self.default        = default
        self.env_default    = env_default
        self.role_default   = role_default
        self.force_default  = force_default
        self.normal         = normal
        self.override       = override
        self.role_override  = role_override
        self.env_override   = env_override
        self.force_override = force_override
        self.automatic      = automatic
      end

      COMPONENTS_AS_SYMBOLS.each do |component|
        define_method :"#{component}=" do |value|
          instance_variable_set(
            :"@#{component}",
            if value.is_a?(Hash) || value.is_a?(Array)
              Chef::Node::VividMash.new(
                wrapped_object: value,
                precedence: component,
                node: __node,
                deep_merge_cache: __deep_merge_cache
              )
            else
              value
            end
          )
        end
      end

      # This method is used to take the Mash that ohai gives us
      # and wrap it with a VividMash and bypass convert_value'ing the
      # Mash which is already converted.  If ohai internally used
      # VividMashes we could avoid wrapping entirely and just wire up
      # the deep_merge_cache and node objects for tracking.
      #
      # @api private
      def wrap_automatic_attrs(value)
        @automatic = Chef::Node::VividMash.new(
          wrapped_object: value,
          precedence: :automatic,
          node: __node,
          deep_merge_cache: __deep_merge_cache,
          convert_value: false
        )
      end

      # This function takes the same arguments as the constructor, but by-passes the
      # accessors and short-cricuits calling convert_value on the arguments which
      # are passed.
      #
      # @api private
      def new_cell(node, deep_merge_cache, **args)
        cell = self.class.allocate
        cell.__node = node
        cell.__deep_merge_cache = deep_merge_cache
        args.each do |key, value|
          cell.instance_variable_set(:"@#{key}", value)
        end
        cell
      end

      # For performance reasons we do not mixin the Enumerable class, but instead
      # delegate Enumerable methods to the constructed deep merged object.
      Enumerable.instance_methods.each do |method|
        define_method method do |*args, &block|
          merged_object.public_send(method, *args, &block)
        end
      end

      def is_a?(klass)
        highest_precedence.is_a?(klass) || super(klass)
      end

      def kind_of?(klass)
        highest_precedence.kind_of?(klass) || super(klass)
      end

      def eql?(other)
        if is_a?(Hash)
          return false unless other.is_a?(Hash)
          merged_hash.each do |key, value|
            return false unless merged_hash[key].eql?(other[key])
          end
          return true
        elsif is_a?(Array)
          return false unless other.is_a?(Array)
          merged_array.each_with_index do |value, i|
            return false unless value.eql?(other[i])
          end
          return true
        else
          highest_precedence.eql?(other)
        end
      end

      def ==(other)
        if is_a?(Hash)
          return false unless other.is_a?(Hash)
          merged_hash.each do |key, value|
            return false unless merged_hash[key] == other[key]
          end
        elsif is_a?(Array)
          return false unless other.is_a?(Array)
          merged_array.each_with_index do |value, i|
            return false unless value == other[i]
          end
        else
          highest_precedence == other
        end
      end

      def ===(other)
        merged_object === other
      end

      def to_s
        merged_object(decorated: false).to_s
      end

      # perf
      def key?(key)
        if self.is_a?(Hash)
          merged_hash_has_key?(key)
        else
          merged_object(decorated: false).key?(key)
        end
      end

      # perf
      def include?(key)
        if self.is_a?(Hash)
          merged_hash_has_key?(key)
        else
          merged_object(decorated: false).include?(key)
        end
      end

      # perf
      def member?(key)
        if self.is_a?(Hash)
          merged_hash_has_key?(key)
        else
          merged_object(decorated: false).member?(key)
        end
      end

      # perf
      def has_key?(key)
        if self.is_a?(Hash)
          merged_hash_has_key?(key)
        else
          merged_object(decorated: false).has_key?(key)
        end
      end

      def method_missing(method, *args, &block)
        merged_object.public_send(method, *args, &block)
      end

      def respond_to?(method, include_private = false)
        merged_object.respond_to?(method, include_private) || is_a?(Hash) && key?(method.to_s)
      end

      def [](key)
        if self.is_a?(Hash)
          merged_hash_key(key)
        elsif self.is_a?(Array)
          merged_array[key]
        else
          return highest_precedence[key]
        end
      end

      def combined_default
        new_cell(nil, nil, default: @default, env_default: @env_default, role_default: @role_default, force_default: @force_default)
      end

      def combined_override
        new_cell(nil, nil, override: @override, role_override: @role_override, env_override: @env_override, force_override: @force_override)
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        if self.is_a?(Hash)
          merged_hash.each do |key, value|
            yield key, value
          end
        elsif self.is_a?(Array)
          merged_array.each do |value|
            yield value
          end
        else
          yield highest_precedence
        end
      end

      private

      def merged_object(decorated: true)
        if self.is_a?(Hash)
          merged_hash(decorated: decorated)
        elsif self.is_a?(Array)
          merged_array(decorated: decorated)
        else
          # in normal usage we never wrap non-containers, so this should never happen
          highest_precedence
        end
      end

      def merged_hash_has_key?(key)
        COMPONENTS_AS_SYMBOLS.reverse_each do |component|
          hash = instance_variable_get(:"@#{component}")
          next unless hash.is_a?(Hash)
          return true if hash.key?(key)
        end
        return false
      end

      def merged_hash_key(key)
        # this is much faster than merged_hash[key]
        highest_value_found = false
        retval = nil
        COMPONENTS_AS_SYMBOLS.reverse_each do |component|
          hash = instance_variable_get(:"@#{component}")
          next unless hash.is_a?(Hash)
          next unless hash.key?(key)
          value = hash[key]
          unless highest_value_found
            highest_value_found = true
            # this short-circuit is critical for performance
            return value unless value.is_a?(Hash) || value.is_a?(Array)
          end
          retval ||= self.class.allocate
          retval.instance_variable_set(:"@#{component}", value)
        end
        return retval
      end

      def merged_hash(decorated: true)
        # this is a one level deep deep_merge
        merged_hash = {}
        highest_value_found = {}
        if decorated
          COMPONENTS_AS_SYMBOLS.each do |component|
            hash = instance_variable_get(:"@#{component}")
            next unless hash.is_a?(Hash)
            hash.each do |key, value|
              merged_hash[key] ||= self.class.allocate
              merged_hash[key].instance_variable_set(:"@#{component}", value)
              highest_value_found[key] = value
            end
          end
          # we need to expose scalars as undecorated scalars (esp. nil, true, false)
          highest_value_found.each do |key, value|
            next if highest_value_found[key].is_a?(Hash) || highest_value_found[key].is_a?(Array)
            merged_hash[key] = highest_value_found[key]
          end
          merged_hash
        else
          COMPONENTS_AS_SYMBOLS.each do |component|
            hash = instance_variable_get(:"@#{component}")
            next unless hash.is_a?(Hash)
            hash.each do |key, value|
              merged_hash[key] = value
            end
          end
          merged_hash
        end
      end

      def merged_array(decorated: true)
        automatic_array(decorated: decorated) || override_array(decorated: decorated) || normal_array(decorated: decorated) || default_array(decorated: decorated)
      end

      def default_array(decorated: true)
        return nil unless DEFAULT_COMPONENTS_AS_SYMBOLS.any? do |component|
          send(component).is_a?(Array)
        end
        # this is a one level deep deep_merge
        default_array = []
        DEFAULT_COMPONENTS_AS_SYMBOLS.each do |component|
          array = instance_variable_get(:"@#{component}")
          next unless array.is_a?(Array)
          default_array += array
        end
        if decorated
          ImmutableMash.new(wrapped_object: default_array, convert_value: false) # FIXME: precedence for tracking?
        else
          default_arrary
        end
      end

      def normal_array(decorated: true)
        return nil unless @normal.is_a?(Array)
        if decorated
          ImmutableMash.new(wrapped_object: @normal.wrapped_object, convert_value: false) # FIXME: precedence for tracking
        else
          @normal.wrapped_object
        end
      end

      def override_array(decorated: true)
        return nil unless OVERRIDE_COMPONENTS_AS_SYMBOLS.any? do |component|
          send(component).is_a?(Array)
        end
        # this is a one level deep deep_merge
        override_array = []
        OVERRIDE_COMPONENTS_AS_SYMBOLS.each do |component|
          array = instance_variable_get(:"@#{component}")
          next unless array.is_a?(Array)
          override_array += array
        end
        if decorated
          ImmutableMash.new(wrapped_object: override_array, convert_value: false) # FIXME: precedence for tracking?
        else
          override_array
        end
      end

      def automatic_array(decorated: true)
        return nil unless @automatic.is_a?(Array)
        if decorated
          ImmutableMash.new(wrapped_object: @automatic.wrapped_object, convert_value: false) # FIXME: precedence for tracking
        else
          @automatic.is_a?(Array)
        end
      end

      # @return [Object] value of the highest precedence level
      def highest_precedence
        COMPONENTS.reverse_each do |component|
          value = instance_variable_get(component)
          return value unless value.nil?
        end
        nil
      end
    end
  end
end
