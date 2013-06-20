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
  before do
    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new([])
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    #This new_resource can be called anything --> it is not the same as in ifconfig.rb
    @new_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)
    @new_resource.mask "255.255.254.0"
    @new_resource.metric "1"
    @new_resource.mtu "1500"
    @new_resource.device "eth0"
    @provider = Chef::Provider::Ifconfig::Debian.new(@new_resource, @run_context)
    @current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)

    status = mock("Status", :exitstatus => 0)
    @provider.instance_variable_set("@status", status)
    @provider.current_resource = @current_resource
    @provider.stub!(:load_current_resource)
    @provider.stub!(:run_command)

    @config_filename_ifaces = "/etc/network/interfaces"
    @config_filename_ifcfg = "/etc/network/interfaces.d/ifcfg-#{@new_resource.device}"
  end

  describe "generate_config for action_add" do
   before do
    @config_file_ifaces = StringIO.new
    @config_file_ifcfg = StringIO.new
    FileUtils.should_receive(:cp)
    File.should_receive(:new).with(@config_filename_ifaces).and_return(StringIO.new)
    File.should_receive(:open).with(@config_filename_ifaces, "w").and_yield(@config_file_ifaces)
    File.should_receive(:new).with(@config_filename_ifcfg, "w").and_return(@config_file_ifcfg)
    File.should_receive(:exist?).with(@config_filename_ifaces).and_return(true)
   end

   it "should create network-scripts directory" do
    File.should_receive(:directory?).with(File.dirname(@config_filename_ifcfg)).and_return(false)
    Dir.should_receive(:mkdir).with(File.dirname(@config_filename_ifcfg))
    @provider.run_action(:add)
   end

   it "should write configure network-scripts directory" do
    File.should_receive(:directory?).with(File.dirname(@config_filename_ifcfg)).and_return(true)
    @provider.run_action(:add)
    @config_file_ifaces.string.should match(/^\s*source\s+\/etc\/network\/interfaces[.]d\/[*]\s*$/)
   end

   it "should write a network-script" do
    File.should_receive(:directory?).with(File.dirname(@config_filename_ifcfg)).and_return(true)
    @provider.run_action(:add)
    @config_file_ifcfg.string.should match(/^iface eth0 inet static\s*$/)
    @config_file_ifcfg.string.should match(/^\s+address 10\.0\.0\.1\s*$/)
    @config_file_ifcfg.string.should match(/^\s+netmask 255\.255\.254\.0\s*$/)
   end
  end

  describe "delete_config for action_delete" do

    it "should delete network-script if it exists" do
      @current_resource.device @new_resource.device
      File.should_receive(:exist?).with(@config_filename_ifcfg).and_return(true)
      FileUtils.should_receive(:rm_f).with(@config_filename_ifcfg, :verbose => false)

      @provider.run_action(:delete)
    end
  end
end
