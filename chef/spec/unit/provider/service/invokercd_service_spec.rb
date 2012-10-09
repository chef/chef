#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Provider::Service::Invokercd, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = {:ps => "ps -ef"}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")

    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Invokercd.new(@new_resource, @run_context)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @stdout = StringIO.new(<<-PS)
aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb
aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash
aj        8119  6041  0 21:34 pts/3    00:00:03 vi init_service_spec.rb
PS
    @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
    @provider.stub!(:shell_out!).and_return(@status)
  end
  
  it "should create a current resource with the name of the new resource" do
    @provider.load_current_resource
    @provider.current_resource.should equal(@current_resource)
  end

  it "should set the current resources service name to the new resources service name" do
    @provider.load_current_resource
    @current_resource.service_name.should == 'chef'
  end

  describe "when the service supports status" do
    before do
      @new_resource.supports({:status => true})
    end

    it "should run '/usr/sbin/invoke-rc.d service_name status'" do
      @provider.should_receive(:shell_out).with("/usr/sbin/invoke-rc.d #{@current_resource.service_name} status").and_return(@status)
      @provider.load_current_resource
    end
  
    it "should set running to true if the the status command returns 0" do
      @provider.stub!(:shell_out).with("/usr/sbin/invoke-rc.d #{@current_resource.service_name} status").and_return(@status)
      @provider.load_current_resource
      @current_resource.running.should be_true
    end

    it "should set running to false if the status command returns anything except 0" do
      @status.stub!(:exitstatus).and_return(1)
      @provider.stub!(:shell_out).with("/usr/sbin/invoke-rc.d #{@current_resource.service_name} status").and_return(@status)
      @provider.load_current_resource
      @current_resource.running.should be_false
    end

    it "should set running to false if the status command raises" do
      @provider.stub!(:shell_out).with("/usr/sbin/invoke-rc.d #{@current_resource.service_name} status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @provider.load_current_resource
      @current_resource.running.should be_false
    end
  end

  describe "when a status command has been specified" do
    before do
      @new_resource.stub!(:status_command).and_return("/usr/sbin/invoke-rc.d chefhasmonkeypants status")
    end

    it "should run the services status command if one has been specified" do
      @provider.should_receive(:shell_out).with("/usr/sbin/invoke-rc.d chefhasmonkeypants status").and_return(@status)
      @provider.load_current_resource
    end
    
  end
  
  describe "when the node has not specified a ps command" do
    it "should raise error if the node has a nil ps attribute and no other means to get status" do
      @node.automatic_attrs[:command] = {:ps => nil}
      @provider.action = :start
      @provider.define_resource_requirements
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
    end

    it "should raise error if the node has an empty ps attribute and no other means to get status" do
      @node.automatic_attrs[:command] = {:ps => ""}
      @provider.action = :start
      @provider.define_resource_requirements
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
    end
    
  end


  describe "when we have a 'ps' attribute" do
    it "should shell_out! the node's ps command" do
      @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
      @provider.should_receive(:shell_out!).with(@node[:command][:ps]).and_return(@status)
      @provider.load_current_resource
    end

    it "should set running to true if the regex matches the output" do
      @stdout = StringIO.new(<<-RUNNING_PS)
aj        7842  5057  0 21:26 pts/2    00:00:06 chef
aj        7842  5057  0 21:26 pts/2    00:00:06 poos
RUNNING_PS
      @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
      @provider.should_receive(:shell_out!).and_return(@status)
      @provider.load_current_resource 
      @current_resource.running.should be_true
    end

    it "should set running to false if the regex doesn't match" do
      @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
      @provider.should_receive(:shell_out!).and_return(@status)
      @provider.load_current_resource
      @current_resource.running.should be_false
    end

    it "should raise an exception if ps fails" do
      @provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @provider.action = :start
      @provider.load_current_resource
      @provider.define_resource_requirements
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
    end
  end

  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end

  describe "when starting the service" do
    it "should call the start command if one is specified" do
      @new_resource.start_command("/usr/sbin/invoke-rc.d chef startyousillysally")
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d chef startyousillysally")
      @provider.start_service()
    end

    it "should call '/usr/sbin/invoke-rc.d service_name start' if no start command is specified" do
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d #{@new_resource.service_name} start")
      @provider.start_service()
    end 
  end

  describe Chef::Provider::Service::Invokercd, "stop_service" do
    it "should call the stop command if one is specified" do
      @new_resource.stop_command("/usr/sbin/invoke-rc.d chef itoldyoutostop")
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d chef itoldyoutostop")
      @provider.stop_service()
    end

    it "should call '/usr/sbin/invoke-rc.d service_name stop' if no stop command is specified" do
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d #{@new_resource.service_name} stop")
      @provider.stop_service()
    end
  end

  describe "when restarting a service" do
    it "should call 'restart' on the service_name if the resource supports it" do
      @new_resource.supports({:restart => true})
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d #{@new_resource.service_name} restart")
      @provider.restart_service()
    end

    it "should call the restart_command if one has been specified" do
      @new_resource.restart_command("/usr/sbin/invoke-rc.d chef restartinafire")
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d #{@new_resource.service_name} restartinafire")
      @provider.restart_service()
    end

    it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
      @provider.should_receive(:stop_service)
      @provider.should_receive(:sleep).with(1)
      @provider.should_receive(:start_service)
      @provider.restart_service()
    end
  end

  describe "when reloading a service" do
    it "should call 'reload' on the service if it supports it" do
      @new_resource.supports({:reload => true})
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d chef reload")
      @provider.reload_service()
    end

    it "should should run the user specified reload command if one is specified and the service doesn't support reload" do
      @new_resource.reload_command("/usr/sbin/invoke-rc.d chef lollerpants")
      @provider.should_receive(:shell_out!).with("/usr/sbin/invoke-rc.d chef lollerpants")
      @provider.reload_service()
    end
  end
end
