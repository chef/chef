#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "spec_helper"
require "chef/exceptions"

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
      @status = double(stdout: @ifconfig_output, exitstatus: 0)
      allow(@provider).to receive(:shell_out).and_return(@status)
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
      allow(@provider).to receive(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end
      command = "chdev -l #{@new_resource.device} -a netaddr=#{@new_resource.name}"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))

      @provider.run_action(:add)
      expect(@new_resource).to be_updated
    end

    it "should raise exception if metric attribute is set" do
      @new_resource.device "en0"
      @new_resource.metric "1"
      allow(@provider).to receive(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end

      expect { @provider.run_action(:add) }.to raise_error(Chef::Exceptions::Ifconfig, "interface metric attribute cannot be set for :add action")
    end
  end

  describe "#action_enable" do
    it "should enable an interface if it does not exist" do
      @new_resource.device "en10"
      allow(@provider).to receive(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end
      command = "ifconfig #{@new_resource.device} #{@new_resource.name}"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))

      @provider.run_action(:enable)
      expect(@new_resource).to be_updated
    end
  end

  describe "#action_disable" do

    it "should not disable an interface if it does not exist" do
      @new_resource.device "en10"
      allow(@provider).to receive(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end

      expect(@provider).not_to receive(:shell_out!)

      @provider.run_action(:disable)
      expect(@new_resource).not_to be_updated
    end

    context "interface exists" do
      before do
        @new_resource.device "en10"
        allow(@provider).to receive(:load_current_resource) do
          @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
          current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
          current_resource.device @new_resource.device
          @provider.instance_variable_set("@current_resource", current_resource)
        end
      end

      it "should disable an interface if it exists" do
        command = "ifconfig #{@new_resource.device} down"
        expect(@provider).to receive(:shell_out!).with(*command.split(" "))

        @provider.run_action(:disable)
        expect(@new_resource).to be_updated
      end

    end
  end

  describe "#action_delete" do

    it "should not delete an interface if it does not exist" do
      @new_resource.device "en10"
      allow(@provider).to receive(:load_current_resource) do
        @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
        @provider.instance_variable_set("@current_resource", Chef::Resource::Ifconfig.new("10.0.0.1", @run_context))
      end

      expect(@provider).not_to receive(:shell_out!)

      @provider.run_action(:delete)
      expect(@new_resource).not_to be_updated
    end

    context "interface exists" do
      before do
        @new_resource.device "en10"
        allow(@provider).to receive(:load_current_resource) do
          @provider.instance_variable_set("@status", double("Status", exitstatus: 0))
          current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
          current_resource.device @new_resource.device
          @provider.instance_variable_set("@current_resource", current_resource)
        end
      end

      it "should delete an interface if it exists" do
        command = "chdev -l #{@new_resource.device} -a state=down"
        expect(@provider).to receive(:shell_out!).with(*command.split(" "))

        @provider.run_action(:delete)
        expect(@new_resource).to be_updated
      end
    end
  end
end
