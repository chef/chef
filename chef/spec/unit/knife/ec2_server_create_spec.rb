#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'fog'

describe Chef::Knife::Ec2ServerCreate do
  before do
    @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new()
    @knife_ec2_create.name_args = ['role[base]']
    @knife_ec2_create.initial_sleep_delay = 0
    @knife_ec2_create.stub!(:tcp_test_ssh).and_return(true)

    @ec2_connection = mock()
    @ec2_servers = mock()
    @new_ec2_server = mock()

    @ec2_server_attribs = { :id => 'i-39382318',
                           :flavor_id => 'm1.small',
                           :image_id => 'ami-47241231',
                           :availability_zone => 'us-west-1',
                           :key_name => 'my_ssh_key',
                           :groups => ['group1', 'group2'],
                           :dns_name => 'ec2-75.101.253.10.compute-1.amazonaws.com',
                           :ip_address => '75.101.253.10',
                           :private_dns_name => 'ip-10-251-75-20.ec2.internal',
                           :private_ip_address => '10.251.75.20' }

    @ec2_server_attribs.each_pair do |attrib, value|
      @new_ec2_server.stub!(attrib).and_return(value)
    end
  end

  describe "run" do
    before do
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @ec2_servers.should_receive(:create).and_return(@new_ec2_server)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)

      Fog::AWS::EC2.should_receive(:new).and_return(@ec2_connection)

      @knife_ec2_create.stub!(:puts)
      @knife_ec2_create.stub!(:print)

    end

    it "creates an EC2 instance and bootstraps it" do
      @bootstrap = Chef::Knife::Bootstrap.new
      Chef::Knife::Bootstrap.stub!(:new).and_return(@bootstrap)
      @bootstrap.should_receive(:run)
      @knife_ec2_create.run
    end

  end

  describe "when configuring the bootstrap process" do
    before do
      @knife_ec2_create.config[:ssh_user] = "ubuntu"
      @knife_ec2_create.config[:identity_file] = "~/.ssh/aws-key.pem"
      @knife_ec2_create.config[:chef_node_name] = "blarf"
      @knife_ec2_create.config[:template_file] = '~/.chef/templates/my-bootstrap.sh.erb'
      @knife_ec2_create.config[:distro] = 'ubuntu-10.04-magic-sparkles'

      @bootstrap = @knife_ec2_create.bootstrap_for_node(@new_ec2_server)
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server" do
      @bootstrap.name_args.should == ['ec2-75.101.253.10.compute-1.amazonaws.com']
    end

    it "configures sets the bootstrap's run_list" do
      @bootstrap.config[:run_list].should == ['role[base]']
    end

    it "configures the bootstrap to use the correct ssh_user login" do
      @bootstrap.config[:ssh_user].should == 'ubuntu'
    end

    it "configures the bootstrap to use the correct ssh identity file" do
      @bootstrap.config[:identity_file].should == "~/.ssh/aws-key.pem"
    end

    it "configures the bootstrap to use the configured node name if provided" do
      @bootstrap.config[:chef_node_name].should == 'blarf'
    end

    it "configures the bootstrap to use the EC2 server id if no explicit node name is set" do
      @knife_ec2_create.config[:chef_node_name] = nil

      bootstrap = @knife_ec2_create.bootstrap_for_node(@new_ec2_server)
      bootstrap.config[:chef_node_name].should == @new_ec2_server.id
    end

    it "configures the bootstrap to use prerelease versions of chef if specified" do
      @bootstrap.config[:prerelease].should be_false

      @knife_ec2_create.config[:prerelease] = true

      bootstrap = @knife_ec2_create.bootstrap_for_node(@new_ec2_server)
      bootstrap.config[:prerelease].should be_true
    end

    it "configures the bootstrap to use the desired distro-specific bootstrap script" do
      @bootstrap.config[:distro].should == 'ubuntu-10.04-magic-sparkles'
    end

    it "configures the bootstrap to use sudo" do
      @bootstrap.config[:use_sudo].should be_true
    end

    it "configured the bootstrap to use the desired template" do
      @bootstrap.config[:template_file].should == '~/.chef/templates/my-bootstrap.sh.erb'
    end
  end

end
