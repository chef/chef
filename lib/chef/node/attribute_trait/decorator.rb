class Chef
  class Node
    class AttributeTrait
      module Decorator

        attr_accessor :wrapped_object

        def initialize(wrapped_object: nil)
          @wrapped_object = wrapped_object
        end

        def is_a?(klass)
          return true if wrapped_object.is_a?(klass)
          super
        end

        def [](key)
          ret = wrapped_object[key]
          if ret.is_a?(Hash) || ret.is_a?(Array)
            self.class.new(wrapped_object: ret)
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
          wrapped_object.respond_to?(method, include_private)
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

        # rescue "can't dup NilClass"
        def safe_dup(e)
          e.dup
        rescue TypeError
          e
        end

      end
    end
  end
end
