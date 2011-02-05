#
# Author:: Nuo Yan <nuo@opscode.com>
# Copyright:: Copyright (c) 2010, Opscode, Inc
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Service::Windows, "load_current_resource" do
  before(:each) do
    @init_command = "sc"
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    
    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.pattern("chef")

    @current_resource = Chef::Resource::Service.new("chef")
    @provider = Chef::Provider::Service::Windows.new(@new_resource, @run_context)
    @status = mock("Status", :exitstatus => 0)
    @stdout = StringIO.new("Service Service lolcats Service")
    @pid = nil
    @stdout_query = StringIO.new(<<-SC)
        
        SERVICE_NAME: chef
        TYPE               : 20  WIN32_SHARE_PROCESS
        STATE              : 4  RUNNING
                                (STOPPABLE, NOT_PAUSABLE, IGNORES_SHUTDOWN))
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
      SC
    @stdout_qc = StringIO.new(<<-SC)
        [SC] QueryServiceConfig SUCCESS
        
        SERVICE_NAME: chef
        TYPE               : 20  WIN32_SHARE_PROCESS
        START_TYPE         : 2   AUTO_START
        ERROR_CONTROL      : 1   NORMAL
        BINARY_PATH_NAME   : C:\chef\this_is_made_up.exe
        LOAD_ORDER_GROUP   : TDI
        TAG                : 0
        DISPLAY_NAME       : Chef
        DEPENDENCIES       : lolcats
        SERVICE_START_NAME : NT AUTHORITY\NetworkService
      SC
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)

    @provider.stub!(:popen4).with("#{@init_command} query #{@new_resource.service_name}").and_yield(@pid, @stdin, @stdout_query, @stderr).and_return(@status)
    @provider.stub!(:popen4).with("#{@init_command} qc #{@new_resource.service_name}").and_yield(@pid, @stdin, @stdout_qc, @stderr).and_return(@status)
  end

  it "should set the current resources service name to the new resources service name" do
    @provider.load_current_resource
    @provider.current_resource.service_name.should == 'chef'
  end

  it "should return the current resource" do
    @provider.load_current_resource.should equal(@provider.current_resource)
  end
  
  it "should raise an exception if the service does not exist and query fails" do
    @stdout_fake_service = StringIO.new(<<-SC)
      [SC] EnumQueryServicesStatus:OpenService FAILED 1060:
      
      The specified service does not exist as an installed service.
    SC
    @provider.stub!(:popen4).with("#{@init_command} query #{@new_resource.service_name}").and_yield(@pid, @stdin, @stdout_fake_service, @stderr).and_return(@status)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should raise an exception if the service does not exist and qc fails" do
    @stdout_fake_service = StringIO.new(<<-SC)
      [SC] EnumQueryServicesStatus:OpenService FAILED 1060:
      
      The specified service does not exist as an installed service.
    SC
    @provider.stub!(:popen4).with("#{@init_command} qc #{@new_resource.service_name}").and_yield(@pid, @stdin, @stdout_fake_service, @stderr).and_return(@status)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  describe Chef::Provider::Service::Windows, "start_service" do
    before(:each) do
      @new_resource.start_command "sc start chef"
    end

    it "should call the start command if one is specified" do
      @new_resource.stub!(:start_command).and_return("#{@new_resource.start_command}")
      @provider.should_receive(:popen4).with("#{@new_resource.start_command}").and_return("Starting custom service")
      @provider.start_service().should be_true
    end

    it "should use the built-in command if no start command is specified" do
      @new_resource.stub!(:start_command).and_return(nil)
      @provider.should_receive(:popen4).with("#{@init_command} start #{@new_resource.service_name}").and_return([
          "\n",
          "SERVICE_NAME: dnscache\n",
          "TYPE               : 20  WIN32_SHARE_PROCESS\n",
          "STATE              : 2  START_PENDING\n",
          "(NOT_STOPPABLE, NOT_PAUSABLE, IGNORES_SHUTDOWN))\n",
          "\n",
          "WIN32_EXIT_CODE    : 0  (0x0)\n",
          "SERVICE_EXIT_CODE  : 0  (0x0)\n",
          "CHECKPOINT         : 0x0\n",
          "WAIT_HINT          : 0x7d0\n",
          "PID                : 736\n",
          "FLAGS              :\n"
        ])
      @provider.start_service()
    end
  end

  describe Chef::Provider::Service::Windows, "stop_service" do
    before(:each) do
      @new_resource.stop_command "sc stop chef"
    end

    it "should call the stop command if one is specified" do
      @new_resource.stub!(:stop_command).and_return("#{@new_resource.stop_command}")
      @provider.should_receive(:popen4).with("#{@new_resource.stop_command}").and_return("Stopping custom service")
      @provider.stop_service().should be_true
    end

    it "should use the built-in command if no stop command is specified" do
      @new_resource.stub!(:stop_command).and_return(nil)
      @provider.should_receive(:popen4).with("#{@init_command} stop #{@new_resource.service_name}").and_return([
          "\n",
          "SERVICE_NAME: chef\n",
          "\tTYPE               : 20  WIN32_SHARE_PROCESS\n",
          "\tSTATE              : 3  STOP_PENDING\n",
          "\t                        (NOT_STOPPABLE, NOT_PAUSABLE, IGNORES_SHUTDOWN))",
          "",
          "WIN32_EXIT_CODE    : 0  (0x0)",
          "SERVICE_EXIT_CODE  : 0  (0x0)",
          "CHECKPOINT         : 0x0",
          "WAIT_HINT          : 0x0"
        ])
      @provider.stop_service().should be_true
    end
  end

  describe Chef::Provider::Service::Windows, "restart_service" do
    it "should call the restart command if one is specified" do
      @new_resource.stub!(:restart_command).and_return("#{@new_resource.restart_command}")
      @provider.should_receive(:popen4).with("#{@new_resource.restart_command}").and_return("Restarting custom service")
      @provider.restart_service().should be_true
    end

    it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
      @provider.should_receive(:popen4).with("sc stop chef").and_return(StringIO.new("foo\nbar\nbaz\n1 STOPPED\n"))
      @provider.should_receive(:popen4).with("sc start chef").and_return(StringIO.new("foo\nbar\nbaz\n2 START_PENDING\n"))
      @provider.restart_service()
    end
  end

  describe Chef::Provider::Service::Windows, "enable_service" do
    it "should enable service and set the startup type" do
      @new_resource.startup_type :automatic
      @provider.should_receive(:popen4).with("sc config chef start= auto").and_return(StringIO.new("SUCCESS"))
      @provider.enable_service().should be_true
    end
  end

  describe Chef::Provider::Service::Windows, "disable_service" do
    it "should disable service" do
      @provider.should_receive(:popen4).with("sc config chef start= disabled").and_return(StringIO.new("SUCCESS"))
      @provider.disable_service().should be_true
    end
  end
end
