require 'chef/node/attribute_constants'
require 'chef/node/attribute_trait/immutablize'
require 'chef/node/vivid_mash'

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
      include AttributeTrait::Immutablize

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

      def initialize(default: nil, env_default: nil, role_default: nil, force_default: nil,
                     normal: nil,
                     override: nil, role_override: nil, env_override: nil, force_override: nil,
                     automatic: nil)
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
              Chef::Node::VividMash.new(wrapped_object: value)
            else
              value
            end
          )
        end
      end

      def kind_of?(klass)
        highest_precedence.kind_of?(klass) || super(klass)
      end

      def is_a?(klass)
        highest_precedence.is_a?(klass) || super(klass)
      end

      def kind_of?(klass)
        highest_precedence.kind_of?(klass) || super(klass)
      end

      def eql?(other)
        as_simple_object.eql?(other)
      end

      def ==(other)
        as_simple_object == other
      end

      def ===(other)
        as_simple_object === other
      end

      def to_s
        as_simple_object.to_s
      end

      def method_missing(method, *args, &block)
        # FIXME: we're leaking stringize into this method
        begin
          as_simple_object.public_send(method, *args, &block)
        rescue NoMethodError
          if args.empty?
            self[method.to_s]
          else
            raise
          end
        end
      end

      def respond_to?(method, include_private = false)
        # FIXME: we're leaking stringize into this method
        as_simple_object.respond_to?(method, include_private) || key?(method.to_s)
      end

      def [](key)
        if self.is_a?(Hash)
          # this is a one-level deep_merge that preserves precedence level
          args = {}
          highest_found_value = nil
          COMPONENTS.map do |component|
            hash = instance_variable_get(component)
            next unless hash.is_a?(Hash)
            next unless hash.key?(key)
            args[component.to_s[1..-1].to_sym] = highest_found_value = hash[key]
          end
          if highest_found_value.is_a?(Array) || highest_found_value.is_a?(Hash)
            return self.class.new(args)
          else
            return highest_found_value
          end
        elsif self.is_a?(Array)
          tuple = highest_precedence_zipped_array[key]
          if tuple[:value].is_a?(Hash) || tuple[:value].is_a?(Array)
            # return a new decorator with the correct precedence level set to the value
            return self.class.new(tuple[:level] => tuple[:value])
          else
            # return just the bare value
            return tuple[:value]
          end
        else
          # this should never happen - should probably freeze this or dump/load
          return highest_precedence[key]
        end
      end

      def combined_default
        return self.class.new(
          default: @default,
          env_default: @env_default,
          role_default: @role_default,
          force_default: @force_default,
        )
      end

      def combined_override
        return self.class.new(
          override: @override,
          role_override: @role_override,
          env_override: @env_override,
          force_override: @force_override,
        )
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        if self.is_a?(Hash)
          merged_hash.keys.each do |key|
            yield key, self[key]
          end
        elsif self.is_a?(Array)
          highest_precedence_zipped_array.each do |value|
            yield self.class.new(tuple[:level] => tuple[:value])
          end
        else
          yield highest_precedence
        end
      end

      def to_json(*opts)
        Chef::JSONCompat.to_json(to_hash, *a)
      end

      def to_hash
        if self.is_a?(Hash)
          h = {}
          each do |key, value|
            if value.is_a?(Hash)
              h[key] = value.to_hash
            elsif value.is_a?(Array)
              h[key] = value.to_a
            else
              h[key] = value
            end
          end
          h
        elsif self.is_a?(Array)
          raise
        else
          highest_precedence.to_hash
        end
      end

      def to_a
        if self.is_a?(Hash)
          raise
        elsif self.is_a?(Array)
          a = []
          each do |value|
            a.push(value)
          end
          a
        else
          highest_precedence.to_a
        end
      end

      private

      def as_simple_object
        if self.is_a?(Hash)
          merged_hash
        elsif self.is_a?(Array)
          highest_precedence_array
        else
          # in normal usage we never wrap non-containers, so this should never happen
          highest_precedence
        end
      end

      def merged_hash
        # this is a one level deep deep_merge
        merged_hash = {}
        COMPONENTS.each do |component|
          hash = instance_variable_get(component)
          next unless hash.is_a?(Hash)
          hash.each do |key, value|
            merged_hash[key] = value
          end
        end
        merged_hash
      end

      def merged_default_zipped_array
        return nil unless DEFAULT_COMPONENTS_AS_SYMBOLS.any? do |component|
          send(component).is_a?(Array)
        end
        # this is a one level deep deep_merge
        DEFAULT_COMPONENTS_AS_SYMBOLS.each_with_object([]) do |component, merged_array|
          array = instance_variable_get(:"@#{component}")
          next unless array.is_a?(Array)
          merged_array << array.map do |value|
            { level: component, value: value }
          end
        end.flatten
      end

      def merged_normal_zipped_array
        return nil unless @normal.is_a?(Array)
        @normal.map { |value| { level: :normal, value: value } }
      end

      def merged_override_zipped_array
        return nil unless OVERRIDE_COMPONENTS_AS_SYMBOLS.any? do |component|
          send(component).is_a?(Array)
        end
        # this is a one level deep deep_merge
        OVERRIDE_COMPONENTS_AS_SYMBOLS.each_with_object([]) do |component, merged_array|
          # FIXME: test all of these to make sure we're not getting VividMashes through
          # the accessor and are really getting the instance variable directly
          array = instance_variable_get(:"@#{component}")
          next unless array.is_a?(Array)
          merged_array << array.map do |value|
            { level: component, value: value }
          end
        end.flatten
      end

      def merged_automatic_zipped_array
        return nil unless @automatic.is_a?(Array)
        @automatic.map { |value| { level: :automatic, value: value } }
      end

      def highest_precedence_array
        highest_precedence_zipped_array.map { |i| i[:value] }
      end

      def highest_precedence_zipped_array
        raise "internal bug, please report" unless is_a?(Array)
        return merged_automatic_zipped_array if merged_automatic_zipped_array
        return merged_override_zipped_array if merged_override_zipped_array
        return merged_normal_zipped_array if merged_normal_zipped_array
        return merged_default_zipped_array if merged_default_zipped_array
        raise "internal bug, please report"
      end

      # @return [Object] value of the highest precedence level
      def highest_precedence
        COMPONENTS.map do |component|
          instance_variable_get(component)
        end.compact.last
      end
    end
  end
end
