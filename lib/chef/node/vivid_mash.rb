require 'chef/node/attribute_trait/decorator'
require 'chef/node/attribute_trait/convert_value'
require 'chef/node/attribute_trait/stringize'
require 'chef/node/attribute_trait/autovivize'
require 'chef/node/attribute_trait/methodize'

class Chef
  class Node
    class VividMash
      include AttributeTrait::Decorator
      include AttributeTrait::ConvertValue
      include AttributeTrait::Autovivize
      include AttributeTrait::Stringize
      include AttributeTrait::Methodize
    end
  end
end
