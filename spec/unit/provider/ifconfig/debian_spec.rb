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

    status = double("Status", :exitstatus => 0)
    @provider.instance_variable_set("@status", status)
    @provider.current_resource = @current_resource
    @provider.stub(:load_current_resource)
    @provider.stub(:run_command)

    @config_filename_ifaces = "/etc/network/interfaces"
    @config_filename_ifcfg = "/etc/network/interfaces.d/ifcfg-#{@new_resource.device}"
  end

  describe "generate_config for action_add" do

    it "should create network-scripts directory" do
      @provider.run_action(:add)
      Dir.exist?(File.dirname(@config_filename_ifcfg)).should be_true
    end

    it "should write configure network-scripts directory" do
      @provider.run_action(:add)
      config_ifaces = File.read(@config_filename_ifaces)
      config_ifaces.should match(/^\s*source\s+\/etc\/network\/interfaces[.]d\/[*]\s*$/)
    end

    it "should write a network-script" do
      @provider.run_action(:add)
      config_ifcfg = File.read(@config_filename_ifcfg)
      config_ifcfg.should match(/^iface eth0 inet static\s*$/)
      config_ifcfg.should match(/^\s+address 10\.0\.0\.1\s*$/)
      config_ifcfg.should match(/^\s+netmask 255\.255\.254\.0\s*$/)
    end
  end

  describe "delete_config for action_delete" do

    it "should delete network-script if it exists" do
      @current_resource.device @new_resource.device
      @provider.run_action(:delete)
      File.exist?(@config_filename_ifcfg).should be_false
    end
  end
end
