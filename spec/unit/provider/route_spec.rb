#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Route do
  before do
    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new([])
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @new_resource = Chef::Resource::Route.new('10.0.0.10')
    @new_resource.gateway "10.0.0.9"
    @current_resource = Chef::Resource::Route.new('10.0.0.10')
    @current_resource.gateway "10.0.0.9"

    @provider = Chef::Provider::Route.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe Chef::Provider::Route, "hex2ip" do
    it "should return nil if ip address is invalid" do
      @provider.hex2ip('foo').should be_nil # does not even look like an ip
      @provider.hex2ip('ABCDEFGH').should be_nil # 8 chars, but invalid
    end

    it "should return quad-dotted notation for a valid IP" do
      @provider.hex2ip('01234567').should == '103.69.35.1'
      @provider.hex2ip('0064a8c0').should == '192.168.100.0'
      @provider.hex2ip('00FFFFFF').should == '255.255.255.0'
    end
  end


  describe Chef::Provider::Route, "load_current_resource" do
    context "on linux" do
      before do
        @node.automatic_attrs[:os] = 'linux'
        routing_table = "Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT\n" +
                        "eth0	0064A8C0	0984A8C0	0003	0	0	0	00FFFFFF	0	0	0\n"
        route_file = StringIO.new(routing_table)
        File.stub!(:open).with("/proc/net/route", "r").and_return(route_file)
      end

      it "should set is_running to false when a route is not detected" do
        resource = Chef::Resource::Route.new('10.10.10.0/24')
        resource.stub!(:gateway).and_return("10.0.0.1")
        resource.stub!(:device).and_return("eth0")
        provider = Chef::Provider::Route.new(resource, @run_context)

        provider.load_current_resource
        provider.is_running.should be_false
      end

      it "should detect existing routes and set is_running attribute correctly" do
        resource = Chef::Resource::Route.new('192.168.100.0/24')
        resource.stub!(:gateway).and_return("192.168.132.9")
        resource.stub!(:device).and_return("eth0")
        provider = Chef::Provider::Route.new(resource, @run_context)

        provider.load_current_resource
        provider.is_running.should be_true
      end

      it "should use gateway value when matching routes" do
        resource = Chef::Resource::Route.new('192.168.100.0/24')
        resource.stub!(:gateway).and_return("10.10.10.10")
        resource.stub!(:device).and_return("eth0")
        provider = Chef::Provider::Route.new(resource, @run_context)

        provider.load_current_resource
        provider.is_running.should be_false
      end
    end
  end

  describe Chef::Provider::Route, "action_add" do
    it "should add the route if it does not exist" do
      @provider.stub!(:run_command).and_return(true)
      @current_resource.stub!(:gateway).and_return(nil)
      @provider.should_receive(:generate_command).once.with(:add)
      @provider.should_receive(:generate_config)
      @provider.run_action(:add)
      @new_resource.should be_updated
    end

    it "should not add the route if it exists" do
      @provider.stub!(:run_command).and_return(true)
      @provider.stub!(:is_running).and_return(true)
      @provider.should_not_receive(:generate_command).with(:add)
      @provider.should_receive(:generate_config)
      @provider.run_action(:add)
      @new_resource.should_not be_updated
    end
  end

  describe Chef::Provider::Route, "action_delete" do
    it "should delete the route if it exists" do
      @provider.stub!(:run_command).and_return(true)
      @provider.should_receive(:generate_command).once.with(:delete)
      @provider.stub!(:is_running).and_return(true)
      @provider.run_action(:delete)
      @new_resource.should be_updated
    end

    it "should not delete the route if it does not exist" do
      @current_resource.stub!(:gateway).and_return(nil)
      @provider.stub!(:run_command).and_return(true)
      @provider.should_not_receive(:generate_command).with(:add)
      @provider.run_action(:delete)
      @new_resource.should_not be_updated
    end
  end

  describe Chef::Provider::Route, "generate_command for action_add" do
    it "should include a netmask when a one is specified" do
      @new_resource.stub!(:netmask).and_return('255.255.0.0')
      @provider.generate_command(:add).should match(/\/\d{1,2}\s/)
    end

    it "should not include a netmask when a one is specified" do
      @new_resource.stub!(:netmask).and_return(nil)
      @provider.generate_command(:add).should_not match(/\/\d{1,2}\s/)
    end

    it "should include ' via $gateway ' when a gateway is specified" do
      @provider.generate_command(:add).should match(/\svia\s#{@new_resource.gateway}\s/)
    end

    it "should not include ' via $gateway ' when a gateway is not specified" do
      @new_resource.stub!(:gateway).and_return(nil)
      @provider.generate_command(:add).should_not match(/\svia\s#{@new_resource.gateway}\s/)
    end
  end

  describe Chef::Provider::Route, "generate_command for action_delete" do
    it "should include a netmask when a one is specified" do
      @new_resource.stub!(:netmask).and_return('255.255.0.0')
      @provider.generate_command(:delete).should match(/\/\d{1,2}\s/)
    end

    it "should not include a netmask when a one is specified" do
      @new_resource.stub!(:netmask).and_return(nil)
      @provider.generate_command(:delete).should_not match(/\/\d{1,2}\s/)
    end

    it "should include ' via $gateway ' when a gateway is specified" do
      @provider.generate_command(:delete).should match(/\svia\s#{@new_resource.gateway}\s/)
    end

    it "should not include ' via $gateway ' when a gateway is not specified" do
      @new_resource.stub!(:gateway).and_return(nil)
      @provider.generate_command(:delete).should_not match(/\svia\s#{@new_resource.gateway}\s/)
    end
  end

  describe Chef::Provider::Route, "config_file_contents for action_add" do
    it "should include a netmask when a one is specified" do
      @new_resource.stub!(:netmask).and_return('255.255.0.0')
      @provider.config_file_contents(:add, { :target => @new_resource.target, :netmask => @new_resource.netmask}).should match(/\/\d{1,2}.*\n$/)
    end

    it "should not include a netmask when a one is specified" do
      @provider.config_file_contents(:add, { :target => @new_resource.target}).should_not match(/\/\d{1,2}.*\n$/)
    end

    it "should include ' via $gateway ' when a gateway is specified" do
      @provider.config_file_contents(:add, { :target => @new_resource.target, :gateway => @new_resource.gateway}).should match(/\svia\s#{@new_resource.gateway}\n/)
    end

    it "should not include ' via $gateway ' when a gateway is not specified" do
      @provider.generate_command(:add).should_not match(/\svia\s#{@new_resource.gateway}\n/)
    end
  end

  describe Chef::Provider::Route, "config_file_contents for action_delete" do
    it "should return an empty string" do
      @provider.config_file_contents(:delete).should match(/^$/)
    end
  end

  describe Chef::Provider::Route, "generate_config method" do
    %w[ centos redhat fedora ].each do |platform|
      it "should write a route file on #{platform} platform" do
        @node.automatic_attrs[:platform] = platform

        route_file = StringIO.new
        File.should_receive(:new).with("/etc/sysconfig/network-scripts/route-eth0", "w").and_return(route_file)
        #Chef::Log.should_receive(:debug).with("route[10.0.0.10] writing route.eth0\n10.0.0.10 via 10.0.0.9\n")
        @run_context.resource_collection << @new_resource
        @provider.generate_config
      end
    end

    it "should put all routes for a device in a route config file" do
      @node.automatic_attrs[:platform] = 'centos'

      route_file = StringIO.new
      File.should_receive(:new).and_return(route_file)
      @run_context.resource_collection << Chef::Resource::Route.new('192.168.1.0/24 via 192.168.0.1')
      @run_context.resource_collection << Chef::Resource::Route.new('192.168.2.0/24 via 192.168.0.1')
      @run_context.resource_collection << Chef::Resource::Route.new('192.168.3.0/24 via 192.168.0.1')

      @provider.generate_config
      route_file.string.split("\n").should have(3).items
      route_file.string.should match(/^192.168.1.0\/24 via 192.168.0.1$/)
      route_file.string.should match(/^192.168.2.0\/24 via 192.168.0.1$/)
      route_file.string.should match(/^192.168.3.0\/24 via 192.168.0.1$/)
    end
  end
end
