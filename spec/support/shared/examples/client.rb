
require "spec_helper"
require "spec/support/shared/context/client"

# requires platform and platform_version be defined
shared_examples "a completed run" do
  include_context "run completed"

  it "runs ohai, sets up authentication, loads node state, synchronizes policy, converges, and runs audits" do
    # This is what we're testing.
    expect(client.run).to be true

    # fork is stubbed, so we can see the outcome of the run
    expect(node.automatic_attrs[:platform]).to eq(platform)
    expect(node.automatic_attrs[:platform_version]).to eq(platform_version)
  end
end

shared_examples "a completed run with audit failure" do
  include_context "run completed"

  before do
    expect(Chef::Application).to receive(:debug_stacktrace).with an_instance_of(Chef::Exceptions::RunFailedWrappingError)
  end

  it "converges, runs audits, saves the node and raises the error in a wrapping error" do
    expect { client.run }.to raise_error(Chef::Exceptions::RunFailedWrappingError) do |error|
      expect(error.wrapped_errors.size).to eq(run_errors.size)
      run_errors.each do |run_error|
        expect(error.wrapped_errors).to include(run_error)
        expect(error.backtrace).to include(*run_error.backtrace)
      end
    end

    # fork is stubbed, so we can see the outcome of the run
    expect(node.automatic_attrs[:platform]).to eq(platform)
    expect(node.automatic_attrs[:platform_version]).to eq(platform_version)
  end
end

shared_examples "a failed run" do
  include_context "run failed"

  it "skips node save and raises the error in a wrapping error" do
    expect { client.run }.to raise_error(Chef::Exceptions::RunFailedWrappingError) do |error|
      expect(error.wrapped_errors.size).to eq(run_errors.size)
      run_errors.each do |run_error|
        expect(error.wrapped_errors).to include(run_error)
        expect(error.backtrace).to include(*run_error.backtrace)
      end
    end
  end
end
