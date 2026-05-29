#
# Copyright:: Copyright (c) 2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#

require "spec_helper"
require "tmpdir"
require "chef-config/mixin/train_transport"

RSpec.describe ChefConfig::Mixin::TrainTransport do
  let(:logger) do
    instance_double(
      "Logger",
      warn: nil,
      debug: nil,
      trace: nil,
      error: nil
    )
  end

  let(:target_mode_config) do
    instance_double(
      "TargetModeConfig",
      host: "host.example.org",
      credentials_file: nil,
      protocol: "ssh",
      to_hash: { host: "host.example.org", protocol: "ssh" }
    )
  end

  let(:config) do
    instance_double(
      "Config",
      target_mode: target_mode_config,
      target_mode?: true,
      platform_specific_path: "/etc/chef/host.example.org/credentials"
    )
  end

  let(:test_class) do
    Class.new do
      include ChefConfig::Mixin::TrainTransport

      attr_reader :config

      def initialize(logger, config)
        super(logger)
        @config = config
      end
    end
  end

  subject(:test_obj) { test_class.new(logger, config) }

  describe "#contains_split_fqdn?" do
    it "returns the terminal hash when fqdn is represented as nested hashes" do
      nested = { "host" => { "example" => { "org" => {} } } }
      expect(test_obj.contains_split_fqdn?(nested, "host.example.org")).to eq({})
    end

    it "returns false when fqdn is not split" do
      normal = { "host.example.org" => { "user" => "admin" } }
      expect(test_obj.contains_split_fqdn?(normal, "host.example.org")).to be(false)
    end

    it "returns nil when profile does not look like fqdn" do
      expect(test_obj.contains_split_fqdn?({}, "localhost")).to be_nil
    end
  end

  describe "#load_credentials" do
    it "warns for split fqdn keys and returns symbolized credentials" do
      credentials = { "host.example.org" => { "user" => "admin", "port" => 22 } }
      allow(test_obj).to receive(:parse_credentials_file).and_return(credentials)
      allow(test_obj).to receive(:contains_split_fqdn?).and_return(true)
      allow(test_obj).to receive(:resolve_secrets)
      allow(test_obj).to receive(:credentials_file_path).and_return("/tmp/credentials.toml")

      expect(logger).to receive(:warn).with(/contains target 'host\.example\.org' as a Hash/)
      expect(logger).to receive(:warn).with(/Hostnames must be surrounded by single quotes/)

      expect(test_obj.load_credentials("host.example.org")).to eq(user: "admin", port: 22)
    end

    it "returns nil when the profile does not exist" do
      allow(test_obj).to receive(:parse_credentials_file).and_return({ "other" => { "user" => "admin" } })
      allow(test_obj).to receive(:contains_split_fqdn?).and_return(false)
      allow(test_obj).to receive(:resolve_secrets)

      expect(test_obj.load_credentials("host.example.org")).to be_nil
    end
  end

  describe "#credentials_file_path" do
    around do |example|
      old_env = ENV.to_hash
      begin
        ENV.delete("CHEF_CREDENTIALS_FILE")
        example.run
      ensure
        ENV.clear
        ENV.update(old_env)
      end
    end

    it "prefers CHEF_CREDENTIALS_FILE when it exists" do
      Dir.mktmpdir("train-cred") do |dir|
        env_file = File.join(dir, "credentials")
        File.write(env_file, "[default]\n")
        ENV["CHEF_CREDENTIALS_FILE"] = env_file

        expect(test_obj.credentials_file_path).to eq(env_file)
      end
    end

    it "raises when no candidate credentials file exists" do
      allow(config).to receive(:platform_specific_path).and_return("/nonexistent/system_credentials")
      allow(ChefConfig::PathHelper).to receive(:home).and_return(nil)

      expect { test_obj.credentials_file_path }.to raise_error(ArgumentError, /No credentials file found/)
    end
  end

  describe "#build_transport" do
    it "returns nil when target mode is disabled" do
      allow(config).to receive(:target_mode?).and_return(false)
      expect(test_obj.build_transport).to be_nil
    end
  end
end
