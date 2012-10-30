#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Copyright:: Copyright (c) 2009, Mathieu Sauve Frankel
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

describe Chef::Provider::Service::Simple, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = {:ps => "ps -ef"}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")
    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Simple.new(@new_resource, @run_context)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @stdout = StringIO.new(<<-NOMOCKINGSTRINGSPLZ)
aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb
aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash
aj        8119  6041  0 21:34 pts/3    00:00:03 vi simple_service_spec.rb
NOMOCKINGSTRINGSPLZ
    @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
    @provider.stub!(:shell_out!).and_return(@status)
  end
  
  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    @current_resource.should_receive(:service_name).with(@new_resource.service_name)
    @provider.load_current_resource
  end

  it "should raise error if the node has a nil ps attribute and no other means to get status" do
    @node.automatic_attrs[:command] = {:ps => nil}
    @provider.define_resource_requirements
    lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
  end

  it "should raise error if the node has an empty ps attribute and no other means to get status" do
    @node.automatic_attrs[:command] = {:ps => ""}
    @provider.define_resource_requirements
    lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
  end

  describe "when we have a 'ps' attribute" do
    it "should shell_out! the node's ps command" do
      @provider.should_receive(:shell_out!).with(@node[:command][:ps]).and_return(@status)
      @provider.load_current_resource
    end

    it "should read stdout of the ps command" do
      @provider.stub!(:shell_out!).and_return(@status)
      @stdout.should_receive(:each_line).and_return(true)
      @provider.load_current_resource
    end

    it "should set running to true if the regex matches the output" do
      @stdout = StringIO.new(<<-NOMOCKINGSTRINGSPLZ)
aj        7842  5057  0 21:26 pts/2    00:00:06 chef
aj        7842  5057  0 21:26 pts/2    00:00:06 poos
NOMOCKINGSTRINGSPLZ
      @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
      @provider.stub!(:shell_out!).and_return(@status)
      @provider.load_current_resource 
      @current_resource.running.should be_true
    end

    it "should set running to false if the regex doesn't match" do
      @provider.stub!(:shell_out!).and_return(@status)
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
      @new_resource.stub!(:start_command).and_return("#{@new_resource.start_command}")
      @provider.should_receive(:shell_out!).with("#{@new_resource.start_command}")
      @provider.start_service()
    end

    it "should raise an exception if no start command is specified" do
      @provider.define_resource_requirements
      @provider.action = :start
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
    end 
  end

  describe "when stopping a service" do
    it "should call the stop command if one is specified" do
      @new_resource.stop_command("/etc/init.d/themadness stop")
      @provider.should_receive(:shell_out!).with("/etc/init.d/themadness stop")
      @provider.stop_service()
    end

    it "should raise an exception if no stop command is specified" do
      @provider.define_resource_requirements
      @provider.action = :stop
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
    end
  end

  describe Chef::Provider::Service::Simple, "restart_service" do
    it "should call the restart command if one has been specified" do
      @new_resource.restart_command("/etc/init.d/foo restart")
      @provider.should_receive(:shell_out!).with("/etc/init.d/foo restart")
      @provider.restart_service()
    end

    it "should raise an exception if the resource doesn't support restart, no restart command is provided, and no stop command is provided" do
      @provider.define_resource_requirements
      @provider.action = :restart
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service) 
    end

    it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
      @provider.should_receive(:stop_service)
      @provider.should_receive(:sleep).with(1)
      @provider.should_receive(:start_service)
      @provider.restart_service()
    end
  end

  describe Chef::Provider::Service::Simple, "reload_service" do
    it "should raise an exception if reload is requested but no command is specified" do
      @provider.define_resource_requirements
      @provider.action = :reload
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should should run the user specified reload command if one is specified" do
      @new_resource.reload_command("kill -9 1")
      @provider.should_receive(:shell_out!).with("kill -9 1")
      @provider.reload_service()
    end
  end
end
