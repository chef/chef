#
# Author:: Nuo Yan <nuo@chef.io>
# Author:: Seth Chisamore <schisamo@chef.io>
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Provider::Service::Windows, "load_current_resource" do
  include_context "Win32"

  before do
    stub_const("Chef::ReservedNames::Win32::Security", Class.new) unless windows?
  end

  let(:logger) { double("Mixlib::Log::Child").as_null_object }

  let(:chef_service_name) { "chef-client" }
  let(:new_resource) { Chef::Resource::WindowsService.new(chef_service_name) }

  # Actual response from Win32::Service.config_info('chef-client')
  let(:chef_service_binary_path_name) do
    'C:\\opscode\\chef\\embedded\\bin\\ruby.exe C:\\opscode\\chef\\bin\\chef-windows-service'
  end
  let(:chef_service_config_info) do
    double("Struct::ServiceConfigInfo",
      service_type: "own process",
      start_type: "auto start",
      error_control: "ignore",
      binary_path_name: chef_service_binary_path_name,
      load_order_group: "",
      tag_id: 0,
      dependencies: ["Winmgmt"],
      service_start_name: "LocalSystem",
      display_name: "Chef Client Service")
  end

  # Actual response from Win32::Service.services
  let(:chef_service_info) do
    double("Struct::ServiceInfo",
      service_name: chef_service_name,
      display_name: "Chef Client Service",
      service_type: "own process",
      current_state: "running",
      controls_accepted: [],
      win32_exit_code: 1077,
      service_specific_exit_code: 0,
      check_point: 0,
      wait_hint: 0,
      binary_path_name: chef_service_binary_path_name,
      start_type: "auto start",
      error_control: "ignore",
      load_order_group: "",
      tag_id: 0,
      start_name: "LocalSystem",
      dependencies: ["Winmgmt"],
      description: "Runs Chef Client on regular, configurable intervals.",
      interactive: false,
      pid: 0,
      service_flags: 0,
      reset_period: 0,
      reboot_message: nil,
      command: nil,
      num_actions: 0,
      actions: nil,
      delayed_start: 1)
  end

  let(:provider) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    allow(run_context).to receive(:logger).and_return(logger)
    prvdr = Chef::Provider::Service::Windows.new(new_resource, run_context)
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

    allow(Win32::Service).to receive(:start).with(any_args).and_return(Win32::Service)
    allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
      double("StatusStruct", current_state: "running")
    )
    allow(Win32::Service).to receive(:config_info).with(new_resource.service_name)
      .and_return(chef_service_config_info)

    allow(Win32::Service).to receive(:delayed_start).with(chef_service_name).and_return(1)
    allow(Win32::Service).to receive(:exists?).and_return(true)
    allow(Win32::Service).to receive(:configure).and_return(Win32::Service)
    allow(Chef::ReservedNames::Win32::Security).to receive(:get_account_right).and_return([])
    allow(Chef::ReservedNames::Win32::Security).to receive(:add_account_right).with("localsystem", "SeServiceLogonRight").and_return(0)
  end

  after(:each) do
    Win32::Service.send(:remove_const, "AUTO_START") if defined?(Win32::Service::AUTO_START)
    Win32::Service.send(:remove_const, "DEMAND_START") if defined?(Win32::Service::DEMAND_START)
    Win32::Service.send(:remove_const, "DISABLED") if defined?(Win32::Service::DISABLED)
  end

  it "sets the current resources service name to the new resources service name" do
    provider.load_current_resource
    expect(provider.current_resource.service_name).to eq(chef_service_name)
  end

  it "returns the current resource" do
    expect(provider.load_current_resource).to equal(provider.current_resource)
  end

  it "sets the current resources start type" do
    provider.load_current_resource
    expect(provider.current_resource.enabled).to be_truthy
  end

  context "service does not exist" do
    before do
      allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(false)
    end

    %w{running enabled startup_type error_control binary_path_name
      load_order_group dependencies run_as_user display_name }.each do |prop|
        it "does not set #{prop}" do
          expect(provider.current_resource.running).to be_nil
        end
      end
  end

  context "service exists" do
    before do
      allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(true)
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("Struct::ServiceConfigInfo",
          service_type: "share process",
          start_type: "demand start",
          error_control: "normal",
          binary_path_name: 'C:\\Windows\\system32\\svchost.exe -k LocalServiceNetworkRestricted',
          load_order_group: "TDI",
          tag_id: 0,
          dependencies: %w{NSI Tdx Afd},
          service_start_name: 'NT Authority\\LocalService',
          display_name: "DHCP Client")
      )
    end

    context "startup_type is neither :automatic or :disabled" do
      before do
        allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
          double("Struct::ServiceConfigInfo",
            service_type: "share process",
            start_type: "demand start",
            error_control: "normal",
            binary_path_name: 'C:\\Windows\\system32\\svchost.exe -k LocalServiceNetworkRestricted',
            load_order_group: "TDI",
            tag_id: 0,
            dependencies: %w{NSI Tdx Afd},
            service_start_name: 'NT Authority\\LocalService',
            display_name: "DHCP Client")
        )
      end

      it "does not set the current resources enabled" do
        provider.load_current_resource
        expect(provider.current_resource.enabled).to be_nil
      end
    end

    it "sets the current resources running to true if it's running" do
      allow(provider).to receive(:current_state).and_return("running")
      provider.load_current_resource
      expect(provider.current_resource.running).to be true
    end

    it "sets the current resources running to false if it's in any other state" do
      allow(provider).to receive(:current_state).and_return("other state")
      provider.load_current_resource
      expect(provider.current_resource.running).to be false
    end

    it "sets startup_type" do
      expect(provider.current_resource.startup_type).to be_truthy
    end

    it "sets error_control" do
      provider.load_current_resource
      expect(provider.current_resource.error_control).to be_truthy
    end

    it "sets binary_path_name" do
      provider.load_current_resource
      expect(provider.current_resource.binary_path_name).to be_truthy
    end

    it "sets load_order_group" do
      provider.load_current_resource
      expect(provider.current_resource.load_order_group).to be_truthy
    end

    it "sets dependencies" do
      provider.load_current_resource
      expect(provider.current_resource.dependencies).to be_truthy
    end

    it "sets run_as_user" do
      provider.load_current_resource
      expect(provider.current_resource.run_as_user).to be_truthy
    end

    it "sets display_name" do
      provider.load_current_resource
      expect(provider.current_resource.display_name).to be_truthy
    end

    it "sets delayed start to true if delayed start is enabled" do
      allow(Win32::Service).to receive(:delayed_start).with(chef_service_name).and_return(1)
      provider.load_current_resource
      expect(provider.current_resource.delayed_start).to be true
    end

    it "sets delayed start to false if delayed start is disabled" do
      allow(Win32::Service).to receive(:delayed_start).with(chef_service_name).and_return(0)
      provider.load_current_resource
      expect(provider.current_resource.delayed_start).to be false
    end
  end

  describe Chef::Provider::Service::Windows, "action_create" do
    before do
      provider.new_resource.binary_path_name = chef_service_binary_path_name
    end

    context "service exists" do
      before do
        allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(true)
      end

      it "logs debug message" do
        expect(logger).to receive(:debug).with("windows_service[#{chef_service_name}] already exists - nothing to do")
        provider.action_create
      end

      it "does not converge" do
        provider.action_create
        expect(provider.resource_updated?).to be false
      end

      it "does not create service" do
        expect(Win32::Service).to_not receive(:new)
        provider.action_create
      end

      it "does not call converge_delayed_start" do
        expect(provider).to_not receive(:converge_delayed_start)
        provider.action_create
      end
    end

    context "service does not exist" do
      before do
        allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(false)
        allow(Win32::Service).to receive(:new).with(anything).and_return(true)
      end

      it "converges resource" do
        provider.action_create
        expect(provider.resource_updated?).to be true
      end

      it "creates service" do
        expect(Win32::Service).to receive(:new)
        provider.action_create
      end

      it "creates service with correct configuration" do
        expect(Win32::Service).to receive(:new).with(
          service_name: chef_service_name,
          service_type: 16,
          start_type: 2,
          error_control: 1,
          binary_path_name: chef_service_binary_path_name,
          service_start_name: "localsystem",
          desired_access: 983551
        )
        provider.action_create
      end

      it "calls converge_delayed_start" do
        expect(provider).to receive(:converge_delayed_start)
        provider.action_create
      end
    end
  end

  describe Chef::Provider::Service::Windows, "action_delete" do
    context "service exists" do
      before do
        allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(true)
        allow(Win32::Service).to receive(:delete).with(chef_service_name).and_return(true)
      end

      it "converges resource" do
        provider.action_delete
        expect(provider.resource_updated?).to be true
      end

      it "deletes service" do
        expect(Win32::Service).to receive(:delete).with(chef_service_name)
        provider.action_delete
      end
    end

    context "service does not exist" do
      before do
        allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(false)
      end

      it "logs debug message" do
        expect(logger).to receive(:debug).with("windows_service[#{chef_service_name}] does not exist - nothing to do")
        provider.action_delete
      end

      it "does not converge" do
        provider.action_delete
        expect(provider.resource_updated?).to be false
      end

      it "does not delete service" do
        expect(Win32::Service).to_not receive(:delete)
        provider.action_delete
      end
    end
  end

  describe Chef::Provider::Service::Windows, "action_configure" do
    context "service exists" do
      before do
        allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(true)
        allow(Win32::Service).to receive(:configure).with(anything).and_return(true)
      end

      # properties that are Strings
      %i{binary_path_name load_order_group dependencies run_as_user
         display_name description}.each do |attr|
           it "configures service if #{attr} has changed" do
             provider.current_resource.send("#{attr}=", "old value")
             provider.new_resource.send("#{attr}=", "new value")

             expect(Win32::Service).to receive(:configure)
             provider.action_configure
           end
         end

      # properties that are Integers
      %i{service_type error_control}.each do |attr|
        it "configures service if #{attr} has changed" do
          provider.current_resource.send("#{attr}=", 1)
          provider.new_resource.send("#{attr}=", 2)

          expect(Win32::Service).to receive(:configure)
          provider.action_configure
        end
      end

      it "configures service if startup_type has changed" do
        provider.current_resource.startup_type = :automatic
        provider.new_resource.startup_type = :manual

        expect(Win32::Service).to receive(:configure)
        provider.action_configure
      end

      it "does not configure service when run_as_user case is different" do
        provider.current_resource.run_as_user = "JohnDoe"
        provider.new_resource.run_as_user = "johndoe"
        expect(Win32::Service).not_to receive(:configure)
        provider.action_configure

        provider.current_resource.run_as_user = "johndoe"
        provider.new_resource.run_as_user = "JohnDoe"
        expect(Win32::Service).not_to receive(:configure)
        provider.action_configure
      end

      it "calls converge_delayed_start" do
        expect(provider).to receive(:converge_delayed_start)
        provider.action_configure
      end
    end

    context "service does not exist" do
      let(:missing_service_warning_message) { "windows_service[#{chef_service_name}] does not exist. Maybe you need to prepend action :create" }

      before do
        allow(Win32::Service).to receive(:exists?).with(chef_service_name).and_return(false)

        # This prevents warnings being logged during unit tests which adds to
        # developer confusion when they aren't familiar with this specific test
        allow(logger).to receive(:warn).with(missing_service_warning_message)
      end

      it "logs warning" do
        expect(logger).to receive(:warn).with(missing_service_warning_message)
        provider.action_configure
      end

      it "does not converge" do
        provider.action_configure
        expect(provider.resource_updated?).to be false
      end

      it "does not configure service" do
        expect(Win32::Service).to_not receive(:configure)
        provider.action_configure
      end

      it "does not call converge_delayed_start" do
        expect(provider).to_not receive(:converge_delayed_start)
        provider.action_configure
      end
    end
  end

  describe Chef::Provider::Service::Windows, "converge_delayed_start" do
    before do
      allow(Win32::Service).to receive(:configure).and_return(true)
    end

    context "delayed start needs to be updated" do
      before do
        provider.current_resource.delayed_start = false
        provider.new_resource.delayed_start = true
      end

      it "configures delayed start" do
        expect(Win32::Service).to receive(:configure)
        provider.send(:converge_delayed_start)
      end

      it "configures delayed start with correct params" do
        expect(Win32::Service).to receive(:configure).with(service_name: chef_service_name, delayed_start: 1)
        provider.send(:converge_delayed_start)
      end

      it "converges resource" do
        provider.send(:converge_delayed_start)
        expect(provider.resource_updated?).to be true
      end
    end

    context "delayed start does not need to be updated" do
      before do
        provider.current_resource.delayed_start = false
        provider.new_resource.delayed_start = false
      end

      it "does not configure delayed start" do
        expect(Win32::Service).to_not receive(:configure)
        provider.send(:converge_delayed_start)
      end

      it "does not converge" do
        provider.send(:converge_delayed_start)
        expect(provider.resource_updated?).to be false
      end
    end
  end

  describe Chef::Provider::Service::Windows, "start_service" do
    before(:each) do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "stopped"),
        double("StatusStruct", current_state: "running")
      )
    end

    context "run_as_user user is specified" do
      let(:run_as_user) { provider.new_resource.class.properties[:run_as_user].default }

      before do
        provider.new_resource.run_as_user run_as_user
      end

      it "configures service run_as_user and run_as_password" do
        expect(provider).to receive(:configure_service_run_as_properties).and_call_original
        expect(Win32::Service).to receive(:configure)
        provider.start_service
      end
    end

    context "run_as_user user is not specified" do
      before do
        expect(provider.new_resource.property_is_set?(:run_as_user)).to be false
      end

      it "does not configure service run_as_user and run_as_password" do
        expect(Win32::Service).not_to receive(:configure)
        provider.start_service
      end
    end

    context "start_command is specified" do
      let(:start_command) { "sc start #{chef_service_name}" }

      before do
        new_resource.start_command start_command
        allow(provider).to receive(:shell_out!).with(start_command)
      end

      it "shells out the start_command" do
        expect(provider).to receive(:shell_out!).with(start_command)
        provider.start_service
      end

      it "does not call Win32::Service.start" do
        expect(Win32::Service).not_to receive(:start)
        provider.start_service
      end

      it "is updated by last action" do
        provider.start_service
        expect(new_resource).to be_updated_by_last_action
      end
    end

    context "start_command is not specified" do
      before do
        expect(new_resource.start_command).to be_nil
      end

      it "uses the built-in command" do
        expect(Win32::Service).to receive(:start).with(new_resource.service_name)
        provider.start_service
      end

      it "does not shell out the start_command" do
        expect(provider).not_to receive(:shell_out!)
        provider.start_service
      end

      it "is updated by last action" do
        provider.start_service
        expect(new_resource).to be_updated_by_last_action
      end
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:start)
      provider.start_service
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "does nothing if the service is running" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "running")
      )
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      provider.start_service
      expect(new_resource).not_to be_updated_by_last_action
    end

    context "service is paused" do
      before do
        allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
          double("StatusStruct", current_state: "paused")
        )
        provider.load_current_resource
      end

      it "raises error" do
        expect { provider.start_service }.to raise_error(Chef::Exceptions::Service)
      end

      it "does not start service" do
        expect(Win32::Service).not_to receive(:start)
        expect(provider).not_to receive(:shell_out!)
        expect { provider.start_service }.to raise_error(Chef::Exceptions::Service)
      end

      it "is not updated by last action" do
        expect { provider.start_service }.to raise_error(Chef::Exceptions::Service)
        expect(new_resource).not_to be_updated_by_last_action
      end
    end

    context "service is in start_pending" do
      before do
        allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
          double("StatusStruct", current_state: "start pending"),
          double("StatusStruct", current_state: "start pending"),
          double("StatusStruct", current_state: "running")
        )
        provider.load_current_resource
      end

      it "waits until service is running" do
        expect(provider).to receive(:wait_for_state).with(Chef::Provider::Service::Windows::RUNNING)
        provider.start_service
      end

      it "does not start service" do
        expect(Win32::Service).not_to receive(:start)
        expect(provider).not_to receive(:shell_out!)
        provider.start_service
      end

      it "is not updated by last action" do
        provider.start_service
        expect(new_resource).not_to be_updated_by_last_action
      end
    end

    context "service is in stop_pending" do
      before do
        allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
          double("StatusStruct", current_state: "stop pending")
        )
        provider.load_current_resource
      end

      it "raises error" do
        expect { provider.start_service }.to raise_error(Chef::Exceptions::Service)
      end

      it "does not start service" do
        expect(Win32::Service).not_to receive(:start)
        expect(provider).not_to receive(:shell_out!)
        expect { provider.start_service }.to raise_error(Chef::Exceptions::Service)
      end

      it "is not updated by last action" do
        expect { provider.start_service }.to raise_error(Chef::Exceptions::Service)
        expect(new_resource).not_to be_updated_by_last_action
      end
    end

    describe "running as a different account" do
      before do
        new_resource.run_as_user(".\\wallace")
        new_resource.run_as_password("Wensleydale")
      end

      it "calls #grant_service_logon if the :run_as_user and :run_as_password properties are present" do
        expect(provider).to receive(:grant_service_logon).and_return(true)
        provider.start_service
      end

      it "does not grant user SeServiceLogonRight if it already has it" do
        expect(Chef::ReservedNames::Win32::Security).to receive(:get_account_right).with("wallace").and_return([service_right])
        expect(Chef::ReservedNames::Win32::Security).not_to receive(:add_account_right).with("wallace", service_right)
        provider.start_service
      end

      it "skips the rights check for LocalSystem" do
        new_resource.run_as_user("LocalSystem")
        expect(Chef::ReservedNames::Win32::Security).not_to receive(:get_account_right)
        expect(Chef::ReservedNames::Win32::Security).not_to receive(:add_account_right)
        provider.start_service
      end
    end
  end

  describe Chef::Provider::Service::Windows, "stop_service" do

    before(:each) do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "running"),
        double("StatusStruct", current_state: "stopped")
      )
    end

    it "calls the stop command if one is specified" do
      new_resource.stop_command "sc stop #{chef_service_name}"
      expect(provider).to receive(:shell_out!).with((new_resource.stop_command).to_s).and_return("Stopping custom service")
      provider.stop_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "uses the built-in command if no stop command is specified" do
      expect(Win32::Service).to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource).to_not be_updated_by_last_action
    end

    it "does nothing if the service is stopped" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "stopped")
      )
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource).to_not be_updated_by_last_action
    end

    it "raises an error if the service is paused" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "paused")
      )
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      expect { provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      expect(new_resource).to_not be_updated_by_last_action
    end

    it "waits and continue if the service is in stop_pending" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "stop pending"),
        double("StatusStruct", current_state: "stop pending"),
        double("StatusStruct", current_state: "stopped")
      )
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      provider.stop_service
      expect(new_resource).to_not be_updated_by_last_action
    end

    it "fails if the service is in start_pending" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "start pending")
      )
      provider.load_current_resource
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      expect { provider.stop_service }.to raise_error( Chef::Exceptions::Service )
      expect(new_resource).to_not be_updated_by_last_action
    end

    it "passes custom timeout to the stop command if provided" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "running")
      )
      new_resource.timeout 1
      expect(Win32::Service).to receive(:stop).with(new_resource.service_name)
      Timeout.timeout(2) do
        expect { provider.stop_service }.to raise_error(Timeout::Error)
      end
      expect(new_resource).to_not be_updated_by_last_action
    end

  end

  describe Chef::Provider::Service::Windows, "restart_service" do

    it "calls the restart command if one is specified" do
      new_resource.restart_command "sc restart"
      expect(provider).to receive(:shell_out!).with((new_resource.restart_command).to_s)
      provider.restart_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "stops then starts the service if it is running" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "running"),
        double("StatusStruct", current_state: "stopped"),
        double("StatusStruct", current_state: "stopped"),
        double("StatusStruct", current_state: "running")
      )
      expect(Win32::Service).to receive(:stop).with(new_resource.service_name)
      expect(Win32::Service).to receive(:start).with(new_resource.service_name)
      provider.restart_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "just starts the service if it is stopped" do
      allow(Win32::Service).to receive(:status).with(new_resource.service_name).and_return(
        double("StatusStruct", current_state: "stopped"),
        double("StatusStruct", current_state: "stopped"),
        double("StatusStruct", current_state: "running")
      )
      expect(Win32::Service).to receive(:start).with(new_resource.service_name)
      provider.restart_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:stop).with(new_resource.service_name)
      expect(Win32::Service).not_to receive(:start).with(new_resource.service_name)
      provider.restart_service
      expect(new_resource).to_not be_updated_by_last_action
    end

  end

  describe Chef::Provider::Service::Windows, "enable_service" do
    before(:each) do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", start_type: "disabled")
      )
    end

    it "enables service" do
      expect(Win32::Service).to receive(:configure).with(service_name: new_resource.service_name, start_type: Win32::Service::AUTO_START)
      provider.enable_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:configure)
      provider.enable_service
      expect(new_resource).to_not be_updated_by_last_action
    end
  end

  describe Chef::Provider::Service::Windows, "action_enable" do
    it "does nothing if the service is enabled" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", start_type: "auto start")
      )
      expect(provider).not_to receive(:enable_service)
      provider.action_enable
    end

    it "enables the service if it is not set to automatic start" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", start_type: "disabled")
      )
      expect(provider).to receive(:enable_service)
      provider.action_enable
    end
  end

  describe Chef::Provider::Service::Windows, "action_disable" do
    it "does nothing if the service is disabled" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", start_type: "disabled")
      )
      expect(provider).not_to receive(:disable_service)
      provider.action_disable
    end

    it "disables the service if it is not set to disabled" do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", start_type: "auto start")
      )
      expect(provider).to receive(:disable_service)
      provider.action_disable
    end
  end

  describe Chef::Provider::Service::Windows, "disable_service" do
    before(:each) do
      allow(Win32::Service).to receive(:config_info).with(new_resource.service_name).and_return(
        double("ConfigStruct", start_type: "auto start")
      )
    end

    it "disables service" do
      expect(Win32::Service).to receive(:configure)
      provider.disable_service
      expect(new_resource).to be_updated_by_last_action
    end

    it "does nothing if the service does not exist" do
      allow(Win32::Service).to receive(:exists?).with(new_resource.service_name).and_return(false)
      expect(Win32::Service).not_to receive(:configure)
      provider.disable_service
      expect(new_resource).to_not be_updated_by_last_action
    end
  end

  describe Chef::Provider::Service::Windows, "action_configure_startup" do
    %i{automatic manual disabled}.each do |type|
      it "sets the startup type to #{type} if it is something else" do
        new_resource.startup_type(type)
        allow(provider).to receive(:current_startup_type).and_return(:fire)
        expect(provider).to receive(:set_startup_type).with(type)
        provider.action_configure_startup
      end

      it "leaves the startup type as #{type} if it is already set" do
        new_resource.startup_type(type)
        allow(provider).to receive(:current_startup_type).and_return(type)
        expect(provider).not_to receive(:set_startup_type).with(type)
        provider.action_configure_startup
      end
    end

    it "calls converge_delayed_start" do
      expect(provider).to receive(:converge_delayed_start)
      provider.action_configure_startup
    end
  end

  describe Chef::Provider::Service::Windows, "set_start_type" do
    it "when called with :automatic it calls Win32::Service#configure with Win32::Service::AUTO_START" do
      expect(Win32::Service).to receive(:configure).with(service_name: new_resource.service_name, start_type: Win32::Service::AUTO_START)
      provider.send(:set_startup_type, :automatic)
    end

    it "when called with :manual it calls Win32::Service#configure with Win32::Service::DEMAND_START" do
      expect(Win32::Service).to receive(:configure).with(service_name: new_resource.service_name, start_type: Win32::Service::DEMAND_START)
      provider.send(:set_startup_type, :manual)
    end

    it "when called with :disabled it calls Win32::Service#configure with Win32::Service::DISABLED" do
      expect(Win32::Service).to receive(:configure).with(service_name: new_resource.service_name, start_type: Win32::Service::DISABLED)
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
