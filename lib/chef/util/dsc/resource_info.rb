
class Chef
  class Util
    class DSC
      class ResourceInfo
        # The name is the text following [Start Set]
        attr_reader :name

        # A list of all log messages between [Start Set] and [End Set].
        # Each line is an element in the list.
        attr_reader :change_log

        def initialize(name, sets, change_log)
          @name = name
          @sets = sets
          @change_log = change_log || []
        end

        # Does this resource change the state of the system?
        def changes_state?
          @sets
        end
      end
    end
  end
end
