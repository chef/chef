require "support/shared/integration/integration_helper"

describe "Resources with a no-op provider" do
  include IntegrationSupport

  context "with noop provider providing foo" do
    before(:context) do
      class NoOpFoo < Chef::Resource
        resource_name "hi_there"
        default_action :update
      end
      Chef::Provider::Noop.provides :hi_there
    end

    it "does not blow up a run with a noop'd resource" do
      recipe = converge do
        hi_there "blah" do
          action :update
        end
      end
      expect(recipe.logged_warnings).to eq ""
    end
  end
end
