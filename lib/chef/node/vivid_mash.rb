require 'chef/node/attribute_trait/decorator'
require 'chef/node/attribute_trait/stringize'
require 'chef/node/attribute_trait/methodize'
require 'chef/node/attribute_trait/autovivize'

class Chef
  class Node
    class VividMash
      include AttributeTrait::Decorator
      include AttributeTrait::Stringize
      include AttributeTrait::Methodize
      include AttributeTrait::Autovivize

      def initialize(wrapped_object: {})
        super(wrapped_object: wrapped_object)
      end

    end
  end
end
