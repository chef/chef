#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'chef/exceptions'

describe Chef::Provider::Ifconfig::Aix do
  
  before(:all) do
    @ifconfig_output = <<-IFCONFIG
en1: flags=1e080863,480<UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),CHAIN>
        inet 10.153.11.59 netmask 0xffff0000 broadcast 10.153.255.255
         tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
en0: flags=1e080863,480<UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),CHAIN> metric 1
        inet 172.29.174.58 netmask 0xffffc000 broadcast 172.29.191.255
         tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
lo0: flags=e08084b,c0<UP,BROADCAST,LOOPBACK,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,LARGESEND,CHAIN>
        inet 127.0.0.1 netmask 0xff000000 broadcast 127.255.255.255
        inet6 ::1%1/0
IFCONFIG
  end


  before(:each) do
    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new([])
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @new_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)

    @provider = Chef::Provider::Ifconfig::Aix.new(@new_resource, @run_context)
  end

  describe "#load_current_resource" do 
    before do 
      status = double("Status", :exitstatus => 0)
      @provider.should_receive(:popen4).with("ifconfig -a").and_yield(@pid,@stdin,@ifconfig_output,@stderr).and_return(status)
      @new_resource.device "en0"
    end
    it "should load given interface with attributes." do
      current_resource = @provider.load_current_resource
      expect(current_resource.inet_addr).to eq("172.29.174.58")
      expect(current_resource.target).to eq(@new_resource.target)
      expect(current_resource.mask).to eq("255.255.192.0")
      expect(current_resource.bcast).to eq("172.29.191.255")
      expect(current_resource.metric).to eq("1")
    end
  end

  describe "#action_add" do

    it "should add an interface if it does not exist" do
      @new_resource.device "en10"
      @provider.stub!(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", :exitstatus => 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end
      command = "chdev -l #{@new_resource.device} -a netaddr=#{@new_resource.name}"
      @provider.should_receive(:run_command).with(:command => command)

      @provider.run_action(:add)
      @new_resource.should be_updated
    end

    context "VIP" do
      before do
        @provider.stub!(:load_current_resource) do
          @provider.instance_variable_set("@status", double("Status", :exitstatus => 0))
          current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
          current_resource.inet_addr '12.12.11.1'
          @provider.instance_variable_set("@current_resource", current_resource)
        end
        @new_resource.device "en0"
      end

      it "should add an VIP if interface already exists and is_vip is true" do
        @new_resource.is_vip true
        command = "chdev -l #{@new_resource.device} -a alias4=#{@new_resource.name}"
        @provider.should_receive(:run_command).with(:command => command)

        @provider.run_action(:add)
        @new_resource.should be_updated
      end


      it "should not add an VIP if is_vip is false" do
        @new_resource.is_vip false
        @provider.should_not_receive(:run_command)

        @provider.run_action(:add)
        @new_resource.should_not be_updated
      end
    end
  end

  describe "#action_enable" do

    it "should enable an interface if it does not exist" do
      @new_resource.device "en10"
      @provider.stub!(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", :exitstatus => 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end
      command = "ifconfig #{@new_resource.device} #{@new_resource.name}"
      @provider.should_receive(:run_command).with(:command => command)

      @provider.run_action(:enable)
      @new_resource.should be_updated
    end

    context "VIP" do
      before do
        @provider.stub!(:load_current_resource) do
          @provider.instance_variable_set("@status", double("Status", :exitstatus => 0))
          current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
          current_resource.inet_addr '12.12.11.1'
          @provider.instance_variable_set("@current_resource", current_resource)
        end
        @new_resource.device "en0"
      end

      it "should enable an VIP if interface already exists and is_vip is true" do
        @new_resource.is_vip true
        command = "ifconfig #{@new_resource.device} inet #{@new_resource.name} alias"
        @provider.should_receive(:run_command).with(:command => command)

        @provider.run_action(:enable)
        @new_resource.should be_updated
      end


      it "should not add an VIP if is_vip is false" do
        @new_resource.is_vip false
        @provider.should_not_receive(:run_command)

        @provider.run_action(:enable)
        @new_resource.should_not be_updated
      end
    end
  end

  describe "#action_disable" do

    it "should not disable an interface if it does not exist" do
      @new_resource.device "en10"
      @provider.stub!(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", :exitstatus => 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end

      @provider.should_not_receive(:run_command)

      @provider.run_action(:disable)
      @new_resource.should_not be_updated
    end

    context "interface exists" do
      before do
        @new_resource.device "en10"
        @provider.stub!(:load_current_resource) do
          @provider.instance_variable_set("@status", double("Status", :exitstatus => 0))
          current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
          current_resource.device @new_resource.device
          @provider.instance_variable_set("@current_resource", current_resource)
        end
      end

      it "should disable an interface if it exists" do
        command = "ifconfig #{@new_resource.device} down"
        @provider.should_receive(:run_command).with(:command => command)

        @provider.run_action(:disable)
        @new_resource.should be_updated
      end

      it "should disable VIP" do
        @new_resource.is_vip true
        command = "ifconfig #{@new_resource.device} inet 10.0.0.1 delete"
        @provider.should_receive(:run_command).with(:command => command)

        @provider.run_action(:disable)
        @new_resource.should be_updated
      end
    end
  end

end