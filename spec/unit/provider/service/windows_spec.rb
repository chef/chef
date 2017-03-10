#
# Author:: Nuo Yan <nuo@chef.io>
# Author:: Seth Chisamore <schisamo@chef.io>
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
require "mixlib/shellout"

describe Chef::Provider::Service::Windows, "load_current_resource" do
  include_context "Win32"

  let(:new_resource) { Chef::Resource::WindowsService.new("chef") }
  let(:provider) do
    prvdr = Chef::Provider::Service::Windows.new(new_resource,
      Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new))
    prvdr.current_resource = Chef::Resource::WindowsService.new("current-chef")
    prvdr
  end
  let(:service_right) { Chef::Provider::Service::Windows::SERVICE_RIGHT }

  before(:all) do
    Win32::Service = Class.new
  end

  before(:each) do
    Win32::Service::AUTO_START = 0x00000002
    Win32::Service::DEMAND_START = 0x00000003
    Win32::Service::DISABLED = 0x00000004

    allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
      double("StatusStruct", :current_state => "running"))
    allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
      double("ConfigStruct", :start_type => "auto start"))
    allow(Win32::Service).to receive(:exists?).and_return(true)
    allow(Win32::Service).to receive(:configure).and_return(Win32::Service)
    allow(Chef::ReservedNames::Win32::Security).to receive(:get_account_right).and_return([])
  end

  after(:each) do
    Win32::Service.send(:remove_const, "AUTO_START") if defined?(Win32::Service::AUTO_START)
    Win32::Service.send(:remove_const, "DEMAND_START") if defined?(Win32::Service::DEMAND_START)
    Win32::Service.send(:remove_const, "DISABLED") if defined?(Win32::Service::DISABLED)
  end

  it "sets the current resources service name to the new resources service name" do
    provider.load_current_resource
    expect(provider.current_resource.service_name).to eq("chef")
  end

  it "returns the current resource" do
    expect(provider.load_current_resource).to equal(provider.current_resource)
  end

  it "sets the current resources status" do
    provider.load_current_resource
    expect(provider.current_resource.running).to be_truthy
  end

  it "sets the current resources start type" do
    provider.load_current_resource
    expect(provider.current_resource.enabled).to be_truthy
  end

  it "does not set the current resources start type if it is neither AUTO START or DISABLED" do
    allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
      double("ConfigStruct", :start_type => "manual"))
    provider.load_current_resource
    expect(provider.current_resource.enabled).to be_nil
  end

  describe Chef::Provider::Service::Windows, "start_service" do
    before(:each) do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
    end

    it "calls the start command if one is specified" do
      new_resource.start_command "sc start chef"
      expect(provider).to receive(:shell_out!).with("#{new_resource.start_command}").and_return("Starting custom service")
      provider.start_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "uses the built-in command if no start command is specified" do
      expect(Win32::Service).to receive(:start).with(new_resource.service_name)
      provider.start_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      provider.start_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "does nothing if the service is running" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      provider.start_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "raises an error if the service is paused" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "paused"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      expect { provider.start_service }.to raise_error( Chef::Exceptions::Service )
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "waits and continues if the service is in start_pending" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "start pending"),
        double("StatusStruct", :current_state => "start pending"),
        double("StatusStruct", :current_state => "running"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      provider.start_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "fails if the service is in stop_pending" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stop pending"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      expect { provider.start_service }.to raise_error( Chef::Exceptions::Service )
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    describe "running as a different account" do
      let(:old_run_as_user) { new_resource.run_as_user }
      let(:old_run_as_password) { new_resource.run_as_password }

      before do
        new_resource.run_as_user(".\\wallace")
        new_resource.run_as_password("Wensleydale")
      end

      after do
        new_resource.run_as_user(old_run_as_user)
        new_resource.run_as_password(old_run_as_password)
      end

      it "calls #grant_service_logon if the :run_as_user and :run_as_password attributes are present" do
        expect(Win32::Service).to receive(:start)
        expect(provider).to receive(:grant_service_logon).and_return(true)
        provider.start_service
      end

      it "does not grant user SeServiceLogonRight if it already has it" do
        expect(Win32::Service).to receive(:start)
        expect(Chef::ReservedNames::Win32::Security).to receive(:get_account_right).with("wallace").and_return([service_right])
        expect(Chef::ReservedNames::Win32::Security).not_to receive(:add_account_right).with("wallace", service_right)
        provider.start_service
      end
    end
  end

  describe Chef::Provider::Service::Windows, "stop_service" do

    before(:each) do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"),
        double("StatusStruct", :current_state => "stopped"))
    end

    it "calls the stop command if one is specified" do
      new_resource.stop_command "sc stop chef"
      expect(provider).to receive(:shell_out!).with("#{new_resource.stop_command}").and_return("Stopping custom service")
      provider.stop_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "uses the built-in command if no stop command is specified" do
      expect(Win32::Service).to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "does nothing if the service is stopped" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "raises an error if the service is paused" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "paused"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      expect { provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "waits and continue if the service is in stop_pending" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stop pending"),
        double("StatusStruct", :current_state => "stop pending"),
        double("StatusStruct", :current_state => "stopped"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "fails if the service is in start_pending" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "start pending"))
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      expect { provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

    it "passes custom timeout to the stop command if provided" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"))
      new_resource.timeout 1
      expect(Win32::Service).to receive(:stop).with(new_resource.service_name)
      Timeout.timeout(2) do
        expect { provider.stop_service }.to raise_error(Timeout::Error)
      end
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

  end

  describe Chef::Provider::Service::Windows, "restart_service" do

    it "calls the restart command if one is specified" do
      new_resource.restart_command "sc restart"
      expect(provider).to receive(:shell_out!).with("#{new_resource.restart_command}")
      provider.restart_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "stops then starts the service if it is running" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "running"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
      expect(Win32::Service).to receive(:stop).with(new_resource.service_name)
      expect(Win32::Service).to receive(:start).with(new_resource.service_name)
      provider.restart_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "just starts the service if it is stopped" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "stopped"),
        double("StatusStruct", :current_state => "running"))
      expect(Win32::Service).to receive(:start).with(new_resource.service_name)
      provider.restart_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      provider.restart_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end

  end

  describe Chef::Provider::Service::Windows, "enable_service" do
    before(:each) do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
    end

    it "enables service" do
      expect(Win32::Service).to receive(:configure).with(:service_name => new_resource.service_name, :start_type => Win32::Service::AUTO_START)
      provider.enable_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:configure)
      provider.enable_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end
  end

  describe Chef::Provider::Service::Windows, "action_enable" do
    it "does nothing if the service is enabled" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
      expect(provider).not_to receive(:enable_service)
      provider.action_enable
    end

    it "enables the service if it is not set to automatic start" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
      expect(provider).to receive(:enable_service)
      provider.action_enable
    end
  end

  describe Chef::Provider::Service::Windows, "action_disable" do
    it "does nothing if the service is disabled" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "disabled"))
      expect(provider).not_to receive(:disable_service)
      provider.action_disable
    end

    it "disables the service if it is not set to disabled" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
      expect(provider).to receive(:disable_service)
      provider.action_disable
    end
  end

  describe Chef::Provider::Service::Windows, "disable_service" do
    before(:each) do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", :start_type => "auto start"))
    end

    it "disables service" do
      expect(Win32::Service).to receive(:configure)
      provider.disable_service
      expect(new_resource.updated_by_last_action?).to be_truthy
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:configure)
      provider.disable_service
      expect(new_resource.updated_by_last_action?).to be_falsey
    end
  end

  describe Chef::Provider::Service::Windows, "action_configure_startup" do
    { :automatic => "auto start", :manual => "demand start", :disabled => "disabled" }.each do |type, win32|
      it "sets the startup type to #{type} if it is something else" do
        new_resource.startup_type(type)
        allow(provider).to receive(:current_start_type).and_return("fire")
        expect(provider).to receive(:set_startup_type).with(type)
        provider.action_configure_startup
      end

      it "leaves the startup type as #{type} if it is already set" do
        new_resource.startup_type(type)
        allow(provider).to receive(:current_start_type).and_return(win32)
        expect(provider).not_to receive(:set_startup_type).with(type)
        provider.action_configure_startup
      end
    end
  end

  describe Chef::Provider::Service::Windows, "set_start_type" do
    it "when called with :automatic it calls Win32::Service#configure with Win32::Service::AUTO_START" do
      expect(Win32::Service).to receive(:configure).with(:service_name => new_resource.service_name, :start_type => Win32::Service::AUTO_START)
      provider.send(:set_startup_type, :automatic)
    end

    it "when called with :manual it calls Win32::Service#configure with Win32::Service::DEMAND_START" do
      expect(Win32::Service).to receive(:configure).with(:service_name => new_resource.service_name, :start_type => Win32::Service::DEMAND_START)
      provider.send(:set_startup_type, :manual)
    end

    it "when called with :disabled it calls Win32::Service#configure with Win32::Service::DISABLED" do
      expect(Win32::Service).to receive(:configure).with(:service_name => new_resource.service_name, :start_type => Win32::Service::DISABLED)
      provider.send(:set_startup_type, :disabled)
    end

    it "raises an exception when given an unknown start type" do
      expect { provider.send(:set_startup_type, :fire_truck) }.to raise_error(Chef::Exceptions::ConfigurationError)
    end
  end

  shared_context "testing private methods" do

    let(:private_methods) do
      described_class.private_instance_methods
    end

    before do
      described_class.send(:public, *private_methods)
    end

    after do
      described_class.send(:private, *private_methods)
    end
  end

  describe "grant_service_logon" do
    include_context "testing private methods"

    let(:username) { "unit_test_user" }

    it "calls win32 api to grant user SeServiceLogonRight" do
      expect(Chef::ReservedNames::Win32::Security).to receive(:add_account_right).with(username, service_right)
      expect(provider.grant_service_logon(username)).to equal true
    end

    it "strips '.\' from user name when sending to win32 api" do
      expect(Chef::ReservedNames::Win32::Security).to receive(:add_account_right).with(username, service_right)
      expect(provider.grant_service_logon(".\\#{username}")).to equal true
    end

    it "raises an exception when the grant fails" do
      expect(Chef::ReservedNames::Win32::Security).to receive(:add_account_right).and_raise(Chef::Exceptions::Win32APIError, "barf")
      expect { provider.grant_service_logon(username) }.to raise_error(Chef::Exceptions::Service)
    end
  end

  describe "cleaning usernames" do
    include_context "testing private methods"

    it "correctly reformats usernames to create valid filenames" do
      expect(provider.clean_username_for_path("\\\\problem username/oink.txt")).to eq("_problem_username_oink_txt")
      expect(provider.clean_username_for_path("boring_username")).to eq("boring_username")
    end

    it "correctly reformats usernames for the policy file" do
      expect(provider.canonicalize_username(".\\maryann")).to eq("maryann")
      expect(provider.canonicalize_username("maryann")).to eq("maryann")

      expect(provider.canonicalize_username("\\\\maryann")).to eq("maryann")
      expect(provider.canonicalize_username("mydomain\\\\maryann")).to eq("mydomain\\\\maryann")
      expect(provider.canonicalize_username("\\\\mydomain\\\\maryann")).to eq("mydomain\\\\maryann")
    end
  end
end
