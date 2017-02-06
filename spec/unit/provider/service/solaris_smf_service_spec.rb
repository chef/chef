#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
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

describe Chef::Provider::Service::Solaris do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")

    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Solaris.new(@new_resource, @run_context)
    allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)

    # enabled / started service (svcs -l chef)
    enabled_svc_stdout = [
      "fmri         svc:/application/chef:default",
      "name         chef service",
      "enabled      true",
      "state        online",
      "next_state   none",
      "state_time   April  2, 2015 04:25:19 PM EDT",
      "logfile      /var/svc/log/application-chef:default.log",
      "restarter    svc:/system/svc/restarter:default",
      "contract_id  1115271",
      "dependency   require_all/error svc:/milestone/multi-user:default (online)",
    ].join("\n")

    # disabled / stopped service (svcs -l chef)
    disabled_svc_stdout = [
      "fmri         svc:/application/chef:default",
      "name         chef service",
      "enabled      false",
      "state        disabled",
      "next_state   none",
      "state_time   April  2, 2015 04:25:19 PM EDT",
      "logfile      /var/svc/log/application-chef:default.log",
      "restarter    svc:/system/svc/restarter:default",
      "contract_id  1115271",
      "dependency   require_all/error svc:/milestone/multi-user:default (online)",
    ].join("\n")

    # disabled / stopped service (svcs -l chef)
    maintenance_svc_stdout = [
      "fmri         svc:/application/chef:default",
      "name         chef service",
      "enabled      true",
      "state        maintenance",
      "next_state   none",
      "state_time   April  2, 2015 04:25:19 PM EDT",
      "logfile      /var/svc/log/application-chef:default.log",
      "restarter    svc:/system/svc/restarter:default",
      "contract_id  1115271",
      "dependency   require_all/error svc:/milestone/multi-user:default (online)",
    ].join("\n")

    # shell_out! return value for a service that is running
    @enabled_svc_status = double("Status", :exitstatus => 0, :stdout => enabled_svc_stdout, :stdin => "", :stderr => "")

    # shell_out! return value for a service that is disabled
    @disabled_svc_status = double("Status", :exitstatus => 0, :stdout => disabled_svc_stdout, :stdin => "", :stderr => "")

    # shell_out! return value for a service that is in maintenance mode
    @maintenance_svc_status = double("Status", :exitstatus => 0, :stdout => maintenance_svc_stdout, :stdin => "", :stderr => "")

    # shell_out! return value for a service that does not exist
    @no_svc_status = double("Status", :exitstatus => 1, :stdout => "", :stdin => "", :stderr => "svcs: Pattern 'chef' doesn't match any instances\n")

    # shell_out! return value for a successful execution
    @success = double("clear", :exitstatus => 0, :stdout => "", :stdin => "", :stderr => "")
  end

  it "should raise an error if /bin/svcs and /usr/sbin/svcadm are not executable" do
    allow(File).to receive(:executable?).with("/bin/svcs").and_return(false)
    allow(File).to receive(:executable?).with("/usr/sbin/svcadm").and_return(false)
    expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Service)
  end

  it "should raise an error if /bin/svcs is not executable" do
    allow(File).to receive(:executable?).with("/bin/svcs").and_return(false)
    allow(File).to receive(:executable?).with("/usr/sbin/svcadm").and_return(true)
    expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Service)
  end

  it "should raise an error if /usr/sbin/svcadm is not executable" do
    allow(File).to receive(:executable?).with("/bin/svcs").and_return(true)
    allow(File).to receive(:executable?).with("/usr/sbin/svcadm").and_return(false)
    expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Service)
  end

  describe "on a host with /bin/svcs and /usr/sbin/svcadm" do

    before do
      allow(File).to receive(:executable?).with("/bin/svcs").and_return(true)
      allow(File).to receive(:executable?).with("/usr/sbin/svcadm").and_return(true)
    end

    describe "when discovering the current service state" do
      it "should create a current resource with the name of the new resource" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        expect(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
        @provider.load_current_resource
      end

      it "should return the current resource" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        expect(@provider.load_current_resource).to eql(@current_resource)
      end

      it "should call '/bin/svcs -l service_name'" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        @provider.load_current_resource
      end

      it "should mark service as not running" do
        expect(@provider).to receive(:shell_out!).and_return(@disabled_svc_status)
        expect(@current_resource).to receive(:running).with(false)
        @provider.load_current_resource
      end

      it "should mark service as running" do
        expect(@provider).to receive(:shell_out!).and_return(@enabled_svc_status)
        expect(@current_resource).to receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should not mark service as maintenance" do
        expect(@provider).to receive(:shell_out!).and_return(@enabled_svc_status)
        @provider.load_current_resource
        expect(@provider.maintenance).to be_falsey
      end

      it "should mark service as maintenance" do
        expect(@provider).to receive(:shell_out!).and_return(@maintenance_svc_status)
        @provider.load_current_resource
        expect(@provider.maintenance).to be_truthy
      end
    end

    describe "when enabling the service" do
      before(:each) do
        @provider.current_resource = @current_resource
      end

      it "should call svcadm enable -s chef" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        expect(@provider).not_to receive(:shell_out!).with("/usr/sbin/svcadm", "clear", @current_resource.service_name)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "enable", "-s", @current_resource.service_name).and_return(@success)
        @provider.load_current_resource

        expect(@provider.enable_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end

      it "should call svcadm enable -s chef for start_service" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        expect(@provider).not_to receive(:shell_out!).with("/usr/sbin/svcadm", "clear", @current_resource.service_name)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "enable", "-s", @current_resource.service_name).and_return(@success)
        @provider.load_current_resource
        expect(@provider.start_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end

      it "should call svcadm clear chef for start_service when state maintenance" do
        # we are in maint mode
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@maintenance_svc_status)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "clear", @current_resource.service_name).and_return(@success)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "enable", "-s", @current_resource.service_name).and_return(@success)

        # load the resource, then enable it
        @provider.load_current_resource
        expect(@provider.enable_service).to be_truthy

        # now we are enabled
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        @provider.load_current_resource

        expect(@current_resource.enabled).to be_truthy
      end
    end

    describe "when enabling the service recursively" do
      before(:each) do
        @provider.current_resource = @current_resource
      end

      it "should call svcadm enable -s -r chef" do
        @new_resource.options("-r")
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        expect(@provider).not_to receive(:shell_out!).with("/usr/sbin/svcadm", "clear", @current_resource.service_name)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "enable", "-s", "-r", @current_resource.service_name).and_return(@success)
        @provider.load_current_resource
        expect(@provider.enable_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end

      it "should call svcadm enable -s -r -t chef when passed an array of options" do
        @new_resource.options(["-r", "-t"])
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
        expect(@provider).not_to receive(:shell_out!).with("/usr/sbin/svcadm", "clear", @current_resource.service_name)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "enable", "-s", "-r", "-t", @current_resource.service_name).and_return(@success)
        @provider.load_current_resource
        expect(@provider.enable_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end

    end

    describe "when disabling the service" do
      before(:each) do
        @provider.current_resource = @current_resource
      end

      it "should call svcadm disable -s chef" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@disabled_svc_status)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "disable", "-s", "chef").and_return(@success)
        @provider.load_current_resource
        expect(@provider.disable_service).to be_truthy
        expect(@current_resource.enabled).to be_falsey
      end

      it "should call svcadm disable -s chef for stop_service" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@disabled_svc_status)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "disable", "-s", "chef").and_return(@success)
        @provider.load_current_resource
        expect(@provider.disable_service).to be_truthy
        expect(@current_resource.enabled).to be_falsey
      end

      it "should call svcadm disable chef with options" do
        @new_resource.options("-t")
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@disabled_svc_status)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "disable", "-s", "-t", "chef").and_return(@success)
        @provider.load_current_resource
        expect(@provider.disable_service).to be_truthy
        expect(@current_resource.enabled).to be_falsey
      end

    end

    describe "when reloading the service" do
      before(:each) do
        @provider.current_resource = @current_resource
        allow(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@enabled_svc_status)
      end

      it "should call svcadm refresh chef" do
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm", "refresh", "chef")
        @provider.reload_service
      end

    end

    describe "when the service doesn't exist" do
      before(:each) do
        @provider.current_resource = @current_resource
        expect(@provider).to receive(:shell_out!).with("/bin/svcs", "-l", "chef", { :returns => [0, 1] }).and_return(@no_svc_status)
      end

      it "should be marked not running" do
        @provider.service_status
        expect(@current_resource.running).to be_falsey
      end

      it "should be marked not enabled" do
        @provider.service_status
        expect(@current_resource.enabled).to be_falsey
      end

    end
  end
end
