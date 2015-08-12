require 'chef/node/attribute_traits'

class Chef
  class Node
    class VividMash
      include AttributeTrait::Decorator
      include AttributeTrait::ConvertValue
      include AttributeTrait::Autovivify
      include AttributeTrait::SymbolConvert
      include AttributeTrait::MethodMissing
    end
  end
end
