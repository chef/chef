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
require 'mixlib/shellout'

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
    allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
      double("StatusStruct", :current_state => "running"))
    allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
      double("ConfigStruct", :start_type => "auto start"))
    allow(Win32::Service).to receive(:exists?).and_return(true)
    allow(Win32::Service).to receive(:configure).and_return(Win32::Service)
  end

  it "should set the current resources service name to the new resources service name" do
    @provider.load_current_resource
    expect(@provider.current_resource.service_name).to eq('chef')
  end

  it "should return the current resource" do
    expect(@provider.load_current_resource).to equal(@provider.current_resource)
  end

  it "should set the current resources status" do
    @provider.load_current_resource
    expect(@provider.current_resource.running).to be_truthy
  end

  it "should set the current resources start type" do
    @provider.load_current_resource
    expect(@provider.current_resource.enabled).to be_truthy
  end

  it "does not set the current resources start type if it is neither AUTO START or DISABLED" do
    allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
      double("ConfigStruct", :start_type => "manual"))
    @provider.load_current_resource
    expect(@provider.current_resource.enabled).to be_nil
  end

  describe Chef::Provider::Service::Windows, "start_service" do
    before(:each) do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
    end

    it "should call the start command if one is specified" do
      @new_resource.start_command "sc start chef"
      expect(@provider).to receive(:shell_out!).with("#{@new_resource.start_command}").and_return("Starting custom service")
      @provider.start_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should use the built-in command if no start command is specified" do
      expect(Win32::Service).to receive(:start).with(@new_resource.service_name)
      @provider.start_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should do nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(@new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      @provider.start_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should do nothing if the service is running" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      @provider.start_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should raise an error if the service is paused" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "paused"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      expect { @provider.start_service }.to raise_error( Chef::Exceptions::Service )
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should wait and continue if the service is in start_pending" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "start pending"),
        double("StatusStruct", :current_state => "start pending"),
        double("StatusStruct", :current_state => "running"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      @provider.start_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should fail if the service is in stop_pending" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stop pending"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      expect { @provider.start_service }.to raise_error( Chef::Exceptions::Service )
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    describe "running as a different account" do
      let(:old_run_as_user) { @new_resource.run_as_user }
      let(:old_run_as_password) { @new_resource.run_as_password }

      before {
        @new_resource.run_as_user(".\\wallace")
        @new_resource.run_as_password("Wensleydale")
      }

      after {
        @new_resource.run_as_user(old_run_as_user)
        @new_resource.run_as_password(old_run_as_password)
      }

      it "should call #grant_service_logon if the :run_as_user and :run_as_password attributes are present" do
        expect(Win32::Service).to receive(:start)
        expect(@provider).to receive(:grant_service_logon).and_return(true)
        @provider.start_service
      end
    end
  end


  describe Chef::Provider::Service::Windows, "stop_service" do

    before(:each) do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"),
        double("StatusStruct", :current_state => "stopped"))
    end

    it "should call the stop command if one is specified" do
      @new_resource.stop_command "sc stop chef"
      expect(@provider).to receive(:shell_out!).with("#{@new_resource.stop_command}").and_return("Stopping custom service")
      @provider.stop_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should use the built-in command if no stop command is specified" do
      expect(Win32::Service).to receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should do nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(@new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should do nothing if the service is stopped" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should raise an error if the service is paused" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "paused"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      expect { @provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should wait and continue if the service is in stop_pending" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stop pending"),
        double("StatusStruct", :current_state => "stop pending"),
        double("StatusStruct", :current_state => "stopped"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(@new_resource.service_name)
      @provider.stop_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should fail if the service is in start_pending" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "start pending"))
      @provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(@new_resource.service_name)
      expect { @provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

    it "should pass custom timeout to the stop command if provided" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"))
      @new_resource.timeout 1
      expect(Win32::Service).to receive(:stop).with(@new_resource.service_name)
      Timeout.timeout(2) do
        expect { @provider.stop_service }.to raise_error(Timeout::Error)
      end
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

  end

  describe Chef::Provider::Service::Windows, "restart_service" do

    it "should call the restart command if one is specified" do
      @new_resource.restart_command "sc restart"
      expect(@provider).to receive(:shell_out!).with("#{@new_resource.restart_command}")
      @provider.restart_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should stop then start the service if it is running" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
      expect(Win32::Service).to receive(:stop).with(@new_resource.service_name)
      expect(Win32::Service).to receive(:start).with(@new_resource.service_name)
      @provider.restart_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should just start the service if it is stopped" do
      allow(Win32::Service).to receive(:status).with(@new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
      expect(Win32::Service).to receive(:start).with(@new_resource.service_name)
      @provider.restart_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should do nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(@new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:stop).with(@new_resource.service_name)
      expect(Win32::Service).not_to receive(:start).with(@new_resource.service_name)
      @provider.restart_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end

  end

  describe Chef::Provider::Service::Windows, "enable_service" do
    before(:each) do
      allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
    end

    it "should enable service" do
      expect(Win32::Service).to receive(:configure).with(:service_name => @new_resource.service_name, :start_type => Win32::Service::AUTO_START)
      @provider.enable_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should do nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(@new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:configure)
      @provider.enable_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end
  end

  describe Chef::Provider::Service::Windows, "action_enable" do
    it "does nothing if the service is enabled" do
      allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
      expect(@provider).not_to receive(:enable_service)
      @provider.action_enable
    end

    it "enables the service if it is not set to automatic start" do
      allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
      expect(@provider).to receive(:enable_service)
      @provider.action_enable
    end
  end

  describe Chef::Provider::Service::Windows, "action_disable" do
    it "does nothing if the service is disabled" do
      allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
      expect(@provider).not_to receive(:disable_service)
      @provider.action_disable
    end

    it "disables the service if it is not set to disabled" do
      allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
      expect(@provider).to receive(:disable_service)
      @provider.action_disable
    end
  end

  describe Chef::Provider::Service::Windows, "disable_service" do
    before(:each) do
      allow(Win32::Service).to receive(:config_info).with(@new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
    end

    it "should disable service" do
      expect(Win32::Service).to receive(:configure)
      @provider.disable_service
      expect(@new_resource.updated_by_last_action?).to be_truthy
    end

    it "should do nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(@new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:configure)
      @provider.disable_service
      expect(@new_resource.updated_by_last_action?).to be_falsey
    end
  end

  describe Chef::Provider::Service::Windows, "action_configure_startup" do
    { :automatic => "auto start", :manual => "demand start", :disabled => "disabled" }.each do |type,win32|
      it "sets the startup type to #{type} if it is something else" do
        @new_resource.startup_type(type)
        allow(@provider).to receive(:current_start_type).and_return("fire")
        expect(@provider).to receive(:set_startup_type).with(type)
        @provider.action_configure_startup
      end

      it "leaves the startup type as #{type} if it is already set" do
        @new_resource.startup_type(type)
        allow(@provider).to receive(:current_start_type).and_return(win32)
        expect(@provider).not_to receive(:set_startup_type).with(type)
        @provider.action_configure_startup
      end
    end
  end

  describe Chef::Provider::Service::Windows, "set_start_type" do
    it "when called with :automatic it calls Win32::Service#configure with Win32::Service::AUTO_START" do
      expect(Win32::Service).to receive(:configure).with(:service_name => @new_resource.service_name, :start_type => Win32::Service::AUTO_START)
      @provider.send(:set_startup_type, :automatic)
    end

    it "when called with :manual it calls Win32::Service#configure with Win32::Service::DEMAND_START" do
      expect(Win32::Service).to receive(:configure).with(:service_name => @new_resource.service_name, :start_type => Win32::Service::DEMAND_START)
      @provider.send(:set_startup_type, :manual)
    end

    it "when called with :disabled it calls Win32::Service#configure with Win32::Service::DISABLED" do
      expect(Win32::Service).to receive(:configure).with(:service_name => @new_resource.service_name, :start_type => Win32::Service::DISABLED)
      @provider.send(:set_startup_type, :disabled)
    end

    it "raises an exception when given an unknown start type" do
      expect { @provider.send(:set_startup_type, :fire_truck) }.to raise_error(Chef::Exceptions::ConfigurationError)
    end
  end

  shared_context "testing private methods" do

    let(:private_methods) {
      described_class.private_instance_methods
    }

    before {
      described_class.send(:public, *private_methods)
    }

    after {
      described_class.send(:private, *private_methods)
    }
  end

  describe "grant_service_logon" do
    include_context "testing private methods"

    let(:username) { "unit_test_user" }
    let(:success_string) { "The task has completed successfully.\r\nSee logfile etc." }
    let(:failure_string) { "Look on my works, ye Mighty, and despair!" }
    let(:command) {
      dbfile = @provider.grant_dbfile_name(username)
      policyfile = @provider.grant_policyfile_name(username)
      logfile = @provider.grant_logfile_name(username)

      %Q{secedit.exe /configure /db "#{dbfile}" /cfg "#{policyfile}" /areas USER_RIGHTS SECURITYPOLICY SERVICES /log "#{logfile}"}
    }
    let(:shellout_env) { {:environment=>{"LC_ALL"=>"en_US.UTF-8"}} }

    before {
      expect_any_instance_of(described_class).to receive(:shell_out).with(command).and_call_original
      expect_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
    }

    after {
      # only needed for the second test.
      ::File.delete(@provider.grant_policyfile_name(username)) rescue nil
      ::File.delete(@provider.grant_logfile_name(username)) rescue nil
      ::File.delete(@provider.grant_dbfile_name(username)) rescue nil
    }

    it "calls Mixlib::Shellout with the correct command string" do
      expect_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
      expect(@provider.grant_service_logon(username)).to equal true
    end

    it "raises an exception when the grant command fails" do
      expect_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(1)
      expect_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(failure_string)
      expect { @provider.grant_service_logon(username) }.to raise_error(Chef::Exceptions::Service)
    end
  end

  describe "cleaning usernames" do
    include_context "testing private methods"

    it "correctly reformats usernames to create valid filenames" do
      expect(@provider.clean_username_for_path("\\\\problem username/oink.txt")).to eq("_problem_username_oink_txt")
      expect(@provider.clean_username_for_path("boring_username")).to eq("boring_username")
    end

    it "correctly reformats usernames for the policy file" do
      expect(@provider.canonicalize_username(".\\maryann")).to eq("maryann")
      expect(@provider.canonicalize_username("maryann")).to eq("maryann")

      expect(@provider.canonicalize_username("\\\\maryann")).to eq("maryann")
      expect(@provider.canonicalize_username("mydomain\\\\maryann")).to eq("mydomain\\\\maryann")
      expect(@provider.canonicalize_username("\\\\mydomain\\\\maryann")).to eq("mydomain\\\\maryann")
    end
  end
end
