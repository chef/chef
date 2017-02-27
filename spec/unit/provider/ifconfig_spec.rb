#
# Author:: Prajakta Purohit (prajakta@chef.io)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

# require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require "spec_helper"
require "chef/exceptions"

describe Chef::Provider::Ifconfig do
  before do
    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new([])
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    # This new_resource can be called anything --> it is not the same as in ifconfig.rb
    @new_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
    @new_resource.mask "255.255.254.0"
    @new_resource.metric "1"
    @new_resource.mtu "1500"
    @new_resource.device "eth0"
    @provider = Chef::Provider::Ifconfig.new(@new_resource, @run_context)
    @current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)

    status = double("Status", exitstatus: 0)
    @provider.instance_variable_set("@status", status)
    @provider.current_resource = @current_resource

  end
  describe Chef::Provider::Ifconfig, "load_current_resource" do
    before do
      @status = double(stdout: "", exitstatus: 1)
      allow(@provider).to receive(:shell_out).and_return(@status)
      @provider.load_current_resource
    end
    it "should track state of ifconfig failure" do
      expect(@provider.instance_variable_get("@status").exitstatus).not_to eq(0)
    end
    it "should thrown an exception when ifconfig fails" do
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error Chef::Exceptions::Ifconfig
    end
  end
  describe Chef::Provider::Ifconfig, "action_add" do

    it "should add an interface if it does not exist" do
      allow(@provider).to receive(:load_current_resource)
      @current_resource.inet_addr nil
      command = "ifconfig eth0 10.0.0.1 netmask 255.255.254.0 metric 1 mtu 1500"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))
      expect(@provider).to receive(:generate_config)

      @provider.run_action(:add)
      expect(@new_resource).to be_updated
    end

    it "should set the address to target if specified" do
      allow(@provider).to receive(:load_current_resource)
      @new_resource.target "172.16.32.2"
      command = "ifconfig eth0 172.16.32.2 netmask 255.255.254.0 metric 1 mtu 1500"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))

      @provider.run_action(:add)
      expect(@new_resource).to be_updated
    end

    it "should not add an interface if it already exists" do
      allow(@provider).to receive(:load_current_resource)
      expect(@provider).not_to receive(:shell_out!)
      @current_resource.inet_addr "10.0.0.1"
      expect(@provider).to receive(:generate_config)

      @provider.run_action(:add)
      expect(@new_resource).not_to be_updated
    end

    # We are not testing this case with the assumption that anyone writing the cookbook would not make a typo == lo
    # it "should add a blank command if the #{@new_resource.device} == lo" do
    # end
  end

  describe Chef::Provider::Ifconfig, "action_enable" do

    it "should enable interface if it does not exist" do
      allow(@provider).to receive(:load_current_resource)
      @current_resource.inet_addr nil
      command = "ifconfig eth0 10.0.0.1 netmask 255.255.254.0 metric 1 mtu 1500"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))
      expect(@provider).not_to receive(:generate_config)

      @provider.run_action(:enable)
      expect(@new_resource).to be_updated
    end

    it "should set the address to target if specified" do
      allow(@provider).to receive(:load_current_resource)
      @new_resource.target "172.16.32.2"
      command = "ifconfig eth0 172.16.32.2 netmask 255.255.254.0 metric 1 mtu 1500"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))

      @provider.run_action(:enable)
      expect(@new_resource).to be_updated
    end

    it "should not enable interface if it already exists" do
      allow(@provider).to receive(:load_current_resource)
      expect(@provider).not_to receive(:run_command)
      @current_resource.inet_addr "10.0.0.1"
      expect(@provider).not_to receive(:generate_config)

      @provider.run_action(:enable)
      expect(@new_resource).not_to be_updated
    end
  end

  describe Chef::Provider::Ifconfig, "action_delete" do

    it "should delete interface if it exists" do
      allow(@provider).to receive(:load_current_resource)
      @current_resource.device "eth0"
      command = "ifconfig #{@new_resource.device} down"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))
      expect(@provider).to receive(:delete_config)

      @provider.run_action(:delete)
      expect(@new_resource).to be_updated
    end

    it "should not delete interface if it does not exist" do
      allow(@provider).to receive(:load_current_resource)
      expect(@provider).not_to receive(:shell_out!)
      expect(@provider).to receive(:delete_config)

      @provider.run_action(:delete)
      expect(@new_resource).not_to be_updated
    end
  end

  describe Chef::Provider::Ifconfig, "action_disable" do

    it "should disable interface if it exists" do
      allow(@provider).to receive(:load_current_resource)
      @current_resource.device "eth0"
      command = "ifconfig #{@new_resource.device} down"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))
      expect(@provider).not_to receive(:delete_config)

      @provider.run_action(:disable)
      expect(@new_resource).to be_updated
    end

    it "should not delete interface if it does not exist" do
      allow(@provider).to receive(:load_current_resource)
      expect(@provider).not_to receive(:shell_out!)
      expect(@provider).not_to receive(:delete_config)

      @provider.run_action(:disable)
      expect(@new_resource).not_to be_updated
    end
  end

  describe Chef::Provider::Ifconfig, "action_delete" do

    it "should delete interface of it exists" do
      allow(@provider).to receive(:load_current_resource)
      @current_resource.device "eth0"
      command = "ifconfig #{@new_resource.device} down"
      expect(@provider).to receive(:shell_out!).with(*command.split(" "))
      expect(@provider).to receive(:delete_config)

      @provider.run_action(:delete)
      expect(@new_resource).to be_updated
    end

    it "should not delete interface if it does not exist" do
      # This is so that our fake values do not get overwritten
      allow(@provider).to receive(:load_current_resource)
      # This is so that nothing actually runs
      expect(@provider).not_to receive(:shell_out!)
      expect(@provider).to receive(:delete_config)

      @provider.run_action(:delete)
      expect(@new_resource).not_to be_updated
    end
  end
end
