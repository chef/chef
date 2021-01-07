require "spec_helper"

describe Chef::Resource::HomebrewUpdate do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::HomebrewUpdate.new("update", run_context) }

  let(:stamp_dir) { Dir.mktmpdir("brew_update_periodic") }
  let(:stamp_file) { Dir.mktmpdir("apt_update_periodic") }
  let(:brew_update_cmd) { %w{homebrew update} }

  it "sets the default action as :periodic" do
    expect(resource.action).to eql([:periodic])
  end

  it "supports :periodic, :update actions" do
    expect { resource.action :periodic }.not_to raise_error
    expect { resource.action :update }.not_to raise_error
  end

  it "default frequency is set to be 1 da1y" do
    expect(resource.frequency).to eql(86_400)
  end

  it "frequency accepts integers" do
    resource.frequency(400)
    expect(resource.frequency).to eql(400)
  end
end
