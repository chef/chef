#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "knife_spec_helper"
require "chef/knife/core/bootstrap_context"

describe Chef::Knife::Core::BootstrapContext do
  let(:config) { { foo: :bar, color: true } }
  let(:run_list) { Chef::RunList.new("recipe[tmux]", "role[base]") }
  let(:chef_config) do
    {
      config_log_level: "info",
      config_log_location: "/tmp/log",
      validation_key: File.join(CHEF_SPEC_DATA, "ssl", "private_key.pem"),
      chef_server_url: "http://chef.example.com:4444",
      validation_client_name: "chef-validator-testing",
    }
  end

  let(:secret) { nil }

  subject(:bootstrap_context) { described_class.new(config, run_list, chef_config, secret) }

  it "initializes with Chef 11 parameters" do
    expect { described_class.new(config, run_list, chef_config) }.not_to raise_error
  end

  it "runs chef with the first-boot.json with no environment" do
    expect(bootstrap_context.start_chef).to eq "chef-client -j /etc/chef/first-boot.json"
  end

  describe "when in verbosity mode" do
    let(:config) { { verbosity: 2, color: true } }
    it "adds '-l debug' when verbosity is >= 2" do
      expect(bootstrap_context.start_chef).to eq "chef-client -j /etc/chef/first-boot.json -l debug"
    end
  end

  describe "when no color value has been set in config" do
    let(:config) { { color: false } }
    it "adds '--no-color' when color is false" do
      expect(bootstrap_context.start_chef).to eq "chef-client -j /etc/chef/first-boot.json --no-color"
    end
  end

  it "reads the validation key" do
    expect(bootstrap_context.validation_key).to eq IO.read(File.join(CHEF_SPEC_DATA, "ssl", "private_key.pem"))
  end

  it "generates the config file data" do
    expected = <<~EXPECTED
      chef_server_url  "http://chef.example.com:4444"
      validation_client_name "chef-validator-testing"
      log_level   :info
      log_location   "/tmp/log"
      # Using default node name (fqdn)
    EXPECTED
    expect(bootstrap_context.config_content).to eq expected
  end

  describe "when chef_license is set" do
    let(:chef_config) { { chef_license: "accept-no-persist" } }
    it "sets chef_license in the generated config file" do
      expect(bootstrap_context.config_content).to include("chef_license \"accept-no-persist\"")
    end
  end

  describe "when file_cache_path is set" do
    let(:chef_config) { { file_cache_path: "/home/opscode/cache" } }
    it "sets file_cache_path in the generated config file" do
      expect(bootstrap_context.config_content).to include("file_cache_path \"/home/opscode/cache\"")
    end
  end

  describe "when file_backup_path is set" do
    let(:chef_config) { { file_backup_path: "/home/opscode/backup" } }
    it "sets file_backup_path in the generated config file" do
      expect(bootstrap_context.config_content).to include("file_backup_path \"/home/opscode/backup\"")
    end
  end

  describe "alternate chef-client path" do
    let(:chef_config) { { chef_client_path: "/usr/local/bin/chef-client" } }
    it "runs chef-client from another path when specified" do
      expect(bootstrap_context.start_chef).to eq "/usr/local/bin/chef-client -j /etc/chef/first-boot.json"
    end
  end

  describe "validation key path that contains a ~" do
    let(:chef_config) { { validation_key: "~/my.key" } }
    it "reads the validation key when it contains a ~" do
      expect(File).to receive(:exist?).with(File.expand_path("my.key", ENV["HOME"])).and_return(true)
      expect(IO).to receive(:read).with(File.expand_path("my.key", ENV["HOME"]))
      bootstrap_context.validation_key
    end
  end

  describe "when an explicit node name is given" do
    let(:config) { { chef_node_name: "foobar.example.com" } }
    it "sets the node name in the client.rb" do
      expect(bootstrap_context.config_content).to match(/node_name "foobar\.example\.com"/)
    end
  end

  describe "when bootstrapping into a specific environment" do
    let(:config) { { environment: "prodtastic", color: true } }
    it "starts chef in the configured environment" do
      expect(bootstrap_context.start_chef).to eq("chef-client -j /etc/chef/first-boot.json -E prodtastic")
    end
  end

  describe "when tags are given" do
    let(:config) { { tags: [ "unicorn" ] } }
    it "adds the attributes to first_boot" do
      expect(Chef::JSONCompat.to_json(bootstrap_context.first_boot)).to eq(Chef::JSONCompat.to_json({ run_list: run_list, tags: ["unicorn"] }))
    end
  end

  describe "when JSON attributes are given" do
    let(:config) { { first_boot_attributes: { baz: :quux } } }
    it "adds the attributes to first_boot" do
      expect(Chef::JSONCompat.to_json(bootstrap_context.first_boot)).to eq(Chef::JSONCompat.to_json({ baz: :quux, run_list: run_list }))
    end
  end

  describe "when JSON attributes are NOT given" do
    it "sets first_boot equal to run_list" do
      expect(Chef::JSONCompat.to_json(bootstrap_context.first_boot)).to eq(Chef::JSONCompat.to_json({ run_list: run_list }))
    end
  end

  describe "when policy_name and policy_group are present in config" do

    let(:config) { { policy_name: "my_app_server", policy_group: "staging" } }

    it "includes them in the first_boot data and excludes run_list" do
      expect(Chef::JSONCompat.to_json(bootstrap_context.first_boot)).to eq(Chef::JSONCompat.to_json({ policy_name: "my_app_server", policy_group: "staging" }))
    end

  end

  describe "when an encrypted_data_bag_secret is provided" do
    let(:secret) { "supersekret" }
    it "reads the encrypted_data_bag_secret" do
      expect(bootstrap_context.encrypted_data_bag_secret).to eq "supersekret"
    end
  end

  describe "to support compatibility with existing templates" do
    it "sets the @config instance variable" do
      expect(bootstrap_context.instance_variable_get(:@config)).to eq config
    end

    it "sets the @run_list instance variable" do
      expect(bootstrap_context.instance_variable_get(:@run_list)).to eq run_list
    end
  end

  describe "ssl_verify_mode" do
    it "isn't set in the config_content by default" do
      expect(bootstrap_context.config_content).not_to include("ssl_verify_mode")
    end

    describe "when configured via the config hash" do
      let(:config) { { node_ssl_verify_mode: "none" } }

      it "uses the config value" do
        expect(bootstrap_context.config_content).to include("ssl_verify_mode :verify_none")
      end
    end
  end

  describe "fips mode" do
    before do
      chef_config[:fips] = true
    end

    it "sets fips mode in the client.rb" do
      expect(bootstrap_context.config_content).to match(/fips true/)
    end
  end

  describe "verify_api_cert" do
    it "isn't set in the config_content by default" do
      expect(bootstrap_context.config_content).not_to include("verify_api_cert")
    end

    describe "when configured via the config hash" do
      let(:config) { { node_verify_api_cert: true } }

      it "uses config value" do
        expect(bootstrap_context.config_content).to include("verify_api_cert true")
      end
    end
  end

  describe "#config_log_location" do
    context "when config_log_location is nil" do
      let(:chef_config) { { config_log_location: nil } }
      it "sets the default config_log_location  in the client.rb" do
        expect(bootstrap_context.get_log_location).to eq "STDOUT"
      end
    end

    context "when config_log_location is empty" do
      let(:chef_config) { { config_log_location: "" } }
      it "sets the default config_log_location  in the client.rb" do
        expect(bootstrap_context.get_log_location).to eq "STDOUT"
      end
    end

    context "when config_log_location is :win_evt" do
      let(:chef_config) { { config_log_location: :win_evt } }
      it "raise error when config_log_location is :win_evt " do
        expect { bootstrap_context.get_log_location }.to raise_error("The value :win_evt is not supported for config_log_location on Linux Platforms \n")
      end
    end

    context "when config_log_location is :syslog" do
      let(:chef_config) { { config_log_location: :syslog } }
      it "sets the config_log_location value as :syslog in the client.rb" do
        expect(bootstrap_context.get_log_location).to eq ":syslog"
      end
    end

    context "When config_log_location is STDOUT" do
      let(:chef_config) { { config_log_location: STDOUT } }
      it "Sets the config_log_location value as STDOUT in the client.rb" do
        expect(bootstrap_context.get_log_location).to eq "STDOUT"
      end
    end

    context "when config_log_location is STDERR" do
      let(:chef_config) { { config_log_location: STDERR } }
      it "sets the config_log_location value as STDERR  in the client.rb" do
        expect(bootstrap_context.get_log_location).to eq "STDERR"
      end
    end

    context "when config_log_location is a path" do
      let(:chef_config) { { config_log_location: "/tmp/ChefLogFile" } }
      it "sets the config_log_location path in the client.rb" do
        expect(bootstrap_context.get_log_location).to eq "\"/tmp/ChefLogFile\""
      end
    end

  end

  describe "#version_to_install" do
    context "when bootstrap_version is provided" do
      let(:config) { { bootstrap_version: "awesome" } }

      it "returns bootstrap_version" do
        expect(bootstrap_context.version_to_install).to eq "awesome"
      end
    end

    context "when bootstrap_version is not provided" do
      let(:config) { { channel: "stable" } }
      it "returns the currently running major version out of Chef::VERSION" do
        expect(bootstrap_context.version_to_install).to eq Chef::VERSION.split(".").first
      end
    end

    context "and channel is other than stable" do
      let(:config) { { channel: "unstable" } }
      it "returns the version string 'latest'" do
        expect(bootstrap_context.version_to_install).to eq "latest"
      end
    end
  end
end
