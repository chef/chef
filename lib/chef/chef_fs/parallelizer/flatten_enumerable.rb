class Chef
  module ChefFS
    class Parallelizer
      class FlattenEnumerable
        include Enumerable

        def initialize(enum, levels = nil)
          @enum = enum
          @levels = levels
        end

        attr_reader :enum
        attr_reader :levels

        def each(&block)
          enum.each do |value|
            flatten(value, levels, &block)
          end
        end

        private

        def flatten(value, levels, &block)
          if levels != 0 && value.respond_to?(:each) && !value.is_a?(String)
            value.each do |child|
              flatten(child, levels.nil? ? levels : levels - 1, &block)
            end
          else
            yield(value)
          end
        end
      end
    end
  end
end
