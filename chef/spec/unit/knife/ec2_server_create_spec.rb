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
  before(:each) do
    @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new()
    @knife_ec2_create.name_args = ['foo-name']
    @knife_ec2_create.initial_sleep_delay = 0
  end

  describe "run" do
    before do
      @ec2_connection = mock()
      @ec2_servers = mock()

      @new_ec2_server = mock()

      ec2_server_attribs = { :id => 'i-39382318',
                             :flavor_id => 'm1.small',
                             :image_id => 'ami-47241231',
                             :availability_zone => 'us-west-1',
                             :key_name => 'my_ssh_key',
                             :groups => ['group1', 'group2'],
                             :dns_name => 'ec2-75.101.253.10.compute-1.amazonaws.com',
                             :ip_address => '75.101.253.10',
                             :private_dns_name => 'ip-10-251-75-20.ec2.internal',
                             :private_ip_address => '10.251.75.20'
                           }

      ec2_server_attribs.each_pair do |attrib, value|
        @new_ec2_server.should_receive(attrib).at_least(:once).and_return(value)
      end

      @new_ec2_server.should_receive(:wait_for).and_return(true)

      @ec2_servers.should_receive(:create).and_return(@new_ec2_server)

      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)

      Fog::AWS::EC2.should_receive(:new).and_return(@ec2_connection)

      @knife_ec2_create.stub!(:puts)
      @knife_ec2_create.stub!(:print)

      @bootstrap = mock()
    end

    it "should set the bootstrap name_args to an array" do
      @bootstrap.should_receive(:name_args=) do |x|
        x.should be_a_kind_of(Array)
      end

      Chef::Knife::Bootstrap.should_receive(:new).once.and_return(@bootstrap)

      @bootstrap.should_receive(:config).at_least(:once).and_return({})
      @bootstrap.should_receive(:run)

      @knife_ec2_create.run
    end

    it "should retry to bootstrap if the ssh connection is refused" do
      @bootstrap.should_receive(:name_args=).twice

      Chef::Knife::Bootstrap.should_receive(:new).twice.and_return(@bootstrap)

      @bootstrap.should_receive(:config).at_least(:once).and_return({})
      @bootstrap.should_receive(:run).once.and_raise(Errno::ECONNREFUSED)
      @bootstrap.should_receive(:run).once

      @knife_ec2_create.run
    end

    it "should retry to bootstrap if the ssh connection times out" do
      @bootstrap.should_receive(:name_args=).twice

      Chef::Knife::Bootstrap.should_receive(:new).twice.and_return(@bootstrap)

      @bootstrap.should_receive(:config).at_least(:once).and_return({})
      @bootstrap.should_receive(:run).once.and_raise(Errno::ETIMEDOUT)
      @bootstrap.should_receive(:run).once

      @knife_ec2_create.run
    end
  end
end
