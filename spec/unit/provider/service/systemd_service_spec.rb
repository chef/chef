#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

describe Chef::Provider::Service::Systemd do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Service.new('rsyslog.service')
    @provider = Chef::Provider::Service::Systemd.new(@new_resource, @run_context)
  end

  describe "load_current_resource" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      Chef::Resource::Service.stub!(:new).and_return(@current_resource)

      @provider.stub!(:is_active?).and_return(false)
      @provider.stub!(:is_enabled?).and_return(false)
    end

    it "should create a current resource with the name of the new resource" do
      Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      @current_resource.should_receive(:service_name).with(@new_resource.service_name)
      @provider.load_current_resource
    end

    it "should check if the service is running" do
      @provider.should_receive(:is_active?)
      @provider.load_current_resource
    end

    it "should set running to true if the service is running" do
      @provider.stub!(:is_active?).and_return(true)
      @current_resource.should_receive(:running).with(true)
      @provider.load_current_resource
    end

    it "should set running to false if the service is not running" do
      @provider.stub!(:is_active?).and_return(false)
      @current_resource.should_receive(:running).with(false)
      @provider.load_current_resource
    end

    describe "when a status command has been specified" do
      before do
        @new_resource.stub!(:status_command).and_return("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        @provider.stub!(:run_command_with_systems_locale).with({:command => "/bin/chefhasmonkeypants status"}).and_return(0)
        @current_resource.should_receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should run the services status command if one has been specified and properly set status check state" do
        @provider.stub!(:run_command_with_systems_locale).with({:command => "/bin/chefhasmonkeypants status"}).and_return(0)
        @provider.load_current_resource
        @provider.instance_variable_get("@status_check_success").should be_true
      end
      
      it "should set running to false if it catches a Chef::Exceptions::Exec when using a status command" do
        @provider.stub!(:run_command_with_systems_locale).and_raise(Chef::Exceptions::Exec)
        @current_resource.should_receive(:running).with(false)
        @provider.load_current_resource
      end
    
      it "should update state to indicate status check failed when an exception is thrown using a status command" do
        @provider.stub!(:run_command_with_systems_locale).and_raise(Chef::Exceptions::Exec)
        @provider.load_current_resource
        @provider.instance_variable_get("@status_check_success").should be_false
      end
    end 

    it "should check if the service is enabled" do
      @provider.should_receive(:is_enabled?)
      @provider.load_current_resource
    end

    it "should set enabled to true if the service is enabled" do
      @provider.stub!(:is_enabled?).and_return(true)
      @current_resource.should_receive(:enabled).with(true)
      @provider.load_current_resource
    end

    it "should set enabled to false if the service is not enabled" do
      @provider.stub!(:is_enabled?).and_return(false)
      @current_resource.should_receive(:enabled).with(false)
      @provider.load_current_resource
    end

    it "should return the current resource" do
      @provider.load_current_resource.should eql(@current_resource)
    end
  end

  describe "start and stop service" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
    end

    it "should call the start command if one is specified" do
      @new_resource.stub!(:start_command).and_return("/sbin/rsyslog startyousillysally")
      @provider.should_receive(:shell_out!).with("/sbin/rsyslog startyousillysally")
      @provider.start_service
    end

    it "should call '/bin/systemctl start service_name' if no start command is specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl start #{@new_resource.service_name}"}).and_return(0)
      @provider.start_service
    end

    it "should not call '/bin/systemctl start service_name' if it is already running" do
      @current_resource.stub!(:running).and_return(true)
      @provider.should_not_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl start #{@new_resource.service_name}"})
      @provider.start_service
    end

    it "should call the restart command if one is specified" do
      @current_resource.stub!(:running).and_return(true)
      @new_resource.stub!(:restart_command).and_return("/sbin/rsyslog restartyousillysally")
      @provider.should_receive(:shell_out!).with("/sbin/rsyslog restartyousillysally")
      @provider.restart_service
    end

    it "should call '/bin/systemctl restart service_name' if no restart command is specified" do
      @current_resource.stub!(:running).and_return(true)
      @provider.should_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl restart #{@new_resource.service_name}"}).and_return(0)
      @provider.restart_service
    end

    it "should call the reload command if one is specified" do
      @current_resource.stub!(:running).and_return(true)
      @new_resource.stub!(:reload_command).and_return("/sbin/rsyslog reloadyousillysally")
      @provider.should_receive(:shell_out!).with("/sbin/rsyslog reloadyousillysally")
      @provider.reload_service
    end

    it "should call '/bin/systemctl reload service_name' if no reload command is specified" do
      @current_resource.stub!(:running).and_return(true)
      @provider.should_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl reload #{@new_resource.service_name}"}).and_return(0)
      @provider.reload_service
    end

    it "should call the stop command if one is specified" do
      @current_resource.stub!(:running).and_return(true)
      @new_resource.stub!(:stop_command).and_return("/sbin/rsyslog stopyousillysally")
      @provider.should_receive(:shell_out!).with("/sbin/rsyslog stopyousillysally")
      @provider.stop_service
    end

    it "should call '/bin/systemctl stop service_name' if no stop command is specified" do
      @current_resource.stub!(:running).and_return(true)
      @provider.should_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl stop #{@new_resource.service_name}"}).and_return(0)
      @provider.stop_service
    end

    it "should not call '/bin/systemctl stop service_name' if it is already stopped" do
      @current_resource.stub!(:running).and_return(false)
      @provider.should_not_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl stop #{@new_resource.service_name}"})
      @provider.stop_service
    end
  end

  describe "enable and disable service" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
    end

    it "should call '/bin/systemctl enable service_name' to enable the service" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl enable #{@new_resource.service_name}"}).and_return(0)
      @provider.enable_service
    end

    it "should call '/bin/systemctl disable service_name' to disable the service" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => "/bin/systemctl disable #{@new_resource.service_name}"}).and_return(0)
      @provider.disable_service
    end
  end

  describe "is_active?" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    end

    it "should return true if '/bin/systemctl is-active service_name' returns 0" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => '/bin/systemctl is-active rsyslog.service', :ignore_failure => true}).and_return(0)
      @provider.is_active?.should be_true
    end

    it "should return false if '/bin/systemctl is-active service_name' returns anything except 0" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => '/bin/systemctl is-active rsyslog.service', :ignore_failure => true}).and_return(1)
      @provider.is_active?.should be_false
    end
  end

  describe "is_enabled?" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    end

    it "should return true if '/bin/systemctl is-enabled service_name' returns 0" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => '/bin/systemctl is-enabled rsyslog.service', :ignore_failure => true}).and_return(0)
      @provider.is_enabled?.should be_true
    end

    it "should return false if '/bin/systemctl is-enabled service_name' returns anything except 0" do
      @provider.should_receive(:run_command_with_systems_locale).with({:command => '/bin/systemctl is-enabled rsyslog.service', :ignore_failure => true}).and_return(1)
      @provider.is_enabled?.should be_false
    end
  end
end
