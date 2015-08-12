require 'chef/node/attribute_traits'

class Chef
  class Node
    class Mash
      include AttributeTrait::Decorator
      include AttributeTrait::ConvertValue
      include AttributeTrait::SymbolConvert
    end
  end
end
