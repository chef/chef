class Chef
  class Node
    class AttributeTrait
      module Decorator
        attr_accessor :wrapped_object
        include Enumerable

        def initialize(wrapped_object: nil, **args)
          @wrapped_object = wrapped_object
        end

        def ffi_yajl(*args)
          wrapped_object.ffi_yajl(*args)
        end

        def to_json(*opts)
          wrapped_object.to_json(*opts)
        end

        def for_json
          wrapped_object.for_json
        end

        def is_a?(klass)
          wrapped_object.is_a?(klass) || super
        end

        def kind_of?(klass)
          wrapped_object.kind_of?(klass) || super
        end

        def regular_writer(*path, value)
          last_key = path.pop
          obj = path.inject(wrapped_object) { |memo, key| memo[key] }
          obj[last_key] = value
        end

        def regular_reader(*path)
          maybe_decorated_value(
            path.inject(wrapped_object) { |memo, key| memo[key] }
          )
        end

        def [](key)
          maybe_decorated_value(wrapped_object[key])
        end

        def maybe_decorated_value(val)
          if val.is_a?(Hash) || val.is_a?(Array)
            new_decorator(wrapped_object: val)
          else
            val
          end
        end

        def new_decorator(**args)
          self.class.new(**args)
        end

        def method_missing(method, *args, &block)
          if wrapped_object.respond_to?(method, false)
            # we can't define_method here because then we'll always respond_to? the
            # method and in some cases we mutate and no longer respond_to? something
            wrapped_object.public_send(method, *args, &block)
          else
            super
          end
        end

        def respond_to?(method, include_private = false)
          return false if is_a?(Array) && method == :to_hash
          return false if is_a?(Hash) && method == :to_ary
          return false if is_a?(Array) && method == :each_pair
          wrapped_object.respond_to?(method, include_private) || super
        end

        # avoid method_missing perf hit
        def delete(key)
          wrapped_object.delete(key)
        end

        # avoid method_missing perf hit
        def clear
          wrapped_object.clear
        end

        def to_s
          wrapped_object.to_s
        end

        def to_hash
          wrapped_object.to_hash
        end

        def to_a
          wrapped_object.to_a
        end

        def to_ary
          wrapped_object.to_ary
        end

        def initialize_copy(source)
          super
          @wrapped_object = safe_dup(source.wrapped_object)
        end

        # http://blog.rubybestpractices.com/posts/rklemme/018-Complete_Class.html

        def eql?(other)
          wrapped_object.eql?(other)
        end

        def ==(other)
          wrapped_object == other
        end

        def ===(other)
          wrapped_object === other
        end

        def []=(key, value)
          wrapped_object[key] = value
        end

        def key?(key)
          wrapped_object.key?(key)
        end

        # when we're a Hash pick up Hash#select which is different from Enuemrable#select
        def select(&block)
          wrapped_object.select(&block)
        end

        # we need to be careful to return decorated values when appropriate
        def each(&block)
          return enum_for(:each) unless block_given?
          if wrapped_object.is_a?(Array)
            wrapped_object.each_with_index do |value, i|
              yield self[i]
            end
          elsif wrapped_object.is_a?(Hash)
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
            # dunno...
            wrapped_object.each(&block)
          end
        end

        alias_method :each_pair, :each

        # nil, true, false and Fixnums are not dup'able
        def safe_dup(e)
          e.dup
        rescue TypeError
          e
        end

        def dup
          if is_a?(Array)
            Array.new(map { |e|
              safe_dup(e)
            })
          elsif is_a?(Hash)
            h = Hash.new
            each do |k, v|
              h[safe_dup(k)] = safe_dup(v)
            end
            h
          else
            safe_dup(wrapped_object)
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
