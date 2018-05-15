#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Provider::Service::Init, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = { :ps => "ps -ef" }
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")

    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Init.new(@new_resource, @run_context)
    allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)

    @stdout = StringIO.new(<<-PS)
aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb
aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash
aj        8119  6041  0 21:34 pts/3    00:00:03 vi init_service_spec.rb
PS
    @status = double("Status", :exitstatus => 0, :stdout => @stdout)
    allow(@provider).to receive(:shell_out!).and_return(@status)
  end

  it "should create a current resource with the name of the new resource" do
    @provider.load_current_resource
    expect(@provider.current_resource).to equal(@current_resource)
  end

  it "should set the current resources service name to the new resources service name" do
    @provider.load_current_resource
    expect(@current_resource.service_name).to eq("chef")
  end

  describe "when the service supports status" do
    before do
      @new_resource.supports({ :status => true })
    end

    it "should run '/etc/init.d/service_name status'" do
      expect(@provider).to receive(:shell_out).with("/etc/init.d/#{@current_resource.service_name} status").and_return(@status)
      @provider.load_current_resource
    end

    it "should set running to true if the status command returns 0" do
      allow(@provider).to receive(:shell_out).with("/etc/init.d/#{@current_resource.service_name} status").and_return(@status)
      @provider.load_current_resource
      expect(@current_resource.running).to be_truthy
    end

    it "should set running to false if the status command returns anything except 0" do
      allow(@status).to receive(:exitstatus).and_return(1)
      allow(@provider).to receive(:shell_out).with("/etc/init.d/#{@current_resource.service_name} status").and_return(@status)
      @provider.load_current_resource
      expect(@current_resource.running).to be_falsey
    end

    it "should set running to false if the status command raises" do
      allow(@provider).to receive(:shell_out).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @provider.load_current_resource
      expect(@current_resource.running).to be_falsey
    end
  end

  describe "when a status command has been specified" do
    before do
      @new_resource.status_command("/etc/init.d/chefhasmonkeypants status")
    end

    it "should run the services status command if one has been specified" do
      expect(@provider).to receive(:shell_out).with("/etc/init.d/chefhasmonkeypants status").and_return(@status)
      @provider.load_current_resource
    end

  end

  describe "when an init command has been specified" do
    before do
      @new_resource.init_command("/opt/chef-server/service/erchef")
      @provider = Chef::Provider::Service::Init.new(@new_resource, @run_context)
    end

    it "should use the init_command if one has been specified" do
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/opt/chef-server/service/erchef start")
      @provider.start_service
    end

  end

  describe "when the node has not specified a ps command" do

    it "should raise an error if the node has a nil ps attribute" do
      @node.automatic_attrs[:command] = { :ps => nil }
      @provider.load_current_resource
      @provider.action = :start
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
    end

    it "should raise an error if the node has an empty ps attribute" do
      @node.automatic_attrs[:command] = { :ps => "" }
      @provider.load_current_resource
      @provider.action = :start
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
    end

  end

  describe "when we have a 'ps' attribute" do
    it "should shell_out! the node's ps command" do
      expect(@provider).to receive(:shell_out!).and_return(@status)
      @provider.load_current_resource
    end

    it "should set running to true if the regex matches the output" do
      @stdout = StringIO.new(<<-RUNNING_PS)
aj        7842  5057  0 21:26 pts/2    00:00:06 chef
aj        7842  5057  0 21:26 pts/2    00:00:06 poos
RUNNING_PS
      allow(@status).to receive(:stdout).and_return(@stdout)
      @provider.load_current_resource
      expect(@current_resource.running).to be_truthy
    end

    it "should set running to false if the regex doesn't match" do
      allow(@provider).to receive(:shell_out!).and_return(@status)
      @provider.load_current_resource
      expect(@current_resource.running).to be_falsey
    end

    it "should raise an exception if ps fails" do
      allow(@provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @provider.load_current_resource
      @provider.action = :start
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
    end
  end

  it "should return the current resource" do
    expect(@provider.load_current_resource).to eql(@current_resource)
  end

  describe "when starting the service" do
    it "should call the start command if one is specified" do
      @new_resource.start_command("/etc/init.d/chef startyousillysally")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef startyousillysally")
      @provider.start_service()
    end

    it "should call '/etc/init.d/service_name start' if no start command is specified" do
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/#{@new_resource.service_name} start")
      @provider.start_service()
    end
  end

  describe Chef::Provider::Service::Init, "stop_service" do
    it "should call the stop command if one is specified" do
      @new_resource.stop_command("/etc/init.d/chef itoldyoutostop")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef itoldyoutostop")
      @provider.stop_service()
    end

    it "should call '/etc/init.d/service_name stop' if no stop command is specified" do
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/#{@new_resource.service_name} stop")
      @provider.stop_service()
    end
  end

  describe "when restarting a service" do
    it "should call 'restart' on the service_name if the resource supports it" do
      @new_resource.supports({ :restart => true })
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/#{@new_resource.service_name} restart")
      @provider.restart_service()
    end

    it "should call the restart_command if one has been specified" do
      @new_resource.restart_command("/etc/init.d/chef restartinafire")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/#{@new_resource.service_name} restartinafire")
      @provider.restart_service()
    end

    it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
      expect(@provider).to receive(:stop_service)
      expect(@provider).to receive(:sleep).with(1)
      expect(@provider).to receive(:start_service)
      @provider.restart_service()
    end
  end

  describe "when reloading a service" do
    it "should call 'reload' on the service if it supports it" do
      @new_resource.supports({ :reload => true })
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef reload")
      @provider.reload_service()
    end

    it "should should run the user specified reload command if one is specified and the service doesn't support reload" do
      @new_resource.reload_command("/etc/init.d/chef lollerpants")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef lollerpants")
      @provider.reload_service()
    end
  end

  describe "when a custom command has been specified" do
    before do
      @new_resource.start_command("/etc/init.d/chef startyousillysally")
      expect(@provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef startyousillysally")
    end

    it "should still pass all why run assertions" do
      expect { @provider.run_action(:start) }.not_to raise_error
    end
  end
end
