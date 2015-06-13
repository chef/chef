require 'chef/node/attribute_trait/decorator'
require 'chef/node/attribute_trait/set_unlessize'

class Chef
  class Node
    class SetUnless
      include AttributeTrait::Decorator
      include AttributeTrait::SetUnlessize
    end
  end
end
