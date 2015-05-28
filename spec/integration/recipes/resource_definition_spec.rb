require 'support/shared/integration/integration_helper'

describe "Resource definition" do
  include IntegrationSupport

  context "With a resource with only provides lines and no resource_name" do
    before(:context) {
      class ResourceDefinitionNoNameTest < Chef::Resource
        provides :resource_definition_no_name_test
      end
    }
    it "Creating said resource with the resource builder fails with an exception" do
      expect_converge {
        resource_definition_no_name_test 'blah'
      }.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end
  end
end
