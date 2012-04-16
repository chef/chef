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
  include SpecHelpers::Providers::Service

  before(:each) do
    provider.stub!(:shell_out!).and_return(status)
  end

  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(current_resource)
    provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    provider.load_current_resource
    current_resource.service_name.should == 'chef'
  end

  context 'when node has a nil :ps attribute' do
    let(:ps_command) { nil }

    it "should set running to false" do
      lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end
  end

  context 'when node has an empty :ps attribute' do
    let(:ps_command) { '' }

    it "should set running to false if the node has an empty ps attribute" do
      lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end
  end

  context 'when node has a :ps attribute' do
    it "should shell_out! the node's ps command" do
      provider.should_receive(:shell_out!).with(ps_command).and_return(status)
      provider.load_current_resource
    end

    it "should read stdout of the ps command" do
      provider.stub!(:shell_out!).and_return(status)
      stdout.should_receive(:each_line).and_return(true)
      provider.load_current_resource
    end

    context 'with process output with running process' do
      let(:stdout) { ps_with_service_running }

      it "should set running to true if the regex matches the output" do
        Chef::Resource::Service.stub!(:new).and_return(current_resource)
        provider.load_current_resource
        current_resource.running.should be_true
      end
    end

    it "should set running to false if the regex doesn't match" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      provider.load_current_resource
      current_resource.running.should be_false
    end

    it "should raise an exception if ps fails" do
      provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end
  end

  it "should return the current resource" do
    Chef::Resource::Service.stub!(:new).and_return(current_resource)
    provider.load_current_resource.should eql(current_resource)
  end

  describe "#start_service" do
    it "should call the start command if one is specified" do
      new_resource.stub!(:start_command).and_return("#{new_resource.start_command}")
      provider.should_receive(:shell_out!).with("#{new_resource.start_command}")
      provider.start_service()
    end

    it "should raise an exception if no start command is specified" do
      lambda { provider.start_service() }.should raise_error(Chef::Exceptions::Service)
    end
  end

  describe "#stop_service" do
    it "should call the stop command if one is specified" do
      new_resource.stop_command("/etc/init.d/themadness stop")
      provider.should_receive(:shell_out!).with("/etc/init.d/themadness stop")
      provider.stop_service()
    end

    it "should raise an exception if no stop command is specified" do
      lambda { provider.stop_service() }.should raise_error(Chef::Exceptions::Service)
    end
  end

  describe "#restart_service" do
    it "should call the restart command if one has been specified" do
      new_resource.restart_command("/etc/init.d/foo restart")
      provider.should_receive(:shell_out!).with("/etc/init.d/foo restart")
      provider.restart_service()
    end

    it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
      provider.should_receive(:stop_service)
      provider.should_receive(:sleep).with(1)
      provider.should_receive(:start_service)
      provider.restart_service()
    end
  end

  describe "#reload_service" do
    it "should should run the user specified reload command if one is specified" do
      new_resource.reload_command("kill -9 1")
      provider.should_receive(:shell_out!).with("kill -9 1")
      provider.reload_service()
    end
  end
end
