
require "spec_helper"

describe Chef::Resource::RestResource do
  let(:resource_instance_name) { "some_name" }
  let(:resource_name) { :rest_resource }

  let(:resource) do
    run_context = Chef::RunContext.new(Chef::Node.new, nil, nil)

    Chef::Resource::RestResource.new(resource_instance_name, run_context)
  end

  it "is a subclass of Chef::Resource" do
    expect(resource).to be_a_kind_of(Chef::Resource)
  end

  it "sets the default action as :configure" do
    expect(resource.action).to eql([:configure])
  end

  it "supports :configure action" do
    expect { resource.action :configure }.not_to raise_error
  end

  it "supports :delete action" do
    expect { resource.action :delete }.not_to raise_error
  end

  it "should mixin RestResourceDSL" do
    expect(resource.class.included_modules).to include(Chef::DSL::RestResource)
  end

  # TODO: how to test for target_mode support?
end
