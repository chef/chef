require "chef/node/attribute_traits"

#
# This class is for optimizing #to_hash so that we return one of these wrapping
# the node object, and then we lazily #dup the object when we call mutator methods
# rather than #dup'ing the entire node to begin with.
#
class Chef
  class Node
    class COWMash
      include AttributeTrait::Decorator
      include AttributeTrait::SymbolConvert
      include AttributeTrait::MethodMissing
      include AttributeTrait::CopyOnWrite
    end
  end
end
