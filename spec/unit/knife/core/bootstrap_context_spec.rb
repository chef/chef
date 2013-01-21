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
  before do
    @config = {:foo => :bar}
    @run_list = Chef::RunList.new('recipe[tmux]', 'role[base]')
    @chef_config = {:validation_key => File.join(CHEF_SPEC_DATA, 'ssl', 'private_key.pem')}
    @chef_config[:chef_server_url] = 'http://chef.example.com:4444'
    @chef_config[:validation_client_name] = 'chef-validator-testing'
    @context = Chef::Knife::Core::BootstrapContext.new(@config, @run_list, @chef_config)
  end

  describe "to support compatability with existing templates" do
    it "sets the @config instance variable" do
      @context.instance_eval { @config }.should == {:foo => :bar}
    end

    it "sets the @run_list instance variable" do
      @context.instance_eval { @run_list }.should equal(@run_list)
    end
  end

  it "installs the same version of chef on the remote host" do
    @context.bootstrap_version_string.should == "--version #{Chef::VERSION}"
  end

  it "runs chef with the first-boot.json in the _default environment" do
    @context.start_chef.should == "chef-client -j /etc/chef/first-boot.json -E _default"
  end

  it "it runs chef-client from another path when specified" do
    @chef_config[:chef_client_path] = '/usr/local/bin/chef-client'
    @context.start_chef.should == "/usr/local/bin/chef-client -j /etc/chef/first-boot.json -E _default"
  end

  it "reads the validation key" do
    @context.validation_key.should == IO.read(File.join(CHEF_SPEC_DATA, 'ssl', 'private_key.pem'))
  end

  it "reads the validation key when it contains a ~" do
    IO.should_receive(:read).with(File.expand_path("my.key", ENV['HOME']))
    @chef_config = {:validation_key => '~/my.key'}
    @context = Chef::Knife::Core::BootstrapContext.new(@config, @run_list, @chef_config)
    @context.validation_key
  end

  it "generates the config file data" do
    expected=<<-EXPECTED
log_level        :auto
log_location     STDOUT
chef_server_url  "http://chef.example.com:4444"
validation_client_name "chef-validator-testing"
# Using default node name (fqdn)
EXPECTED
    @context.config_content.should == expected
  end

  describe "when an explicit node name is given" do
    before do
      @config[:chef_node_name] = 'foobar.example.com'
    end
    it "sets the node name in the client.rb" do
      @context.config_content.should match(/node_name "foobar\.example\.com"/)
    end
  end

  describe "when bootstrapping into a specific environment" do
    before do
      @chef_config[:environment] = "prodtastic"
    end

    it "starts chef in the configured environment" do
      @context.start_chef.should == 'chef-client -j /etc/chef/first-boot.json -E prodtastic'
    end
  end

  describe "when installing a prerelease version of chef" do
    before do
      @config[:prerelease] = true
    end
    it "supplies --prerelease as the version string" do
      @context.bootstrap_version_string.should == '--prerelease'
    end
  end

  describe "when installing an explicit version of chef" do
    before do
      @context = Chef::Knife::Core::BootstrapContext.new(@config, @run_list, :knife => { :bootstrap_version => '123.45.678' })
    end

    it "gives --version $VERSION as the version string" do
      @context.bootstrap_version_string.should == '--version 123.45.678'
    end
  end
  
  describe "when JSON attributes are given" do
    before do
      conf = @config.dup
      conf[:first_boot_attributes] = {:baz => :quux}
      @context = Chef::Knife::Core::BootstrapContext.new(conf, @run_list, @chef_config)
    end

    it "adds the attributes to first_boot" do
      @context.first_boot.to_json.should == {:baz => :quux, :run_list => @run_list}.to_json
    end
  end
  
  describe "when JSON attributes are NOT given" do
    it "sets first_boot equal to run_list" do
      @context.first_boot.to_json.should == {:run_list => @run_list}.to_json
    end
  end
  
  
end

