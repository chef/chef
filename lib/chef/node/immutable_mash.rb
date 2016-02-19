require "chef/node/attribute_traits"

#
# This class is for when we walk down the Node and wind up on a single
# precedence level.  For optimization, we can stop doing deep merge
# things, but must remain immutable.
#
class Chef
  class Node
    class ImmutableMash
      include AttributeTrait::Decorator
      include AttributeTrait::SymbolConvert
      include AttributeTrait::MethodMissing
      include AttributeTrait::Immutable
      include AttributeTrait::PathTracking
      # we don't wrap an attribute cell so the deep merge cache is not mixed in
    end
  end
end
