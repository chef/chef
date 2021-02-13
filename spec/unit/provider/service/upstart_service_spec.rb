#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright 2010-2016, Bryan McLellan
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

describe Chef::Provider::Service::Upstart do
  let(:shell_out_success) do
    double("shell_out", exitstatus: 0, error?: false)
  end

  before(:each) do
    @node = Chef::Node.new
    @node.name("upstarter")
    @node.automatic_attrs[:platform] = "ubuntu"

    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("rsyslog")
    @provider = Chef::Provider::Service::Upstart.new(@new_resource, @run_context)
  end

  describe "load_current_resource" do
    before(:each) do
      @node.automatic_attrs[:command] = { ps: "ps -ax" }

      @current_resource = Chef::Resource::Service.new("rsyslog")
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)

      @status = double("Status", exitstatus: 0, stdout: "", stderr: "")
      allow(@provider).to receive(:shell_out).and_return(@status)

      allow(::File).to receive(:exist?).and_return(true)
      allow(::File).to receive(:open).and_return(true)
    end

    it "should create a current resource with the name of the new resource" do
      expect(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      expect(@current_resource).to receive(:service_name).with(@new_resource.service_name)
      @provider.load_current_resource
    end

    it "should not change the service name when parameters are specified" do
      @new_resource.parameters({ "OSD_ID" => "2" })
      @provider = Chef::Provider::Service::Upstart.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      expect(@new_resource.service_name).to eq(@current_resource.service_name)
    end

    it "should run '/sbin/status rsyslog'" do
      expect(@provider).to receive(:shell_out).with("/sbin/status rsyslog").and_return(@status)
      @provider.load_current_resource
    end

    describe "when the status command uses the new format" do
      it "should set running to true if the goal state is 'start'" do
        expect(@status).to receive(:stdout).and_return("rsyslog start/running")
        @provider.load_current_resource
        expect(@current_resource.running).to be_truthy
      end

      it "should set running to true if the goal state is 'start' but current state is not 'running'" do
        expect(@status).to receive(:stdout).and_return("rsyslog start/starting")
        @provider.load_current_resource
        expect(@current_resource.running).to be_truthy
      end

      it "should set running to false if the goal state is 'stop'" do
        expect(@status).to receive(:stdout).and_return("rsyslog stop/waiting")
        @provider.load_current_resource
        expect(@current_resource.running).to be_falsey
      end
    end

    describe "when the status command uses the new format with an instance" do
      it "should set running to true if the goal state is 'start'" do
        expect(@status).to receive(:stdout).and_return("rsyslog (test) start/running, process 100")
        @provider.load_current_resource
        expect(@current_resource.running).to be_truthy
      end

      it "should set running to true if the goal state is 'start' but current state is not 'running'" do
        expect(@status).to receive(:stdout).and_return("rsyslog (test) start/starting, process 100")
        @provider.load_current_resource
        expect(@current_resource.running).to be_truthy
      end

      it "should set running to false if the goal state is 'stop'" do
        expect(@status).to receive(:stdout).and_return("rsyslog (test) stop/waiting, process 100")
        @provider.load_current_resource
        expect(@current_resource.running).to be_falsey
      end
    end

    describe "when the status command uses the old format" do
      it "should set running to true if the goal state is 'start'" do
        expect(@status).to receive(:stdout).and_return("rsyslog (start) running, process 32225")
        @provider.load_current_resource
        expect(@current_resource.running).to be_truthy
      end

      it "should set running to true if the goal state is 'start' but current state is not 'running'" do
        expect(@status).to receive(:stdout).and_return("rsyslog (start) starting, process 32225")
        @provider.load_current_resource
        expect(@current_resource.running).to be_truthy
      end

      it "should set running to false if the goal state is 'stop'" do
        expect(@status).to receive(:stdout).and_return("rsyslog (stop) waiting")
        @provider.load_current_resource
        expect(@current_resource.running).to be_falsey
      end
    end

    it "should set running to false if it catches a Chef::Exceptions::Exec" do
      allow(@provider).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_raise(Chef::Exceptions::Exec)
      expect(@current_resource).to receive(:running).with(false)
      @provider.load_current_resource
    end

    it "should set enabled to true when it finds 'starts on'" do
      @lines = double("start on filesystem", gets: "start on filesystem")
      allow(::File).to receive(:open).and_yield(@lines)
      expect(@current_resource).to receive(:running).with(false)
      @provider.load_current_resource
    end

    it "should set enabled to false when it finds '#starts on'" do
      @lines = double("start on filesystem", gets: "#start on filesystem")
      allow(::File).to receive(:open).and_yield(@lines)
      expect(@current_resource).to receive(:running).with(false)
      @provider.load_current_resource
    end

    it "should assume disable when no job configuration file is found" do
      allow(::File).to receive(:exist?).and_return(false)
      expect(@current_resource).to receive(:running).with(false)
      @provider.load_current_resource
    end

    it "should track state when the upstart configuration file fails to load" do
      expect(File).to receive(:exist?).and_return false
      @provider.load_current_resource
      expect(@provider.instance_variable_get("@config_file_found")).to eq(false)
    end

    describe "when a status command has been specified" do
      before do
        @new_resource.status_command("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        allow(@provider).to receive(:shell_out!).with("/bin/chefhasmonkeypants status").and_return(shell_out_success)
        expect(@current_resource).to receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should track state when the user-provided status command fails" do
        allow(@provider).to receive(:shell_out!).and_raise(Errno::ENOENT)
        @provider.load_current_resource
        expect(@provider.instance_variable_get("@command_success")).to eq(false)
      end

      it "should set running to false if it catches a Chef::Exceptions::Exec when using a status command" do
        allow(@provider).to receive(:shell_out!).and_raise(Errno::ENOENT)
        expect(@current_resource).to receive(:running).with(false)
        @provider.load_current_resource
      end
    end

    it "should track state when we fail to obtain service status via upstart_goal_state" do
      expect(@provider).to receive(:upstart_goal_state).and_raise Chef::Exceptions::Exec
      @provider.load_current_resource
      expect(@provider.instance_variable_get("@command_success")).to eq(false)
    end

    it "should return the current resource" do
      expect(@provider.load_current_resource).to eql(@current_resource)
    end

  end

  describe "enable and disable service" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new("rsyslog")
      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
      allow(Chef::Util::FileEdit).to receive(:new)
    end

    it "should enable the service if it is not enabled" do
      @file = Object.new
      allow(Chef::Util::FileEdit).to receive(:new).and_return(@file)
      allow(@current_resource).to receive(:enabled).and_return(false)
      expect(@file).to receive(:search_file_replace)
      expect(@file).to receive(:write_file)
      @provider.enable_service
    end

    it "should disable the service if it is enabled" do
      @file = Object.new
      allow(Chef::Util::FileEdit).to receive(:new).and_return(@file)
      allow(@current_resource).to receive(:enabled).and_return(true)
      expect(@file).to receive(:search_file_replace)
      expect(@file).to receive(:write_file)
      @provider.disable_service
    end

  end

  describe "start and stop service" do
    before(:each) do
      @current_resource = Chef::Resource::Service.new("rsyslog")

      allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      @provider.current_resource = @current_resource
    end

    it "should call the start command if one is specified" do
      @provider.upstart_service_running = false
      @new_resource.start_command("/sbin/rsyslog startyousillysally")
      expect(@provider).to receive(:shell_out!).with("/sbin/rsyslog startyousillysally", default_env: false)
      @provider.start_service
    end

    it "should call '/sbin/start service_name' if no start command is specified" do
      @provider.upstart_service_running = false
      expect(@provider).to receive(:shell_out!).with("/sbin/start #{@new_resource.service_name}", default_env: false).and_return(shell_out_success)
      @provider.start_service
    end

    it "should not call '/sbin/start service_name' if it is already running" do
      @provider.upstart_service_running = true
      expect(@provider).not_to receive(:shell_out!)
      @provider.start_service
    end

    it "should pass parameters to the start command if they are provided" do
      @new_resource = Chef::Resource::Service.new("rsyslog")
      @new_resource.parameters({ "OSD_ID" => "2" })
      @provider = Chef::Provider::Service::Upstart.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      expect(@provider).to receive(:shell_out!).with("/sbin/start rsyslog OSD_ID=2", default_env: false).and_return(shell_out_success)
      @provider.start_service
    end

    it "should call the restart command if one is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      @new_resource.restart_command("/sbin/rsyslog restartyousillysally")
      expect(@provider).to receive(:shell_out!).with("/sbin/rsyslog restartyousillysally", default_env: false)
      @provider.restart_service
    end

    it "should call start/sleep/stop if no restart command is specified" do
      @provider.upstart_service_running = true
      expect(@provider).to receive(:stop_service)
      expect(@provider).to receive(:sleep).with(1)
      expect(@provider).to receive(:start_service)
      @provider.restart_service
    end

    it "should call '/sbin/start service_name' if restart_service is called for a stopped service" do
      @provider.upstart_service_running = false
      allow(@current_resource).to receive(:running).and_return(false)
      expect(@provider).to receive(:shell_out!).with("/sbin/start #{@new_resource.service_name}", default_env: false).and_return(shell_out_success)
      @provider.restart_service
    end

    it "should call the reload command if one is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      @new_resource.reload_command("/sbin/rsyslog reloadyousillysally")
      expect(@provider).to receive(:shell_out!).with("/sbin/rsyslog reloadyousillysally", default_env: false)
      @provider.reload_service
    end

    it "should call '/sbin/reload service_name' if no reload command is specified" do
      allow(@current_resource).to receive(:running).and_return(true)
      expect(@provider).to receive(:shell_out!).with("/sbin/reload #{@new_resource.service_name}", default_env: false).and_return(shell_out_success)
      @provider.reload_service
    end

    it "should call the stop command if one is specified" do
      @provider.upstart_service_running = true
      @new_resource.stop_command("/sbin/rsyslog stopyousillysally")
      expect(@provider).to receive(:shell_out!).with("/sbin/rsyslog stopyousillysally", default_env: false)
      @provider.stop_service
    end

    it "should call '/sbin/stop service_name' if no stop command is specified" do
      @provider.upstart_service_running = true
      expect(@provider).to receive(:shell_out!).with("/sbin/stop #{@new_resource.service_name}", default_env: false).and_return(shell_out_success)
      @provider.stop_service
    end

    it "should not call '/sbin/stop service_name' if it is already stopped" do
      @provider.upstart_service_running = false
      allow(@current_resource).to receive(:running).and_return(false)
      expect(@provider).not_to receive(:shell_out!).with("/sbin/stop #{@new_resource.service_name}", default_env: false)
      @provider.stop_service
      expect(@upstart_service_running).to be_falsey
    end
  end
end
