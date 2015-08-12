require 'chef/node/attribute_traits'

class Chef
  class Node
    class UnMethodChain
      include AttributeTrait::Decorator
      include AttributeTrait::UnMethodChain
    end
  end
end
