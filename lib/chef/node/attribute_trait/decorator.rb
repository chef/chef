class Chef
  class Node
    class AttributeTrait
      module Decorator
        attr_accessor :wrapped_object

        def initialize(wrapped_object: nil)
          @wrapped_object = wrapped_object
        end

        def to_json(*opts)
          wrapped_object.to_json(*opts)
        end

        def is_a?(klass)
          return true if wrapped_object.is_a?(klass)
          super
        end

        def kind_of?(klass)
          return true if wrapped_object.kind_of?(klass)
          super
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
          if wrapped_object.respond_to?(method)
            wrapped_object.public_send(method, *args, &block)
          else
            super
          end
        end

        def respond_to?(method, include_private = false)
          wrapped_object.respond_to?(method, include_private) || super
        end

        def inspect
          "#{self.class.to_s}: #{wrapped_object.inspect}\n"
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

        def initialize_copy(source)
          super
          @wrapped_object = safe_dup(source.wrapped_object)
        end

        # http://blog.rubybestpractices.com/posts/rklemme/018-Complete_Class.html

        #def to_json
        #end
        #def for_json
        #end

        def eql?(other)
          wrapped_object.eql?(other)
        end

        def ==(other)
          wrapped_object == other
        end

        def ===(other)
          wrapped_object === other
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

        def new_decorator(wrapped_object: wrapped_object)
          self.class.new_decorator(wrapped_object: wrapped_object)
        end

        def self.included(base)
          base.extend(DecoratorClassMethods)
        end

        module DecoratorClassMethods
          def new_decorator(wrapped_object: wrapped_object)
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
