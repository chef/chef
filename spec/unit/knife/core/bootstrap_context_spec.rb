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
  let(:secret_file) { File.join(CHEF_SPEC_DATA, 'bootstrap', 'encrypted_data_bag_secret') }

  subject(:bootstrap_context) { described_class.new(config, run_list, chef_config) }

  it "installs the same version of chef on the remote host" do
    bootstrap_context.bootstrap_version_string.should eq "--version #{Chef::VERSION}"
  end

  it "runs chef with the first-boot.json in the _default environment" do
    bootstrap_context.start_chef.should eq "chef-client -j /etc/chef/first-boot.json -E _default"
  end

  it "reads the validation key" do
    bootstrap_context.validation_key.should eq IO.read(File.join(CHEF_SPEC_DATA, 'ssl', 'private_key.pem'))
  end

  it "generates the config file data" do
    expected=<<-EXPECTED
log_level        :auto
log_location     STDOUT
chef_server_url  "http://chef.example.com:4444"
validation_client_name "chef-validator-testing"
# Using default node name (fqdn)
EXPECTED
    bootstrap_context.config_content.should eq expected
  end

  describe "alternate chef-client path" do
    let(:chef_config){ {:chef_client_path => '/usr/local/bin/chef-client'} }
    it "runs chef-client from another path when specified" do
      bootstrap_context.start_chef.should eq "/usr/local/bin/chef-client -j /etc/chef/first-boot.json -E _default"
    end
  end

  describe "validation key path that contains a ~" do
    let(:chef_config){ {:validation_key => '~/my.key'} }
    it "reads the validation key when it contains a ~" do
      IO.should_receive(:read).with(File.expand_path("my.key", ENV['HOME']))
      bootstrap_context.validation_key
    end
  end

  describe "when an explicit node name is given" do
    let(:config){ {:chef_node_name => 'foobar.example.com' }}
    it "sets the node name in the client.rb" do
      bootstrap_context.config_content.should match(/node_name "foobar\.example\.com"/)
    end
  end

  describe "when bootstrapping into a specific environment" do
    let(:chef_config){ {:environment => "prodtastic"} }
    it "starts chef in the configured environment" do
      bootstrap_context.start_chef.should == 'chef-client -j /etc/chef/first-boot.json -E prodtastic'
    end
  end

  describe "when installing a prerelease version of chef" do
    let(:config){ {:prerelease => true }}
    it "supplies --prerelease as the version string" do
      bootstrap_context.bootstrap_version_string.should eq '--prerelease'
    end
  end

  describe "when installing an explicit version of chef" do
    let(:chef_config) do
      {
        :knife => { :bootstrap_version => '123.45.678' }
      }
    end
    it "gives --version $VERSION as the version string" do
      bootstrap_context.bootstrap_version_string.should eq '--version 123.45.678'
    end
  end

  describe "when JSON attributes are given" do
    let(:config) { {:first_boot_attributes => {:baz => :quux}} }
    it "adds the attributes to first_boot" do
      bootstrap_context.first_boot.to_json.should eq({:baz => :quux, :run_list => run_list}.to_json)
    end
  end

  describe "when JSON attributes are NOT given" do
    it "sets first_boot equal to run_list" do
      bootstrap_context.first_boot.to_json.should eq({:run_list => run_list}.to_json)
    end
  end

  describe "when an encrypted_data_bag_secret is provided" do
    context "via config[:secret]" do
      let(:config){ {:secret => "supersekret" }}
      it "reads the encrypted_data_bag_secret" do
        bootstrap_context.encrypted_data_bag_secret.should eq "supersekret"
      end
    end

    context "via config[:secret_file]" do
      let(:config){ {:secret_file =>  secret_file}}
      it "reads the encrypted_data_bag_secret" do
        bootstrap_context.encrypted_data_bag_secret.should eq IO.read(secret_file)
      end
    end
  end

  describe "to support compatibility with existing templates" do
    it "sets the @config instance variable" do
      bootstrap_context.instance_variable_get(:@config).should eq config
    end

    it "sets the @run_list instance variable" do
      bootstrap_context.instance_variable_get(:@run_list).should eq run_list
    end

    describe "accepts encrypted_data_bag_secret via Chef::Config" do
      let(:chef_config) { {:encrypted_data_bag_secret => secret_file }}
      it "reads the encrypted_data_bag_secret" do
        bootstrap_context.encrypted_data_bag_secret.should eq IO.read(secret_file)
      end
    end
  end
end

