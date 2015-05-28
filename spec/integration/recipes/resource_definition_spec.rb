require 'support/shared/integration/integration_helper'

describe "Resource definition" do
  include IntegrationSupport

  context "With a resource with no resource_name or provides line" do
    before do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
    end

    before(:context) {
      class Chef::Resource::ResourceDefinitionNoNameTest < Chef::Resource
      end
    }
    it "Creating said resource with the resource builder fails with an exception" do
      expect_converge {
        resource_definition_no_name_test 'blah'
      }.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end
  end
end
