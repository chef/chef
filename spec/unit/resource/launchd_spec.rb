#

require "spec_helper"

describe Chef::Resource::Launchd do
  @launchd = Chef::Resource::Launchd.new("io.chef.chef-client")
  let(:resource) do
    Chef::Resource::Launchd.new(
    "io.chef.chef-client",
    run_context
  ) end

  it "should create a new Chef::Resource::Launchd" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Launchd)
  end

  it "should have a resource name of Launchd" do
    expect(resource.resource_name).to eql(:launchd)
  end

  it "should have a default action of create" do
    expect(resource.action).to eql([:create])
  end

  it "should accept enable, disable, create, and delete as actions" do
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end
end
