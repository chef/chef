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

    @shell_out_success = double('shell_out_with_systems_locale',
                                :exitstatus => 0, :error? => false)
    @shell_out_failure = double('shell_out_with_systems_locale',
                                :exitstatus => 1, :error? => true)
  end

  describe "load_current_resource" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)

      allow(@provider).to receive(:is_active?).and_return(false)
      allow(@provider).to receive(:is_enabled?).and_return(false)
    end

    it "should create a current resource with the name of the new resource" do
      expect(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      expect(@current_resource).to receive(:service_name).with(@new_resource.service_name)
      @provider.load_current_resource
    end

    it "should check if the service is running" do
      expect(@provider).to receive(:is_active?)
      @provider.load_current_resource
    end

    it "should set running to true if the service is running" do
      allow(@provider).to receive(:is_active?).and_return(true)
      expect(@current_resource).to receive(:running).with(true)
      @provider.load_current_resource
    end

    it "should set running to false if the service is not running" do
      allow(@provider).to receive(:is_active?).and_return(false)
      expect(@current_resource).to receive(:running).with(false)
      @provider.load_current_resource
    end

    describe "when a status command has been specified" do
      before do
        allow(@new_resource).to receive(:status_command).and_return("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        allow(@provider).to receive(:shell_out).and_return(@shell_out_success)
        expect(@current_resource).to receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should run the services status command if one has been specified and properly set status check state" do
        allow(@provider).to receive(:shell_out).with("/bin/chefhasmonkeypants status").and_return(@shell_out_success)
        @provider.load_current_resource
        expect(@provider.instance_variable_get("@status_check_success")).to be_true
      end

      it "should set running to false if a status command fails" do
        allow(@provider).to receive(:shell_out).and_return(@shell_out_failure)
        expect(@current_resource).to receive(:running).with(false)
        @provider.load_current_resource
      end

      it "should update state to indicate status check failed when a status command fails" do
        allow(@provider).to receive(:shell_out).and_return(@shell_out_failure)
        @provider.load_current_resource
        expect(@provider.instance_variable_get("@status_check_success")).to be_false
      end
    end

    it "should check if the service is enabled" do
      expect(@provider).to receive(:is_enabled?)
      @provider.load_current_resource
    end

    it "should set enabled to true if the service is enabled" do
      allow(@provider).to receive(:is_enabled?).and_return(true)
      expect(@current_resource).to receive(:enabled).with(true)
      @provider.load_current_resource
    end

    it "should set enabled to false if the service is not enabled" do
      allow(@provider).to receive(:is_enabled?).and_return(false)
      expect(@current_resource).to receive(:enabled).with(false)
      @provider.load_current_resource
    end

    it "should return the current resource" do
      expect(@provider.load_current_resource).to eql(@current_resource)
    end
  end

  describe "start and stop service" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
    end

    it "should call the start command if one is specified" do
      allow(@new_resource).to receive(:start_command).and_return("/sbin/rsyslog startyousillysally")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/sbin/rsyslog startyousillysally")
      @provider.start_service
    end

    it "should call '/bin/systemctl start service_name' if no start command is specified" do
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/bin/systemctl start #{@new_resource.service_name}").and_return(@shell_out_success)
      @provider.start_service
    end

    it "should not call '/bin/systemctl start service_name' if it is already running" do
      allow(@current_resource).to receive(:running).and_return(true)
      expect(@provider).not_to receive(:shell_out_with_systems_locale!).with("/bin/systemctl start #{@new_resource.service_name}")
      @provider.start_service
    end

    it "should call the restart command if one is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      allow(@new_resource).to receive(:restart_command).and_return("/sbin/rsyslog restartyousillysally")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/sbin/rsyslog restartyousillysally")
      @provider.restart_service
    end

    it "should call '/bin/systemctl restart service_name' if no restart command is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/bin/systemctl restart #{@new_resource.service_name}").and_return(@shell_out_success)
      @provider.restart_service
    end

    describe "reload service" do
      context "when a reload command is specified" do
        it "should call the reload command" do
          allow(@current_resource).to receive(:running).and_return(true)
          allow(@new_resource).to receive(:reload_command).and_return("/sbin/rsyslog reloadyousillysally")
          expect(@provider).to receive(:shell_out_with_systems_locale!).with("/sbin/rsyslog reloadyousillysally")
          @provider.reload_service
        end
      end

      context "when a reload command is not specified" do
        it "should call '/bin/systemctl reload service_name' if the service is running" do
          allow(@current_resource).to receive(:running).and_return(true)
          expect(@provider).to receive(:shell_out_with_systems_locale!).with("/bin/systemctl reload #{@new_resource.service_name}").and_return(@shell_out_success)
          @provider.reload_service
        end

        it "should start the service if the service is not running" do
          allow(@current_resource).to receive(:running).and_return(false)
          expect(@provider).to receive(:start_service).and_return(true)
          @provider.reload_service
        end
      end
    end

    it "should call the stop command if one is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      allow(@new_resource).to receive(:stop_command).and_return("/sbin/rsyslog stopyousillysally")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/sbin/rsyslog stopyousillysally")
      @provider.stop_service
    end

    it "should call '/bin/systemctl stop service_name' if no stop command is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/bin/systemctl stop #{@new_resource.service_name}").and_return(@shell_out_success)
      @provider.stop_service
    end

    it "should not call '/bin/systemctl stop service_name' if it is already stopped" do
      allow(@current_resource).to receive(:running).and_return(false)
      expect(@provider).not_to receive(:shell_out_with_systems_locale!).with("/bin/systemctl stop #{@new_resource.service_name}")
      @provider.stop_service
    end
  end

  describe "enable and disable service" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
    end

    it "should call '/bin/systemctl enable service_name' to enable the service" do
      expect(@provider).to receive(:shell_out!).with("/bin/systemctl enable #{@new_resource.service_name}").and_return(@shell_out_success)
      @provider.enable_service
    end

    it "should call '/bin/systemctl disable service_name' to disable the service" do
      expect(@provider).to receive(:shell_out!).with("/bin/systemctl disable #{@new_resource.service_name}").and_return(@shell_out_success)
      @provider.disable_service
    end
  end

  describe "is_active?" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
    end

    it "should return true if '/bin/systemctl is-active service_name' returns 0" do
      expect(@provider).to receive(:shell_out).with('/bin/systemctl is-active rsyslog.service --quiet').and_return(@shell_out_success)
      expect(@provider.is_active?).to be_true
    end

    it "should return false if '/bin/systemctl is-active service_name' returns anything except 0" do
      expect(@provider).to receive(:shell_out).with('/bin/systemctl is-active rsyslog.service --quiet').and_return(@shell_out_failure)
      expect(@provider.is_active?).to be_false
    end
  end

  describe "is_enabled?" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new('rsyslog.service')
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
    end

    it "should return true if '/bin/systemctl is-enabled service_name' returns 0" do
      expect(@provider).to receive(:shell_out).with('/bin/systemctl is-enabled rsyslog.service --quiet').and_return(@shell_out_success)
      expect(@provider.is_enabled?).to be_true
    end

    it "should return false if '/bin/systemctl is-enabled service_name' returns anything except 0" do
      expect(@provider).to receive(:shell_out).with('/bin/systemctl is-enabled rsyslog.service --quiet').and_return(@shell_out_failure)
      expect(@provider.is_enabled?).to be_false
    end
  end
end
