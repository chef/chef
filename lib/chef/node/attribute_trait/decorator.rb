class Chef
  class Node
    class AttributeTrait
      module Decorator
        attr_accessor :wrapped_object

        #
        # Performance Delegation
        #

        methods = ( Array.instance_methods & Hash.instance_methods ) - Object.instance_methods +
          [ :!, :!=, :<=>, :==, :===, :eql?, :to_s, :hash, :key, :has_key? ]

        methods.each do |method|
          define_method method do |*args, &block|
            wrapped_object.public_send(method, *args, &block)
          end
        end

        #
        # Construction
        #

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def [](*args)
            new(wrapped_object: Hash[ *args ])
          end
        end

        def initialize(wrapped_object: nil, **args)
          @wrapped_object = wrapped_object
        end

        def new_decorator(**args)
          self.class.new(**args)
        end

        #
        # Conversion
        #

        def ffi_yajl(*opts)
          for_json.ffi_yajl(*opts)
        end

        def to_json(*opts)
          Chef::JSONCompat.to_json(for_json, *opts)
        end

        def for_json
          if is_a?(Hash)
            to_hash
          elsif is_a?(Array)
            to_ary
          else
            wrapped_object
          end
        end

        #
        # Inspection
        #

        def is_a?(klass)
          wrapped_object.is_a?(klass) || super
        end

        def kind_of?(klass)
          wrapped_object.kind_of?(klass) || super
        end

        #
        # Extended API
        #

        def regular_writer(*path, value)
          last_key = path.pop
          obj = path.inject(wrapped_object) { |memo, key| memo[key] }
          obj[last_key] = value
        end

        def regular_reader(*path)
          ret = maybe_decorated_value(
            path.inject(wrapped_object) { |memo, key| memo[key] }
          )
        end

        def safe_reader(*path)
          begin
            regular_reader(*path)
          rescue NoMethodError
            nil
          end
        end

        def safe_delete(*path)
          last = path.pop
          hash = safe_reader(*path)
          return nil unless hash.is_a?(Hash)
          hash.delete(last)
        end

        #
        # method_missing
        #

        def method_missing(method, *args, &block)
          if wrapped_object.respond_to?(method, false)
            # do not define_method here
            wrapped_object.public_send(method, *args, &block)
          else
            super
          end
        end

        def respond_to?(method, include_private = false)
          # since we define these methods, :respond_to_missing? doesn't work.
          return false if is_a?(Array) && method == :each_pair
          return false if is_a?(Array) && method == :key?
          return false if is_a?(Array) && method == :has_key?
          wrapped_object.respond_to?(method, false) || super
        end

        def respond_to_missing?(method, include_private = false)
          wrapped_object.respond_to?(method, false) || super
        end

        #
        # Decorated Methods
        #

        def [](key)
          maybe_decorated_value(wrapped_object[key])
        end

        def any?(&block)
          block ||= ->(o) { o }
          if is_a?(Hash)
            each do |key, value|
              if yield key, value
                return true
              end
            end
          elsif is_a?(Array)
            each do |key|
              if yield key
                return true
              end
            end
          else
            return wrapped_object.any?(&block)
          end
          false
        end

        def each(&block)
          return enum_for(:each) unless block_given?
          if is_a?(Array)
            wrapped_object.each_with_index do |value, i|
              yield self[i]
            end
          elsif is_a?(Hash)
            if block.arity > 1
              wrapped_object.each do |key, value|
                yield key, self[key]
              end
            else
              wrapped_object.each do |key, value|
                yield [ key, self[key] ]
              end
            end
          else
            wrapped_object.each(&block)
          end
        end

        alias_method :each_pair, :each

        def map(&block)
          return enum_for(:map) unless block_given?
          if is_a?(Array)
            ret = []
            each do |elem|
              ret.push(yield elem)
            end
            ret
          else
            wrapped_object.map(&block)
          end
        end

        #
        # Copying and dup'ing
        #

        # nil, true, false and Fixnums are not dup'able
        def safe_dup(e)
          e.dup
        rescue TypeError
          e
        end

        def dup
          if is_a?(Array)
            map(&method(:safe_dup))
          elsif is_a?(Hash)
            h = {}
            each { |k, v| h[safe_dup(k)] = safe_dup(v) }
            h
          else
            safe_dup(wrapped_object)
          end
        end

        def initialize_copy(source)
          super
          @wrapped_object = safe_dup(source.wrapped_object)
        end

        private

        def maybe_decorated_value(val)
          if val.is_a?(Hash) || val.is_a?(Array)
            new_decorator(wrapped_object: val)
          else
            val
          end
        end

      end
    end
  end
end

#
# Ruby is arguably buggy here.  The Module.=== operator does not call
# kind_of? or is_a? but only looks up the ancestor heirarchy, so only
# things that directly inherit from Array or Hash can be matched in a
# case statement.  TODO:  supply a patch to ruby to fix its behavior.
#
# Please see the implementation of Module.=== in the ruby source code
#
class Hash
  def self.===(other)
    other.kind_of?(Chef::Node::AttributeTrait::Decorator) || super
  end
end

class Array
  def self.===(other)
    other.kind_of?(Chef::Node::AttributeTrait::Decorator) || super
  end
end
