#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))
require 'ostruct'


# most of this code has been ripped from init_service_spec.rb
# and is only slightly modified to match "arch" needs.

describe Chef::Provider::Service::Arch, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @node[:command] = {:ps => "ps -ef"}

    @run_context = Chef::RunContext.new(@node, {})

    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.pattern("chef")
    @new_resource.supports({:status => false})


    @provider = Chef::Provider::Service::Arch.new(@new_resource, @run_context)

    ::File.stub!(:exists?).with("/etc/rc.conf").and_return(true)
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network apache sshd)")
  end

  describe "when first created" do
    it "should set the current resources service name to the new resources service name" do
      @provider.stub(:popen4).and_return(OpenStruct.new(:exitstatus => 0))
      @provider.load_current_resource
      @provider.current_resource.service_name.should == 'chef'
    end
  end


  describe "when the service supports status" do
    before do
      @provider.stub!(:popen4).and_return(OpenStruct.new(:exitstatus => 0))
      @new_resource.supports({:status => true})
    end

    it "should run '/etc/rc.d/service_name status'" do
      @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chef status"})
      @provider.load_current_resource
    end

    it "should set running to true if the the status command returns 0" do
      @provider.stub!(:run_command).with({:command => "/etc/rc.d/chef status"}).and_return(0)
      @provider.load_current_resource
      @provider.current_resource.running.should be_true
    end

    it "should set running to false if the status command returns anything except 0" do
      @provider.stub!(:run_command).with({:command => "/etc/rc.d/chef status"}).and_raise(Chef::Exceptions::Exec)
      @provider.load_current_resource
      @provider.current_resource.running.should be_false
    end
  end


  describe "when a status command has been specified" do
    before do
      @new_resource.status_command("/etc/rc.d/chefhasmonkeypants status")
    end

    it "should run the services status command if one has been specified" do
      @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chefhasmonkeypants status"})
      @provider.load_current_resource
    end

  end

  it "should set running to false if the node has a nil ps attribute" do
    @node[:command] = {:ps => nil}
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should set running to false if the node has an empty ps attribute" do
    @node[:command] = {:ps => ""}
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should fail if file /etc/rc.conf does not exist" do
    ::File.stub!(:exists?).with("/etc/rc.conf").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should fail if file /etc/rc.conf does not contain DAEMONS array" do
    ::File.stub!(:read).with("/etc/rc.conf").and_return("")
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  describe "when discovering service status with ps" do
    before do
      @status = mock("Status", :exitstatus => 0)
      @provider.stub!(:popen4).and_return(@status)
      @stdin = nil
      @stdout = StringIO.new(<<-DEFAULT_PS)
aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb
aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash
aj        8119  6041  0 21:34 pts/3    00:00:03 vi init_service_spec.rb
DEFAULT_PS
      @stderr = nil
      @pid = nil

      @node[:command] = {:ps => "ps -ef"}
    end

    it "determines the service is running when it appears in ps" do
      @stdout = StringIO.new(<<-RUNNING_PS)
aj        7842  5057  0 21:26 pts/2    00:00:06 chef
aj        7842  5057  0 21:26 pts/2    00:00:06 poos
RUNNING_PS
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.running.should be_true
    end

    it "determines the service is not running when it does not appear in ps" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.running.should be_false
    end

    it "should raise an exception if ps fails" do
      @status.stub!(:exitstatus).and_return(-1)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end
  end

  it "should return existing entries in DAEMONS array" do
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network !apache ssh)")
    @provider.daemons.should == ['network', '!apache', 'ssh']
  end

  context "when the current service status is known" do
    before do
      @current_resource = Chef::Resource::Service.new("chef")
      @provider.current_resource = @current_resource
    end

    describe Chef::Provider::Service::Arch, "enable_service" do
      # before(:each) do
      #   @new_resource = mock("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub!(:start_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      # end

      it "should add chef to DAEMONS array" do
        ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network)")
        @provider.should_receive(:update_daemons).with(['network', 'chef'])
        @provider.enable_service()
      end
    end

    describe Chef::Provider::Service::Arch, "disable_service" do
      # before(:each) do
      #   @new_resource = mock("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub!(:start_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      # end

      it "should remove chef from DAEMONS array" do
        ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network chef)")
        @provider.should_receive(:update_daemons).with(['network', '!chef'])
        @provider.disable_service()
      end
    end


    describe Chef::Provider::Service::Arch, "start_service" do
      # before(:each) do
      #   @new_resource = mock("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub!(:start_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      # end

      it "should call the start command if one is specified" do
        @new_resource.stub!(:start_command).and_return("/etc/rc.d/chef startyousillysally")
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chef startyousillysally"}).and_return(0)
        @provider.start_service()
      end

      it "should call '/etc/rc.d/service_name start' if no start command is specified" do
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} start"}).and_return(0)
        @provider.start_service()
      end
    end

    describe Chef::Provider::Service::Arch, "stop_service" do
      # before(:each) do
      #   @new_resource = mock("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub!(:stop_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      # end

      it "should call the stop command if one is specified" do
        @new_resource.stub!(:stop_command).and_return("/etc/rc.d/chef itoldyoutostop")
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chef itoldyoutostop"}).and_return(0)
        @provider.stop_service()
      end

      it "should call '/etc/rc.d/service_name stop' if no stop command is specified" do
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} stop"}).and_return(0)
        @provider.stop_service()
      end
    end

    describe Chef::Provider::Service::Arch, "restart_service" do
      # before(:each) do
      #   @new_resource = mock("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub!(:restart_command).and_return(false)
      #   @new_resource.stub!(:supports).and_return({:restart => false})
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      # end

      it "should call 'restart' on the service_name if the resource supports it" do
        @new_resource.stub!(:supports).and_return({:restart => true})
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} restart"}).and_return(0)
        @provider.restart_service()
      end

      it "should call the restart_command if one has been specified" do
        @new_resource.stub!(:restart_command).and_return("/etc/rc.d/chef restartinafire")
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} restartinafire"}).and_return(0)
        @provider.restart_service()
      end

      it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
        @provider.should_receive(:stop_service)
        @provider.should_receive(:sleep).with(1)
        @provider.should_receive(:start_service)
        @provider.restart_service()
      end
    end

    describe Chef::Provider::Service::Arch, "reload_service" do
      # before(:each) do
      #   @new_resource = mock("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub!(:reload_command).and_return(false)
      #   @new_resource.stub!(:supports).and_return({:reload => false})
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub!(:new).and_return(@current_resource)
      # end

      it "should call 'reload' on the service if it supports it" do
        @new_resource.stub!(:supports).and_return({:reload => true})
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} reload"}).and_return(0)
        @provider.reload_service()
      end

      it "should should run the user specified reload command if one is specified and the service doesn't support reload" do
        @new_resource.stub!(:reload_command).and_return("/etc/rc.d/chef lollerpants")
        @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} lollerpants"}).and_return(0)
        @provider.reload_service()
      end
    end
  end
end
