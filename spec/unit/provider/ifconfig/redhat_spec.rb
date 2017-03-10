#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright 2013-2016, Onddo Labs, SL.
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

describe Chef::Provider::Ifconfig::Redhat do
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
    @provider = Chef::Provider::Ifconfig::Redhat.new(@new_resource, @run_context)
    @current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)

    status = double("Status", exitstatus: 0)
    @provider.instance_variable_set("@status", status)
    @provider.current_resource = @current_resource

    config_filename = "/etc/sysconfig/network-scripts/ifcfg-#{@new_resource.device}"
    @config = double("chef-resource-file")
    expect(@provider).to receive(:resource_for_config).with(config_filename).and_return(@config)
  end

  describe "generate_config for action_add" do

    it "should write network-script for centos" do
      allow(@provider).to receive(:load_current_resource)
      allow(@provider).to receive(:shell_out!)
      expect(@config).to receive(:content) do |arg|
        expect(arg).to match(/^\s*DEVICE=eth0\s*$/)
        expect(arg).to match(/^\s*IPADDR=10\.0\.0\.1\s*$/)
        expect(arg).to match(/^\s*NETMASK=255\.255\.254\.0\s*$/)
      end
      expect(@config).to receive(:run_action).with(:create)
      expect(@config).to receive(:updated?).and_return(true)
      @provider.run_action(:add)
    end
  end

  describe "delete_config for action_delete" do

    it "should delete network-script if it exists for centos" do
      @current_resource.device @new_resource.device
      allow(@provider).to receive(:load_current_resource)
      allow(@provider).to receive(:shell_out!)
      expect(@config).to receive(:run_action).with(:delete)
      expect(@config).to receive(:updated?).and_return(true)
      @provider.run_action(:delete)
    end
  end
end
