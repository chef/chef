# Inside a `controls` block, self refers to a subclass of RSpec::ExampleGroups so `package` calls the correct
# serverspec helper
controls "some controls" do
  package "foo2"
end
