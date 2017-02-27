require "support/shared/integration/integration_helper"

describe "Recipe DSL methods" do
  include IntegrationSupport

  context "With resource class providing 'provider_thingy'" do
    before :context do
      class Chef::Resource::ProviderThingy < Chef::Resource
        resource_name :provider_thingy
        default_action :create
        def to_s
          "provider_thingy resource class"
        end
      end
    end
    context "And class Chef::Provider::ProviderThingy with no provides" do
      before :context do
        class Chef::Provider::ProviderThingy < Chef::Provider
          def load_current_resource
          end

          def action_create
            Chef::Log.warn("hello from #{self.class.name}")
          end
        end
      end

      it "provider_thingy 'blah' runs the provider and warns" do
        recipe = converge do
          provider_thingy("blah") {}
        end
        expect(recipe.logged_warnings).to match /hello from Chef::Provider::ProviderThingy/
        expect(recipe.logged_warnings).to match /you must use 'provides' to provide DSL/i
      end
    end
  end
end
