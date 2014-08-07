#
# Author:: Nuo Yan <nuo@opscode.com>
# Author:: Seth Chisamore <schisamo@opscode.com>
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc
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

describe Chef::Provider::Service::Windows, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::WindowsService.new("chef")
    @provider = Chef::Provider::Service::Windows.new(@new_resource, @run_context)
    @provider.current_resource = Chef::Resource::WindowsService.new("current-chef")
    Object.send(:remove_const, 'Win32') if defined?(Win32)
    Win32 = Module.new
    Win32::Service = Class.new
    Win32::Service::AUTO_START = 0x00000002
    Win32::Service::DEMAND_START = 0x00000003
    Win32::Service::DISABLED = 0x00000004
    Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
      double("StatusStruct", :current_state => "running"))
    Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
      double("ConfigStruct", :start_type => "auto start"))
    Win32::Service.stub(:exists?).and_return(true)
  end

  it "should set the current resources service name to the new resources service name" do
    @provider.load_current_resource
    @provider.current_resource.service_name.should == 'chef'
  end

  it "should return the current resource" do
    @provider.load_current_resource.should equal(@provider.current_resource)
  end

  it "should set the current resources status" do
    @provider.load_current_resource
    @provider.current_resource.running.should be_true
  end

  it "should set the current resources start type" do
    @provider.load_current_resource
    @provider.current_resource.enabled.should be_true
  end

  describe Chef::Provider::Service::Windows, "start_service" do
    before(:each) do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
    end

    it "should call the start command if one is specified" do
      @new_resource.start_command "sc start chef"
      @provider.should_receive(:shell_out!).with("#{@new_resource.start_command}").and_return("Starting custom service")
      @provider.start_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should use the built-in command if no start command is specified" do
      Win32::Service.should_receive(:start).with(@new_resource.service_name)
      @provider.start_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should do nothing if the service does not exist" do
      Win32::Service.stub(:exists?).with(@new_resource.service_name).and_return(false)
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      @provider.start_service
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should do nothing if the service is running" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      @provider.start_service
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should raise an error if the service is paused" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "paused"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      expect { @provider.start_service }.to raise_error( Chef::Exceptions::Service )
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should wait and continue if the service is in start_pending" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "start pending"),
        double("StatusStruct", :current_state => "start pending"),
        double("StatusStruct", :current_state => "running"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      @provider.start_service
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should fail if the service is in stop_pending" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stop pending"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      expect { @provider.start_service }.to raise_error( Chef::Exceptions::Service )
      @new_resource.updated_by_last_action?.should be_false
    end

  end


  describe Chef::Provider::Service::Windows, "stop_service" do

    before(:each) do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"),
        double("StatusStruct", :current_state => "stopped"))
    end

    it "should call the stop command if one is specified" do
      @new_resource.stop_command "sc stop chef"
      @provider.should_receive(:shell_out!).with("#{@new_resource.stop_command}").and_return("Stopping custom service")
      @provider.stop_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should use the built-in command if no stop command is specified" do
      Win32::Service.should_receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should do nothing if the service does not exist" do
      Win32::Service.stub(:exists?).with(@new_resource.service_name).and_return(false)
      Win32::Service.should_not_receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should do nothing if the service is stopped" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should raise an error if the service is paused" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "paused"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      expect { @provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should wait and continue if the service is in stop_pending" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stop pending"),
        double("StatusStruct", :current_state => "stop pending"),
        double("StatusStruct", :current_state => "stopped"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should fail if the service is in start_pending" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "start pending"))
      @provider.load_current_resource
      Win32::Service.should_not_receive(:stop).with(@new_resource.service_name)
      expect { @provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      @new_resource.updated_by_last_action?.should be_false
    end

    it "should pass custom timeout to the stop command if provided" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"))
      @new_resource.timeout 1
      Win32::Service.should_receive(:stop).with(@new_resource.service_name)
      Timeout.timeout(2) do
        expect { @provider.stop_service }.to raise_error(Timeout::Error)
      end
      @new_resource.updated_by_last_action?.should be_false
    end

  end

  describe Chef::Provider::Service::Windows, "restart_service" do

    it "should call the restart command if one is specified" do
      @new_resource.restart_command "sc restart"
      @provider.should_receive(:shell_out!).with("#{@new_resource.restart_command}")
      @provider.restart_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should stop then start the service if it is running" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
      Win32::Service.should_receive(:stop).with(@new_resource.service_name)
      Win32::Service.should_receive(:start).with(@new_resource.service_name)
      @provider.restart_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should just start the service if it is stopped" do
      Win32::Service.stub(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
      Win32::Service.should_receive(:start).with(@new_resource.service_name)
      @provider.restart_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should do nothing if the service does not exist" do
      Win32::Service.stub(:exists?).with(@new_resource.service_name).and_return(false)
      Win32::Service.should_not_receive(:stop).with(@new_resource.service_name)
      Win32::Service.should_not_receive(:start).with(@new_resource.service_name)
      @provider.restart_service
      @new_resource.updated_by_last_action?.should be_false
    end

  end

  describe Chef::Provider::Service::Windows, "enable_service" do
    before(:each) do
      Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
    end

    it "should enable service" do
      Win32::Service.should_receive(:configure).with(:service_name => @new_resource.service_name, :start_type => Win32::Service::AUTO_START)
      @provider.enable_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should do nothing if the service does not exist" do
      Win32::Service.stub(:exists?).with(@new_resource.service_name).and_return(false)
      Win32::Service.should_not_receive(:configure)
      @provider.enable_service
      @new_resource.updated_by_last_action?.should be_false
    end
  end

  describe Chef::Provider::Service::Windows, "action_enable" do
    it "does nothing if the service is enabled" do
      Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
      @provider.should_not_receive(:enable_service)
      @provider.action_enable
    end

    it "enables the service if it is not set to automatic start" do
      Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
      @provider.should_receive(:enable_service)
      @provider.action_enable
    end
  end
  
  describe Chef::Provider::Service::Windows, "action_disable" do
    it "does nothing if the service is disabled" do
      Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
      @provider.should_not_receive(:disable_service)
      @provider.action_disable
    end

    it "disables the service if it is not set to disabled" do
      Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
      @provider.should_receive(:disable_service)
      @provider.action_disable
    end
  end

  describe Chef::Provider::Service::Windows, "disable_service" do
    before(:each) do
      Win32::Service.stub(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
    end

    it "should disable service" do
      Win32::Service.should_receive(:configure)
      @provider.disable_service
      @new_resource.updated_by_last_action?.should be_true
    end

    it "should do nothing if the service does not exist" do
      Win32::Service.stub(:exists?).with(@new_resource.service_name).and_return(false)
      Win32::Service.should_not_receive(:configure)
      @provider.disable_service
      @new_resource.updated_by_last_action?.should be_false
    end
  end

  # FIXME
  describe Chef::Provider::Service::Windows, "action_configure_startup" do
    { :automatic => "auto start", :manual => "demand start", :disabled => "disabled" }.each do |type,win32|
      it "sets the startup type to #{type} if it is something else" do
        @new_resource.startup_type(type)
        @provider.stub(:start_type).and_return("fire")
        @provider.should_receive(:set_startup_type).with(type)
        @provider.action_configure_startup
      end

      it "leaves the startup type as #{type} if it is already set" do
        @new_resource.startup_type(type)
        @provider.stub(:start_type).and_return(win32)
        @provider.should_not_receive(:set_startup_type).with(type)
        @provider.action_configure_startup
      end
    end
  end
  describe Chef::Provider::Service::Windows, "set_start_type" do
    #FIXME
  end
end
