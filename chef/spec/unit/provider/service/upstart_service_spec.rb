#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2010 Bryan McLellan
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

describe Chef::Provider::Service::Upstart, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end

  it "should return a Chef::Provider::Service object" do
    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    @provider.should be_a_kind_of(Chef::Provider::Service::Upstart)
  end

  it "should return /etc/event.d as the upstart job directory when running on Ubuntu 9.04" do
    Chef::Platform.stub!(:find_platform_and_version).and_return([ "ubuntu", "9.04" ])
    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    @provider.instance_variable_get(:@upstart_job_dir).should == "/etc/event.d"
    @provider.instance_variable_get(:@upstart_conf_suffix).should == ""
  end

  it "should return /etc/init as the upstart job directory when running on Ubuntu 9.10" do
    Chef::Platform.stub!(:find_platform_and_version).and_return([ "ubuntu", "9.10" ])
    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    @provider.instance_variable_get(:@upstart_job_dir).should == "/etc/init"
    @provider.instance_variable_get(:@upstart_conf_suffix).should == ".conf"
  end

  it "should return /etc/init as the upstart job directory by default" do
    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    @provider.instance_variable_get(:@upstart_job_dir).should == "/etc/init"
    @provider.instance_variable_get(:@upstart_conf_suffix).should == ".conf"
  end
end

describe Chef::Provider::Service::Upstart, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @node.stub!(:[]).with(:command).and_return({:ps => "ps -ax"})

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "rsyslog",
      :service_name => "rsyslog",
      :running => false,
      :enabled => false
    )
    @new_resource.stub!(:status_command).and_return(false)

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "rsyslog",
      :service_name => "rsyslog",
      :running => false,
      :enabled => false
    )

    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)

    ::File.stub!(:exists?).and_return(true)
    ::File.stub!(:open).and_return(true)
  end

  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    @current_resource.should_receive(:service_name).with(@new_resource.service_name)
    @provider.load_current_resource
  end

  it "should run '/sbin/status rsyslog'" do
    @provider.should_receive(:popen4).with("/sbin/status rsyslog").and_return(@status)
    @provider.load_current_resource
  end

  it "should set running to true if the the status command returns 0" do
    @stdout.stub!(:each).and_yield("rsyslog start/running")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:running).with(true)
    @provider.load_current_resource
  end

  it "should set running to false if the status command returns anything except 0" do
    @stdout.stub!(:each).and_yield("rsyslog stop/waiting")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:running).with(false)
    @provider.load_current_resource
  end

  it "should set running to false if it catches a Chef::Exceptions::Exec" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_raise(Chef::Exceptions::Exec)
    @current_resource.should_receive(:running).with(false)
    @provider.load_current_resource
  end

  it "should set enabled to true when it finds 'starts on'" do
    @lines = mock("start on filesystem", :gets => "start on filesystem")
    ::File.stub!(:open).and_yield(@lines)
    @current_resource.should_receive(:running).with(false)
    @provider.load_current_resource
  end
  
  it "should set enabled to false when it finds '#starts on'" do
    @lines = mock("start on filesystem", :gets => "#start on filesystem")
    ::File.stub!(:open).and_yield(@lines)
    @current_resource.should_receive(:running).with(false)
    @provider.load_current_resource
  end
  
  it "should assume disable when no job configuration file is found" do
    ::File.stub!(:exists?).and_return(false)
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

    it "should set running to false if it catches a Chef::Exceptions::Exec when using a status command" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_raise(Chef::Exceptions::Exec)
      @current_resource.should_receive(:running).with(false)
      @provider.load_current_resource
    end
  end
    
  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end

end

