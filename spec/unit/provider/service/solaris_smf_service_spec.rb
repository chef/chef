#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Provider::Service::Solaris do
  before(:each) do
    @node =Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new('chef')

    @current_resource = Chef::Resource::Service.new('chef')

    @provider = Chef::Provider::Service::Solaris.new(@new_resource, @run_context)
    allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)

    @stdin = StringIO.new
    @stdout = StringIO.new
    @stderr = StringIO.new
    @pid = 2342
    @stdout_string = "state disabled"
    allow(@stdout).to receive(:gets).and_return(@stdout_string)
    @status = double("Status", :exitstatus => 0, :stdout => @stdout)
    allow(@provider).to receive(:shell_out!).and_return(@status)
  end

  it "should raise an error if /bin/svcs does not exist" do
    expect(File).to receive(:exists?).with("/bin/svcs").and_return(false)
    expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Service)
  end

  describe "on a host with /bin/svcs" do

    before do
      allow(File).to receive(:exists?).with('/bin/svcs').and_return(true)
    end

    describe "when discovering the current service state" do
      it "should create a current resource with the name of the new resource" do
        allow(@provider).to receive(:shell_out!).with("/bin/svcs -l chef").and_return(@status)
        expect(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
        @provider.load_current_resource
      end

      it "should return the current resource" do
        allow(@provider).to receive(:shell_out!).with("/bin/svcs -l chef").and_return(@status)
        expect(@provider.load_current_resource).to eql(@current_resource)
      end

      it "should call '/bin/svcs -l service_name'" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs -l chef", {:returns=>[0, 1]}).and_return(@status)
        @provider.load_current_resource
      end

      it "should mark service as not running" do
        allow(@provider).to receive(:shell_out!).and_return(@status)
        expect(@current_resource).to receive(:running).with(false)
        @provider.load_current_resource
      end

      it "should mark service as running" do
        @status = double("Status", :exitstatus => 0, :stdout => 'state online')
        allow(@provider).to receive(:shell_out!).and_return(@status)
        expect(@current_resource).to receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should not mark service as maintenance" do
        allow(@provider).to receive(:shell_out!).and_return(@status)
        @provider.load_current_resource
        expect(@provider.maintenance).to be_falsey
      end

      it "should mark service as maintenance" do
        @status = double("Status", :exitstatus => 0, :stdout => 'state maintenance')
        allow(@provider).to receive(:shell_out!).and_return(@status)
        @provider.load_current_resource
        expect(@provider.maintenance).to be_truthy
      end
    end

    describe "when enabling the service" do
      before(:each) do
        @provider.current_resource = @current_resource
        @current_resource.enabled(true)
      end

      it "should call svcadm enable -s chef" do
        expect(@provider).not_to receive(:shell_out!).with("/usr/sbin/svcadm clear #{@current_resource.service_name}")
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm enable -s #{@current_resource.service_name}").and_return(@status)
        expect(@provider.enable_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end

      it "should call svcadm enable -s chef for start_service" do
        expect(@provider).not_to receive(:shell_out!).with("/usr/sbin/svcadm clear #{@current_resource.service_name}")
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm enable -s #{@current_resource.service_name}").and_return(@status)
        expect(@provider.start_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end

      it "should call svcadm clear chef for start_service when state maintenance" do
        @status = double("Status", :exitstatus => 0, :stdout => 'state maintenance')
        allow(@provider).to receive(:shell_out!).and_return(@status)
        @provider.load_current_resource
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm clear #{@current_resource.service_name}").and_return(@status)
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm enable -s #{@current_resource.service_name}").and_return(@status)
        expect(@provider.enable_service).to be_truthy
        expect(@current_resource.enabled).to be_truthy
      end
    end

    describe "when disabling the service" do
      before(:each) do
        @provider.current_resource = @current_resource
        @current_resource.enabled(false)
      end

      it "should call svcadm disable -s chef" do
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm disable -s chef").and_return(@status)
        expect(@provider.disable_service).to be_truthy
        expect(@current_resource.enabled).to be_falsey
      end

      it "should call svcadm disable -s chef for stop_service" do
        expect(@provider).to receive(:shell_out!).with("/usr/sbin/svcadm disable -s chef").and_return(@status)
        expect(@provider.stop_service).to be_truthy
        expect(@current_resource.enabled).to be_falsey
      end

    end

    describe "when reloading the service" do
      before(:each) do
        @status = double("Process::Status", :exitstatus => 0)
        @provider.current_resource = @current_resource
      end

      it "should call svcadm refresh chef" do
        expect(@provider).to receive(:shell_out_with_systems_locale!).with("/usr/sbin/svcadm refresh chef").and_return(@status)
        @provider.reload_service
      end

    end

    describe "when the service doesn't exist" do
      before(:each) do
        @stdout_string = ""
        @status = double("Status", :exitstatus => 1, :stdout => @stdout)
        @provider.current_resource = @current_resource
      end

      it "should be marked not running" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs -l chef", {:returns=>[0, 1]}).and_return(@status)
        @provider.service_status
        expect(@current_resource.running).to be_falsey
      end

      it "should be marked not enabled" do
        expect(@provider).to receive(:shell_out!).with("/bin/svcs -l chef", {:returns=>[0, 1]}).and_return(@status)
        @provider.service_status
        expect(@current_resource.enabled).to be_falsey
      end

    end
  end
end
