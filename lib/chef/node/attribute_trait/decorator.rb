class Chef
  class Node
    class AttributeTrait
      module Decorator
        include Enumerable

        attr_accessor :wrapped_object

        def initialize(wrapped_object: nil)
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
          path.inject(wrapped_object) { |memo, key| memo[key] }
        end

        def [](key)
          ret = wrapped_object[key]
          if ret.is_a?(Hash) || ret.is_a?(Array)
            new_decorator(wrapped_object: ret)
          else
            ret
          end
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
          wrapped_object.respond_to?(method, include_private) || super
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

        #def hash
        #end

        #def <=>
        #end

        #def freeze
        #end

        # nil, true, false and Fixnums are not dup'able
        def safe_dup(e)
          e.dup
        rescue TypeError
          e
        end

        def new_decorator(*args)
          self.class.new_decorator(*args)
        end

        def self.included(base)
          base.extend(DecoratorClassMethods)
        end

        module DecoratorClassMethods
          # this is for convert_value support in order to be able to internally short-circuit
          # convert_value'ing the wrapped_object again
          def new_decorator(wrapped_object: nil)
            dec = allocate
            dec.wrapped_object = wrapped_object
            dec
          end

          def mixins
            @mixins ||= []
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
