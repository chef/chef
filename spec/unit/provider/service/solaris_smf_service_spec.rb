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
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @stdin = StringIO.new
    @stdout = StringIO.new
    @stderr = StringIO.new
    @pid = 2342
    @stdout_string = "state disabled"
    @stdout.stub!(:gets).and_return(@stdout_string)
    @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
    @provider.stub!(:shell_out!).and_return(@status)
  end

  it "should raise an error if /bin/svcs does not exist" do
    File.should_receive(:exists?).with("/bin/svcs").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  describe "on a host with /bin/svcs" do

    before do
      File.stub!(:exists?).with('/bin/svcs').and_return(true)
    end

    describe "when discovering the current service state" do
      it "should create a current resource with the name of the new resource" do
        @provider.stub!(:popen4).with("/bin/svcs -l chef").and_return(@status)
        Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
        @provider.load_current_resource
      end


      it "should return the current resource" do
        @provider.stub!(:popen4).with("/bin/svcs -l chef").and_return(@status)
        @provider.load_current_resource.should eql(@current_resource)
      end

      it "should popen4 '/bin/svcs -l service_name'" do
        @provider.should_receive(:popen4).with("/bin/svcs -l chef").and_return(@status)
        @provider.load_current_resource
      end

      it "should mark service as not running" do
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @current_resource.should_receive(:running).with(false)
        @provider.load_current_resource
      end

      it "should mark service as running" do
        @stdout.stub!(:each).and_yield("state online")
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @current_resource.should_receive(:running).with(true)
        @provider.load_current_resource
      end
    end

    describe "when enabling the service" do
      before(:each) do
        @provider.current_resource = @current_resource
        @current_resource.enabled(true)
      end

      it "should call svcadm enable -s chef" do
        @new_resource.stub!(:enable_command).and_return("#{@new_resource.enable_command}")
        @provider.should_receive(:shell_out!).with("/usr/sbin/svcadm enable -s #{@current_resource.service_name}").and_return(@status)
				@provider.enable_service.should be_true
        @current_resource.enabled.should be_true
      end

      it "should call svcadm enable -s chef for start_service" do
        @new_resource.stub!(:start_command).and_return("#{@new_resource.start_command}")
        @provider.should_receive(:shell_out!).with("/usr/sbin/svcadm enable -s #{@current_resource.service_name}").and_return(@status)
        @provider.start_service.should be_true
        @current_resource.enabled.should be_true
      end

    end


    describe "when disabling the service" do
      before(:each) do
        @provider.current_resource = @current_resource
        @current_resource.enabled(false)
      end

      it "should call svcadm disable -s chef" do
        @provider.should_receive(:shell_out!).with("/usr/sbin/svcadm disable -s chef").and_return(@status)
        @provider.disable_service.should be_true
        @current_resource.enabled.should be_false
      end

      it "should call svcadm disable -s chef for stop_service" do
        @provider.should_receive(:shell_out!).with("/usr/sbin/svcadm disable -s chef")
        @provider.stop_service.should be_true
        @current_resource.enabled.should be_false
      end

    end

    describe "when reloading the service" do
      before(:each) do
        @status = mock("Process::Status", :exitstatus => 0)
        @provider.current_resource = @current_resource
      end

      it "should call svcadm refresh chef" do
        @provider.should_receive(:shell_out!).with("/usr/sbin/svcadm refresh chef").and_return(@status)
        @provider.reload_service
      end

    end
  end
end