describe Chef::Provider::Service::Upstart, "enable and disable service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "rsyslog",
      :service_name => "rsyslog",
      :running => false,
      :enabled => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "rsyslog",
      :service_name => "rsyslog",
      :running => false,
      :enabled => false
    )

    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
    Chef::Util::FileEdit.stub!(:new)
  end

  it "should enable the service if it is not enabled" do
    @current_resource.stub!(:enabled).and_return(false)
    @file.should_receive(:search_file_replace)
    @file.should_receive(:write_file)
    @provider.enable_service()
  end
  
  it "should disable the service if it is enabled" do
    @current_resource.stub!(:enabled).and_return(true)
    @file.should_receive(:search_file_replace)
    @file.should_receive(:write_file)
    @provider.disable_service()
  end
  
end

describe Chef::Provider::Service::Upstart, "start and stop service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "rsyslog",
      :service_name => "rsyslog",
      :running => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "rsyslog",
      :service_name => "rsyslog",
      :running => false,
      :enabled => false
    )

    @new_resource.stub!(:start_command).and_return(false)
    @new_resource.stub!(:restart_command).and_return(false)
    @new_resource.stub!(:reload_command).and_return(false)
    @new_resource.stub!(:stop_command).and_return(false)

    @provider = Chef::Provider::Service::Upstart.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
  end

  it "should call the start command if one is specified" do
    @new_resource.stub!(:start_command).and_return("/sbin/rsyslog startyousillysally")
    @provider.should_receive(:run_command).with({:command => "/sbin/rsyslog startyousillysally"}).and_return(0)
    @provider.start_service()
  end

  it "should call '/sbin/start service_name' if no start command is specified" do
    @provider.should_receive(:run_command_with_systems_locale).with({:command => "/sbin/start #{@new_resource.service_name}"}).and_return(0)
    @provider.start_service()
  end

  it "should not call '/sbin/start service_name' if it is already running" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_not_receive(:run_command_with_systems_locale).with({:command => "/sbin/start #{@new_resource.service_name}"}).and_return(0)
    @provider.start_service()
  end

  it "should call the restart command if one is specified" do
    @current_resource.stub!(:running).and_return(true)
    @new_resource.stub!(:restart_command).and_return("/sbin/rsyslog restartyousillysally")
    @provider.should_receive(:run_command).with({:command => "/sbin/rsyslog restartyousillysally"}).and_return(0)
    @provider.restart_service()
  end

  it "should call '/sbin/restart service_name' if no restart command is specified" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_receive(:run_command_with_systems_locale).with({:command => "/sbin/restart #{@new_resource.service_name}"}).and_return(0)
    @provider.restart_service()
  end

  it "should call the reload command if one is specified" do
    @current_resource.stub!(:running).and_return(true)
    @new_resource.stub!(:reload_command).and_return("/sbin/rsyslog reloadyousillysally")
    @provider.should_receive(:run_command).with({:command => "/sbin/rsyslog reloadyousillysally"}).and_return(0)
    @provider.reload_service()
  end

  it "should call '/sbin/reload service_name' if no reload command is specified" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_receive(:run_command_with_systems_locale).with({:command => "/sbin/reload #{@new_resource.service_name}"}).and_return(0)
    @provider.reload_service()
  end

  it "should call the stop command if one is specified" do
    @current_resource.stub!(:running).and_return(true)
    @new_resource.stub!(:stop_command).and_return("/sbin/rsyslog stopyousillysally")
    @provider.should_receive(:run_command).with({:command => "/sbin/rsyslog stopyousillysally"}).and_return(0)
    @provider.stop_service()
  end

  it "should call '/sbin/stop service_name' if no stop command is specified" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_receive(:run_command_with_systems_locale).with({:command => "/sbin/stop #{@new_resource.service_name}"}).and_return(0)
    @provider.stop_service()
  end

  it "should not call '/sbin/stop service_name' if it is already stopped" do
    @current_resource.stub!(:running).and_return(false)
    @provider.should_not_receive(:run_command_with_systems_locale).with({:command => "/sbin/stop #{@new_resource.service_name}"}).and_return(0)
    @provider.stop_service()
  end
end

