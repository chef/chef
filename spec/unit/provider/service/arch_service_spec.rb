#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "ostruct"

# most of this code has been ripped from init_service_spec.rb
# and is only slightly modified to match "arch" needs.

describe Chef::Provider::Service::Arch, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = { ps: "ps -ef" }

    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.pattern("chef")
    @new_resource.supports({ status: false })

    @provider = Chef::Provider::Service::Arch.new(@new_resource, @run_context)

    allow(::File).to receive(:exist?).with("/etc/rc.d/chef").and_return(false)
    allow(::File).to receive(:exist?).with("/etc/rc.conf").and_return(true)
    allow(::File).to receive(:read).with("/etc/rc.conf").and_return("DAEMONS=(network apache sshd)")
  end

  describe "when first created" do
    it "should set the current resources service name to the new resources service name" do
      allow(@provider).to receive(:determine_current_status!)
      allow(@provider).to receive(:shell_out).and_return(OpenStruct.new(exitstatus: 0, stdout: ""))
      @provider.load_current_resource
      expect(@provider.current_resource.service_name).to eq("chef")
    end
  end

  describe "when the service supports status" do
    before do
      @new_resource.supports({ status: true })
    end

    it "should run '/etc/rc.d/service_name status'" do
      expect(@provider).to receive(:shell_out).with("/etc/rc.d/chef status").and_return(OpenStruct.new(exitstatus: 0))
      @provider.load_current_resource
    end

    it "should set running to true if the status command returns 0" do
      allow(@provider).to receive(:shell_out).with("/etc/rc.d/chef status").and_return(OpenStruct.new(exitstatus: 0))
      @provider.load_current_resource
      expect(@provider.current_resource.running).to be_truthy
    end

    it "should set running to false if the status command returns anything except 0" do
      allow(@provider).to receive(:shell_out).with("/etc/rc.d/chef status").and_return(OpenStruct.new(exitstatus: 1))
      @provider.load_current_resource
      expect(@provider.current_resource.running).to be_falsey
    end

    it "should set running to false if the status command raises" do
      allow(@provider).to receive(:shell_out).with("/etc/rc.d/chef status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @provider.load_current_resource
      expect(@provider.current_resource.running).to be_falsey
    end

  end

  describe "when a status command has been specified" do
    before do
      @new_resource.status_command("/etc/rc.d/chefhasmonkeypants status")
    end

    it "should run the services status command if one has been specified" do
      expect(@provider).to receive(:shell_out).with("/etc/rc.d/chefhasmonkeypants status").and_return(OpenStruct.new(exitstatus: 0))
      @provider.load_current_resource
    end

  end

  it "should raise error if the node has a nil ps property and no other means to get status" do
    @node.automatic_attrs[:command] = { ps: nil }
    @provider.define_resource_requirements
    @provider.action = :start
    expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
  end

  it "should raise error if the node has an empty ps property and no other means to get status" do
    @node.automatic_attrs[:command] = { ps: "" }
    @provider.define_resource_requirements
    @provider.action = :start
    expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
  end

  it "should fail if file /etc/rc.conf does not exist" do
    allow(::File).to receive(:exist?).with("/etc/rc.conf").and_return(false)
    expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Service)
  end

  it "should fail if file /etc/rc.conf does not contain DAEMONS array" do
    allow(::File).to receive(:read).with("/etc/rc.conf").and_return("")
    expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Service)
  end

  describe "when discovering service status with ps" do
    before do
      @stdout = StringIO.new(<<~DEFAULT_PS)
        aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb
        aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash
        aj        8119  6041  0 21:34 pts/3    00:00:03 vi init_service_spec.rb
      DEFAULT_PS
      @status = double("Status", exitstatus: 0, stdout: @stdout)
      allow(@provider).to receive(:shell_out!).and_return(@status)

      @node.automatic_attrs[:command] = { ps: "ps -ef" }
    end

    it "determines the service is running when it appears in ps" do
      @stdout = StringIO.new(<<~RUNNING_PS)
        aj        7842  5057  0 21:26 pts/2    00:00:06 chef
        aj        7842  5057  0 21:26 pts/2    00:00:06 poos
      RUNNING_PS
      allow(@status).to receive(:stdout).and_return(@stdout)
      @provider.load_current_resource
      expect(@provider.current_resource.running).to be_truthy
    end

    it "determines the service is not running when it does not appear in ps" do
      allow(@provider).to receive(:shell_out!).and_return(@status)
      @provider.load_current_resource
      expect(@provider.current_resource.running).to be_falsey
    end

    it "should raise an exception if ps fails" do
      allow(@provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @provider.load_current_resource
      @provider.action = :start
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
    end
  end

  it "should return existing entries in DAEMONS array" do
    allow(::File).to receive(:read).with("/etc/rc.conf").and_return("DAEMONS=(network !apache ssh)")
    expect(@provider.daemons).to eq(["network", "!apache", "ssh"])
  end

  context "when the current service status is known" do
    before do
      @current_resource = Chef::Resource::Service.new("chef")
      @provider.current_resource = @current_resource
    end

    describe Chef::Provider::Service::Arch, "enable_service" do
      # before(:each) do
      #   @new_resource = double("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub(:start_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub(:new).and_return(@current_resource)
      # end

      it "should add chef to DAEMONS array" do
        allow(::File).to receive(:read).with("/etc/rc.conf").and_return("DAEMONS=(network)")
        expect(@provider).to receive(:update_daemons).with(%w{network chef})
        @provider.enable_service
      end
    end

    describe Chef::Provider::Service::Arch, "disable_service" do
      # before(:each) do
      #   @new_resource = double("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub(:start_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub(:new).and_return(@current_resource)
      # end

      it "should remove chef from DAEMONS array" do
        allow(::File).to receive(:read).with("/etc/rc.conf").and_return("DAEMONS=(network chef)")
        expect(@provider).to receive(:update_daemons).with(["network", "!chef"])
        @provider.disable_service
      end
    end

    describe Chef::Provider::Service::Arch, "start_service" do
      # before(:each) do
      #   @new_resource = double("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub(:start_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub(:new).and_return(@current_resource)
      # end

      it "should call the start command if one is specified" do
        @new_resource.start_command("/etc/rc.d/chef startyousillysally")
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/chef startyousillysally", default_env: false)
        @provider.start_service
      end

      it "should call '/etc/rc.d/service_name start' if no start command is specified" do
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/#{@new_resource.service_name} start", default_env: false)
        @provider.start_service
      end
    end

    describe Chef::Provider::Service::Arch, "stop_service" do
      # before(:each) do
      #   @new_resource = double("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub(:stop_command).and_return(false)
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub(:new).and_return(@current_resource)
      # end

      it "should call the stop command if one is specified" do
        @new_resource.stop_command("/etc/rc.d/chef itoldyoutostop")
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/chef itoldyoutostop", default_env: false)
        @provider.stop_service
      end

      it "should call '/etc/rc.d/service_name stop' if no stop command is specified" do
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/#{@new_resource.service_name} stop", default_env: false)
        @provider.stop_service
      end
    end

    describe Chef::Provider::Service::Arch, "restart_service" do
      # before(:each) do
      #   @new_resource = double("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub(:restart_command).and_return(false)
      #   @new_resource.stub(:supports).and_return({:restart => false})
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub(:new).and_return(@current_resource)
      # end

      it "should call 'restart' on the service_name if the resource supports it" do
        @new_resource.supports({ restart: true })
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/#{@new_resource.service_name} restart", default_env: false)
        @provider.restart_service
      end

      it "should call the restart_command if one has been specified" do
        @new_resource.restart_command("/etc/rc.d/chef restartinafire")
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/#{@new_resource.service_name} restartinafire", default_env: false)
        @provider.restart_service
      end

      it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
        expect(@provider).to receive(:stop_service)
        expect(@provider).to receive(:sleep).with(1)
        expect(@provider).to receive(:start_service)
        @provider.restart_service
      end
    end

    describe Chef::Provider::Service::Arch, "reload_service" do
      # before(:each) do
      #   @new_resource = double("Chef::Resource::Service",
      #     :null_object => true,
      #     :name => "chef",
      #     :service_name => "chef",
      #     :running => false
      #   )
      #   @new_resource.stub(:reload_command).and_return(false)
      #   @new_resource.stub(:supports).and_return({:reload => false})
      #
      #   @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
      #   Chef::Resource::Service.stub(:new).and_return(@current_resource)
      # end

      it "should call 'reload' on the service if it supports it" do
        @new_resource.supports({ reload: true })
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/#{@new_resource.service_name} reload", default_env: false)
        @provider.reload_service
      end

      it "should should run the user specified reload command if one is specified and the service doesn't support reload" do
        @new_resource.reload_command("/etc/rc.d/chef lollerpants")
        expect(@provider).to receive(:shell_out!).with("/etc/rc.d/#{@new_resource.service_name} lollerpants", default_env: false)
        @provider.reload_service
      end
    end
  end
end
