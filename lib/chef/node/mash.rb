require 'chef/node/attribute_trait/decorator'
require 'chef/node/attribute_trait/convert_value'
require 'chef/node/attribute_trait/stringize'

class Chef
  class Node
    class Mash
      include AttributeTrait::Decorator
      include AttributeTrait::ConvertValue
      include AttributeTrait::Stringize
    end
  end
end
