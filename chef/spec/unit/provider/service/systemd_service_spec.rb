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
  include SpecHelpers::Providers::Service

  let(:service_name) { 'rsyslog.service' }
  let(:new_resource) { Chef::Resource::Service.new(service_name) }

  describe "#load_current_resource" do
    before(:each) do
      provider.stub!(:is_active?).and_return(false)
      provider.stub!(:is_enabled?).and_return(false)
    end

    let(:new_resource) { current_resource }

    it "should create a current resource with the name of the new resource" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.load_current_resource
      provider.current_resource.should equal(current_resource)
    end

    it "should set the current resources service name to the new resources service name" do
      provider.load_current_resource
      current_resource.service_name.should eql(service_name)
    end

    it "should check if the service is running" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.should_receive(:is_active?)
      provider.load_current_resource
    end

    it "should set running to true if the service is running" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.stub!(:is_active?).and_return(true)
      current_resource.should_receive(:running).with(true)
      provider.load_current_resource
    end

    it "should set running to false if the service is not running" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.stub!(:is_active?).and_return(false)
      current_resource.should_receive(:running).with(false)
      provider.load_current_resource
    end

    context "when a status command has been specified" do
      before do
        new_resource.stub!(:status_command).and_return("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        Chef::Resource::Service.stub!(:new).and_return(current_resource)
        provider.stub!(:shell_out_with_systems_locale!).with("/bin/chefhasmonkeypants status").and_return(0)
        current_resource.should_receive(:running).with(true)
        provider.load_current_resource
      end

      it "should set running to false if it catches a Chef::Exceptions::Exec when using a status command" do
        Chef::Resource::Service.stub!(:new).and_return(current_resource)
        provider.stub!(:shell_out_with_systems_locale!).and_raise(Chef::Exceptions::Exec)
        current_resource.should_receive(:running).with(false)
        provider.load_current_resource
      end
    end

    it "should check if the service is enabled" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.should_receive(:is_enabled?)
      provider.load_current_resource
    end

    it "should set enabled to true if the service is enabled" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.stub!(:is_enabled?).and_return(true)
      current_resource.should_receive(:enabled).with(true)
      provider.load_current_resource
    end

    it "should set enabled to false if the service is not enabled" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.stub!(:is_enabled?).and_return(false)
      current_resource.should_receive(:enabled).with(false)
      provider.load_current_resource
    end

    it "should return the current resource" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.load_current_resource.should eql(current_resource)
    end
  end

  context "start and stop service" do
    before(:each) do
      provider.current_resource = current_resource
    end

    let(:new_resource) { Chef::Resource::Service.new(service_name) }

    it "should call the start command if one is specified" do
      new_resource.stub!(:start_command).and_return("/sbin/rsyslog startyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog startyousillysally")
      provider.start_service
    end

    it "should call '/bin/systemctl start service_name' if no start command is specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("/bin/systemctl start #{new_resource.service_name}").and_return(0)
      provider.start_service
    end

    it "should not call '/bin/systemctl start service_name' if it is already running" do
      current_resource.stub!(:running).and_return(true)
      provider.should_not_receive(:shell_out_with_systems_locale!).with("/bin/systemctl start #{new_resource.service_name}").and_return(0)
      provider.start_service
    end

    it "should call the restart command if one is specified" do
      current_resource.stub!(:running).and_return(true)
      new_resource.stub!(:restart_command).and_return("/sbin/rsyslog restartyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog restartyousillysally")
      provider.restart_service
    end

    it "should call '/bin/systemctl restart service_name' if no restart command is specified" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:shell_out_with_systems_locale!).with("/bin/systemctl restart #{new_resource.service_name}").and_return(0)
      provider.restart_service
    end

    it "should call the reload command if one is specified" do
      current_resource.stub!(:running).and_return(true)
      new_resource.stub!(:reload_command).and_return("/sbin/rsyslog reloadyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog reloadyousillysally")
      provider.reload_service
    end

    it "should call '/bin/systemctl reload service_name' if no reload command is specified" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:shell_out_with_systems_locale!).with("/bin/systemctl reload #{new_resource.service_name}").and_return(0)
      provider.reload_service
    end

    it "should call the stop command if one is specified" do
      current_resource.stub!(:running).and_return(true)
      new_resource.stub!(:stop_command).and_return("/sbin/rsyslog stopyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog stopyousillysally")
      provider.stop_service
    end

    it "should call '/bin/systemctl stop service_name' if no stop command is specified" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:shell_out_with_systems_locale!).with("/bin/systemctl stop #{new_resource.service_name}").and_return(0)
      provider.stop_service
    end

    it "should not call '/bin/systemctl stop service_name' if it is already stopped" do
      current_resource.stub!(:running).and_return(false)
      provider.should_not_receive(:shell_out_with_systems_locale!).with("/bin/systemctl stop #{new_resource.service_name}").and_return(0)
      provider.stop_service
    end
  end

  context "enable and disable service" do
    before(:each) do
      provider.current_resource = current_resource
    end

    let(:new_resource) { Chef::Resource::Service.new(service_name) }

    it "should call '/bin/systemctl enable service_name' to enable the service" do
      provider.should_receive(:shell_out_with_systems_locale!).with("/bin/systemctl enable #{new_resource.service_name}").and_return(0)
      provider.enable_service
    end

    it "should call '/bin/systemctl disable service_name' to disable the service" do
      provider.should_receive(:shell_out_with_systems_locale!).with("/bin/systemctl disable #{new_resource.service_name}").and_return(0)
      provider.disable_service
    end
  end

  describe "#is_active?" do

    it "should return true if '/bin/systemctl is-active service_name' returns 0" do
      provider.should_receive(:shell_out_with_systems_locale).with('/bin/systemctl is-active rsyslog.service').and_return(0)
      provider.is_active?.should be_true
    end

    it "should return false if '/bin/systemctl is-active service_name' returns anything except 0" do
      provider.should_receive(:shell_out_with_systems_locale).with('/bin/systemctl is-active rsyslog.service').and_return(1)
      provider.is_active?.should be_false
    end
  end

  describe "#is_enabled?" do
    let(:new_resource) { Chef::Resource::Service.new(service_name) }

    it "should return true if '/bin/systemctl is-enabled service_name' returns 0" do
      provider.should_receive(:shell_out_with_systems_locale).with('/bin/systemctl is-enabled rsyslog.service').and_return(0)
      provider.is_enabled?.should be_true
    end

    it "should return false if '/bin/systemctl is-enabled service_name' returns anything except 0" do
      provider.should_receive(:shell_out_with_systems_locale).with('/bin/systemctl is-enabled rsyslog.service').and_return(1)
      provider.is_enabled?.should be_false
    end
  end
end
