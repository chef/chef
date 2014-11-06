
class Chef
  class Audit
    class ChefExampleGroup

      # Can encompass tests in a `control` block or `describe` block
      ::RSpec::Core::ExampleGroup.define_example_group_method :control
      ::RSpec::Core::ExampleGroup.define_example_group_method :__controls__

    end
  end
end
