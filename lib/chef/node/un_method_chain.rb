require 'chef/node/attribute_trait/decorator'
require 'chef/node/attribute_trait/un_method_chainize'

class Chef
  class Node
    class UnMethodChain
      include AttributeTrait::Decorator
      include AttributeTrait::UnMethodChainize
    end
  end
end
