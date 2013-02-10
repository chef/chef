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

describe Chef::Provider::Ifconfig::Redhat do
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
    @provider = Chef::Provider::Ifconfig::Redhat.new(@new_resource, @run_context)
    @current_resource = Chef::Resource::Ifconfig.new("10.0.0.1", @run_context)

    status = mock("Status", :exitstatus => 0)
    @provider.instance_variable_set("@status", status)
    @provider.current_resource = @current_resource
 end

  describe "generate_config for action_add" do

     it "should write network-script for centos" do
      @provider.stub!(:load_current_resource)
      @provider.stub!(:run_command)
      config_filename = "/etc/sysconfig/network-scripts/ifcfg-#{@new_resource.device}"
      config_file = StringIO.new
      File.should_receive(:new).with(config_filename, "w").and_return(config_file)

      @provider.run_action(:add)
      config_file.string.should match(/^\s*DEVICE=eth0\s*$/)
      config_file.string.should match(/^\s*IPADDR=10\.0\.0\.1\s*$/)
      config_file.string.should match(/^\s*NETMASK=255\.255\.254\.0\s*$/)
     end
  end

  describe "delete_config for action_delete" do

    it "should delete network-script if it exists for centos" do
      @current_resource.device @new_resource.device
      @provider.stub!(:load_current_resource)
      @provider.stub!(:run_command)
      config_filename =  "/etc/sysconfig/network-scripts/ifcfg-#{@new_resource.device}"
      File.should_receive(:exist?).with(config_filename).and_return(true)
      FileUtils.should_receive(:rm_f).with(config_filename, :verbose => false)

      @provider.run_action(:delete)
    end
  end
end
