require 'chef/node/attribute_traits'

class Chef
  class Node
    class SetUnless
      include AttributeTrait::Decorator
      include AttributeTrait::SetUnless
    end
  end
end
