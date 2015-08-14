
#
# This is useful as a class that can sit at the base of module lookups and will not
# call super and will slurp up all the **args in initialize.
#

class Chef
  class Node
    class AttributeTrait
      module Base
        def initialize(**args)
        end

        def []=(key, value)
        end

        def [](key)
        end

        def convert_key(key)
        end

        def convert_value(value)
        end
      end
    end
  end
end
