require "support/shared/integration/integration_helper"
require "chef/formatters/doc"

describe "Resource validation is aware of action context" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.expand_path("../../..", __dir__) }
  let(:chef_client) { "bundle exec #{ChefUtils::Dist::Infra::CLIENT} --minimal-ohai --always-dump-stacktrace" }

  context "With a resource that requires a 'command' property but only for :create" do
    class Chef::Resource::FakeResource1 < Chef::Resource
      provides :fake_resource1
      property :command, String, required: [:create]
      allowed_actions [:create, :delete]
      default_action :create
      action :create do; end
      action :delete do; end
    end

    let(:foo_recipe_action_create_correct) do
      converge do
        fake_resource1 "foobar_create_correct" do
          command "foobar_command3"
          action :create
        end
      end
    end

    let(:foo_recipe_action_create_broken) do
      converge do
        fake_resource1 "foobar_create_broken" do
          action :create
        end
      end
    end

    let(:foo_recipe_action_delete) do
      converge do
        fake_resource1 "foobar_delete" do
          action :delete
        end
      end
    end

    context "when :create action is used with required the 'command' property" do
      it "passes validation" do
        expect { foo_recipe_action_create_correct.resources.first }.not_to raise_error
      end
    end

    context "when :delete action is used without the 'command' property" do
      it "passes validation" do
        expect { foo_recipe_action_delete.resources.first }.not_to raise_error
      end
    end

    context "when :create action is used without the 'command' property" do
      it "raises a validation error" do
        expect { foo_recipe_action_create_broken.resources.first }.to \
          raise_error(Chef::Exceptions::ValidationFailed)
      end
    end
  end
end
