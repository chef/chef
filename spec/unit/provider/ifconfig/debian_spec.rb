#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

describe Chef::Provider::Ifconfig::Debian do

  let(:run_context) do
    node = Chef::Node.new
    cookbook_collection = Chef::CookbookCollection.new([])
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:new_resource) do
    new_resource = Chef::Resource::Ifconfig.new("10.0.0.1", run_context)
    new_resource.mask "255.255.254.0"
    new_resource.metric "1"
    new_resource.mtu "1500"
    new_resource.device "eth0"
    new_resource
  end

  let(:current_resource) {  Chef::Resource::Ifconfig.new("10.0.0.1", run_context) }

  let(:provider) do
    status = double("Status", :exitstatus => 0)
    provider = Chef::Provider::Ifconfig::Debian.new(new_resource, run_context)
    provider.instance_variable_set("@status", status)
    provider.current_resource = current_resource
    allow(provider).to receive(:load_current_resource)
    allow(provider).to receive(:run_command)
    provider
  end

  let(:config_filename_ifaces) { "/etc/network/interfaces" }

  let(:config_filename_ifcfg) { "/etc/network/interfaces.d/ifcfg-#{new_resource.device}" }

  describe "generate_config for action_add" do

    let(:config_file_ifaces) { StringIO.new }

    let(:config_file_ifcfg) { StringIO.new }

    before do
      expect(FileUtils).to receive(:cp)
      expect(File).to receive(:open).with(config_filename_ifaces).and_return(StringIO.new)
      expect(File).to receive(:open).with(config_filename_ifaces, "w").and_yield(config_file_ifaces)
      expect(File).to receive(:new).with(config_filename_ifcfg, "w").and_return(config_file_ifcfg)
      expect(File).to receive(:exist?).with(config_filename_ifaces).and_return(true)
    end

    it "should create network-scripts directory" do
      expect(File).to receive(:directory?).with(File.dirname(config_filename_ifcfg)).and_return(false)
      expect(Dir).to receive(:mkdir).with(File.dirname(config_filename_ifcfg))
      provider.run_action(:add)
    end

    it "should write configure network-scripts directory" do
      expect(File).to receive(:directory?).with(File.dirname(config_filename_ifcfg)).and_return(true)
      provider.run_action(:add)
      expect(config_file_ifaces.string).to match(/^\s*source\s+\/etc\/network\/interfaces[.]d\/[*]\s*$/)
    end

    it "should write a network-script" do
      expect(File).to receive(:directory?).with(File.dirname(config_filename_ifcfg)).and_return(true)
      provider.run_action(:add)
      expect(config_file_ifcfg.string).to match(/^iface eth0 inet static\s*$/)
      expect(config_file_ifcfg.string).to match(/^\s+address 10\.0\.0\.1\s*$/)
      expect(config_file_ifcfg.string).to match(/^\s+netmask 255\.255\.254\.0\s*$/)
    end
  end

  describe "delete_config for action_delete" do

    it "should delete network-script if it exists" do
      current_resource.device new_resource.device
      expect(File).to receive(:exist?).with(config_filename_ifcfg).and_return(true)
      expect(FileUtils).to receive(:rm_f).with(config_filename_ifcfg, :verbose => false)

      provider.run_action(:delete)
    end
  end
end
