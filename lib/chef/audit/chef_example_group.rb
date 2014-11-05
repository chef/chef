
class Chef
  class Audit
    class ChefExampleGroup < ::RSpec::Core::ExampleGroup
      # Can encompass tests in a `control` block or `describe` block
      define_example_group_method :control
    end
  end
end
