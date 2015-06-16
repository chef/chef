class Chef
  class Node
    class AttributeTrait
      module Methodize

        alias_method :original_respond_to?, :respond_to?

        def method_missing(symbol, *args, &block)
          if self.is_a?(Hash)
            if original_respond_to?(symbol)
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

        def respond_to?(symbol, include_private = false)
          original_respond_to?(symbol, include_private) || key?(symbol)
          # should return true if the symbol ends in '=' as well?  not sure.
        end

      end
    end
  end
end
