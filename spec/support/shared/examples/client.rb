
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

  describe "setting node GUID" do
    let(:chef_guid_path) { "/tmp/chef_guid" }
    let(:chef_guid) { "test-test-test" }
    let(:metadata_file) { "data_collector_metadata.json" }
    let(:metadata_path) { Pathname.new(File.join(Chef::Config[:file_cache_path], metadata_file)).cleanpath.to_s }
    let(:file) { instance_double(File) }

    before do
      allow(File).to receive(:read).and_call_original
      Chef::Config[:chef_guid_path] = chef_guid_path
      Chef::Config[:chef_guid] = nil
    end

    it "loads from the config" do
      expect(File).to receive(:exists?).with(chef_guid_path).and_return(true)
      expect(File).to receive(:read).with(chef_guid_path).and_return(chef_guid)
      client.run
      expect(Chef::Config[:chef_guid]).to eql(chef_guid)
      expect(node.automatic_attrs[:chef_guid]).to eql(chef_guid)
    end

    it "loads from the data collector config" do
      expect(File).to receive(:exists?).with(chef_guid_path).and_return(false)
      expect(Chef::FileCache).to receive(:load).with(metadata_file).and_return("{\"node_uuid\": \"#{chef_guid}\"}")

      expect(File).to receive(:open).with(chef_guid_path, "w+").and_yield(file)
      expect(file).to receive(:write).with(chef_guid)

      client.run
      expect(Chef::Config[:chef_guid]).to eql(chef_guid)
      expect(node.automatic_attrs[:chef_guid]).to eql(chef_guid)
    end

    it "creates a new one" do
      expect(File).to receive(:exists?).with(chef_guid_path).and_return(false)
      expect(File).to receive(:exists?).with(metadata_path).and_return(false)

      expect(SecureRandom).to receive(:uuid).and_return(chef_guid).at_least(:once)

      # we'll try and write the generated UUID to the data collector too, and that's ok
      allow(File).to receive(:open).with(metadata_path, "w", 420)

      expect(File).to receive(:open).with(chef_guid_path, "w+").and_yield(file)
      expect(file).to receive(:write).with(chef_guid)

      client.run
      expect(Chef::Config[:chef_guid]).to eql(chef_guid)
      expect(node.automatic_attrs[:chef_guid]).to eql(chef_guid)
    end
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
