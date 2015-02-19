#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'spec_helper'
require 'chef/knife/core/bootstrap_context'

describe Chef::Knife::Core::BootstrapContext do
  let(:config) { {:foo => :bar} }
  let(:run_list) { Chef::RunList.new('recipe[tmux]', 'role[base]') }
  let(:chef_config) do
    {
      :validation_key => File.join(CHEF_SPEC_DATA, 'ssl', 'private_key.pem'),
      :chef_server_url => 'http://chef.example.com:4444',
      :validation_client_name => 'chef-validator-testing'
    }
  end

  let(:secret) { nil }

  subject(:bootstrap_context) { described_class.new(config, run_list, chef_config, secret) }

  it "initializes with Chef 11 parameters" do
    expect{described_class.new(config, run_list, chef_config)}.not_to raise_error
  end

  it "runs chef with the first-boot.json in the _default environment" do
    expect(bootstrap_context.start_chef).to eq "chef-client -j /etc/chef/first-boot.json -E _default"
  end

  describe "when in verbosity mode" do
    let(:config) { {:verbosity => 2} }
    it "adds '-l debug' when verbosity is >= 2" do
      expect(bootstrap_context.start_chef).to eq "chef-client -j /etc/chef/first-boot.json -l debug -E _default"
    end
  end

  it "reads the validation key" do
    expect(bootstrap_context.validation_key).to eq IO.read(File.join(CHEF_SPEC_DATA, 'ssl', 'private_key.pem'))
  end

  it "generates the config file data" do
    expected=<<-EXPECTED
log_location     STDOUT
chef_server_url  "http://chef.example.com:4444"
validation_client_name "chef-validator-testing"
# Using default node name (fqdn)
EXPECTED
    expect(bootstrap_context.config_content).to eq expected
  end

  it "does not set a default log_level" do
    expect(bootstrap_context.config_content).not_to match(/log_level/)
  end

  describe "alternate chef-client path" do
    let(:chef_config){ {:chef_client_path => '/usr/local/bin/chef-client'} }
    it "runs chef-client from another path when specified" do
      expect(bootstrap_context.start_chef).to eq "/usr/local/bin/chef-client -j /etc/chef/first-boot.json -E _default"
    end
  end

  describe "validation key path that contains a ~" do
    let(:chef_config){ {:validation_key => '~/my.key'} }
    it "reads the validation key when it contains a ~" do
      expect(File).to receive(:exist?).with(File.expand_path("my.key", ENV['HOME'])).and_return(true)
      expect(IO).to receive(:read).with(File.expand_path("my.key", ENV['HOME']))
      bootstrap_context.validation_key
    end
  end

  describe "when an explicit node name is given" do
    let(:config){ {:chef_node_name => 'foobar.example.com' }}
    it "sets the node name in the client.rb" do
      expect(bootstrap_context.config_content).to match(/node_name "foobar\.example\.com"/)
    end
  end

  describe "when bootstrapping into a specific environment" do
    let(:chef_config){ {:environment => "prodtastic"} }
    it "starts chef in the configured environment" do
      expect(bootstrap_context.start_chef).to eq('chef-client -j /etc/chef/first-boot.json -E prodtastic')
    end
  end

  describe "when JSON attributes are given" do
    let(:config) { {:first_boot_attributes => {:baz => :quux}} }
    it "adds the attributes to first_boot" do
      expect(Chef::JSONCompat.to_json(bootstrap_context.first_boot)).to eq(Chef::JSONCompat.to_json({:baz => :quux, :run_list => run_list}))
    end
  end

  describe "when JSON attributes are NOT given" do
    it "sets first_boot equal to run_list" do
      expect(Chef::JSONCompat.to_json(bootstrap_context.first_boot)).to eq(Chef::JSONCompat.to_json({:run_list => run_list}))
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

  describe "when a bootstrap_version is specified" do
    let(:chef_config) do
      {
        :knife => {:bootstrap_version => "11.12.4" }
      }
    end

    it "should send the full version to the installer" do
      expect(bootstrap_context.latest_current_chef_version_string).to eq("-v 11.12.4")
    end
  end

  describe "when a pre-release bootstrap_version is specified" do
    let(:chef_config) do
      {
        :knife => {:bootstrap_version => "11.12.4.rc.0" }
      }
    end

    it "should send the full version to the installer and set the pre-release flag" do
      expect(bootstrap_context.latest_current_chef_version_string).to eq("-v 11.12.4.rc.0 -p")
    end
  end

  describe "when a bootstrap_version is not specified" do
    it "should send the latest current to the installer" do
      # Intentionally hard coded in order not to replicate the logic.
      expect(bootstrap_context.latest_current_chef_version_string).to eq("-v #{Chef::VERSION.to_i}")
    end
  end

  describe "ssl_verify_mode" do
    it "isn't set in the config_content by default" do
      expect(bootstrap_context.config_content).not_to include("ssl_verify_mode")
    end

    describe "when configured in config" do
      let(:chef_config) do
        {
          :knife => {:ssl_verify_mode => :verify_peer}
        }
      end

      it "uses the config value" do
        expect(bootstrap_context.config_content).to include("ssl_verify_mode :verify_peer")
      end

      describe "when configured via CLI" do
        let(:config) {{:node_ssl_verify_mode => "none"}}

        it "uses CLI value" do
          expect(bootstrap_context.config_content).to include("ssl_verify_mode :verify_none")
        end
      end
    end
  end

  describe "verify_api_cert" do
    it "isn't set in the config_content by default" do
      expect(bootstrap_context.config_content).not_to include("verify_api_cert")
    end

    describe "when configured in config" do
      let(:chef_config) do
        {
          :knife => {:verify_api_cert => :false}
        }
      end

      it "uses the config value" do
        expect(bootstrap_context.config_content).to include("verify_api_cert false")
      end

      describe "when configured via CLI" do
        let(:config) {{:node_verify_api_cert => true}}

        it "uses CLI value" do
          expect(bootstrap_context.config_content).to include("verify_api_cert true")
        end
      end
    end
  end

  describe "prerelease" do
    it "isn't set in the config_content by default" do
      expect(bootstrap_context.config_content).not_to include("prerelease")
    end

    describe "when configured via cli" do
      let(:config) {{:prerelease => true}}

      it "uses CLI value" do
        expect(bootstrap_context.latest_current_chef_version_string).to eq("-p")
      end
    end
  end

end
