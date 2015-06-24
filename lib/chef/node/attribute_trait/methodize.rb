class Chef
  class Node
    class AttributeTrait
      module Methodize

        def method_missing(symbol, *args, &block)
          if self.is_a?(Hash)
            begin
              # we have to try the superclass methods first
              super(symbol, *args, &block)
            rescue NoMethodError # i feel dirty, but i don't care
              if symbol == :to_ary
                # handles IO#puts calling #to_ary which we cannot autovivize (CHEF-3799)
                raise
              elsif args.empty? && ( autovivizing? || key?(symbol) )
                # handles node.default.foo
                self[symbol]
              elsif symbol.to_s =~ /=$/
                # handles node.default.foo=
                key_to_set = symbol.to_s[/^(.+)=$/, 1]
                self[key_to_set] = (args.length == 1 ? args[0] : args)
              else
                raise
              end
            end
          else
            super(symbol, *args, &block)
          end
        end

        def respond_to?(symbol, include_private = false)
          if self.is_a?(Hash)
            # node.foo
            return true if key?(symbol)
            # node.default.foo=
            return true if symbol.to_s =~ /=$/
          end
          super
        end

        private

        def autovivizing?
          self.class.mixins.include?(:autovivize)
        end

      end
    end
  end
end
