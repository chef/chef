require 'chef/node/attribute_traits'

class Chef
  class Node
    class VividMash
      include AttributeTrait::Decorator
      include AttributeTrait::Autovivify
      include AttributeTrait::SymbolConvert
      include AttributeTrait::MethodMissing
      include AttributeTrait::DeepMergeCache
      include AttributeTrait::PathTracking
    end
  end
end
