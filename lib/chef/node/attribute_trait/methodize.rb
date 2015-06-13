class Chef
  class Node
    class AttributeTrait
      module Methodize

        def method_missing(symbol, *args, &block)
          if self.is_a?(Hash)
            if respond_to?(symbol)
              # a method_missing higher up the mixin/inheritance tree handles this
              super(symbol, *args, &block)
            elsif args.empty?
              # handles node.foo
              if key?(symbol)
                self[symbol]
              else
                super(symbol, *args, &block)
              end
            elsif symbol.to_s =~ /=$/
              # handles node.default.foo=
              key_to_set = symbol.to_s[/^(.+)=$/, 1]
              self[key_to_set] = (args.length == 1 ? args[0] : args)
            else
              super(symbol, *args, &block)
            end
          else
            super(symbol, *args, &block)
          end
        end

        # we do not implement respond_to? here deliberately because it would become
        # largely meaningless.
        #
        # this is a huge smell that this pattern is overall terrible and should never have
        # been used in the first place.
        #
        # that and this insolvable problem:
        #
        # foo['class'] = 'bar'
        # foo.class  # != 'bar'

      end
    end
  end
end
