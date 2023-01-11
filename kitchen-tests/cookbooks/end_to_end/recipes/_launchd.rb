#
# Cookbook:: end_to_end
# Recipe:: launchd
#

require "spec_helper"

file "/Library/LaunchDaemons/io.chef.testing.fake.plist" do
  path "io.chef.testing.fake.plist"
  mode "644"
end

launchd "io.chef.testing.fake" do
  source "io.chef.testing.fake"
end

describe "launchd" do
  context "Run on Amazon Linux" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: "amazon", version: "2") do |node|
        node.normal["launchd"]["label"] = "io.chef.testing.fake"
        node.normal["launchd"]["program_arguments"] = "/usr/local/bin/binary"
        node.normal["launchd"]["run_at_load"] = true
        node.normal["launchd"]["associated_bundle_identifiers"] = [
          "io.chef.testing.fake",
        ]
        node.normal["launchd"]["start_calendar_interval"] = [
          {
            "Minute" => 0,
          },
          {
            "Minute" => 30,
          },
        ],
        node.normal["launchd"]["type"] = "agent"
      end.converge(described_recipe)
    end

    it "raises an exception" do
      expect { chef_run }.to raise_error(Chef::Exceptions::UnsupportedPlatform, /launchd can only be run on macOS/)
    end
  end
end