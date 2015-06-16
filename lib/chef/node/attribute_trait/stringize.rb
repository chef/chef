
# NOTE you must include ConvertValue before this in order to use it
# (fixing to include here is annoying due to the class method)
class Chef
  class Node
    class AttributeTrait
      module Stringize

        protected

        def convert_key(key)
          key.kind_of?(Symbol) ? key.to_s : key
        end

        def convert_value(value)
          if value.is_a?(Hash)
            Hash[value.map {|k, v| [k.to_s, convert_value(v)] }]
          elsif value.is_a?(Array)
            value.map do |v|
              convert_value(v)
            end
          else
            value
          end
        end
      end
    end
  end
end
