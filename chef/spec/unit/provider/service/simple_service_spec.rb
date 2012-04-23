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

describe Chef::Provider::Service::Simple do
  include SpecHelpers::Providers::Service

  let(:current_resource) { Chef::Resource::Service.new(service_name) }

  describe '#load_current_resource' do
    subject { given; provider.load_current_resource }

    let(:given) { assume_service_is_running }
    let(:assume_service_is_running) {  provider.should_receive(:service_running?).and_return(true) }

    it "should create a current resource with the name of the new resource" do
      subject.name.should eql(new_resource.name)
    end

    it "should set the current resources service name to the new resources service name" do
      subject.service_name.should eql(new_resource.service_name)
    end

    it "should return the current resource" do
      subject.should eql(provider.current_resource)
    end
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

  describe '#exec_status_cmd!' do
    subject { given; provider.send(:exec_status_cmd!) }
    let(:given) do
      assume_status_cmd
      should_shell_out
    end

    let(:assume_status_cmd) { provider.stub!(:status_cmd).and_return(status_cmd) }
    let(:should_shell_out) { provider.should_receive(:shell_out!).with(status_cmd).and_return(status) }
    let(:status_cmd) { 'ps -ef' }

    context 'when exit status is 0' do
      let(:exitstatus) { 0 }
      it { should be_true }
    end

    context 'when exit status is 1' do
      let(:exitstatus) { 1 }
      it { should be_false }
    end

    context 'when shell out fails' do
      let(:should_shell_out) { provider.should_receive(:shell_out!).with(status_cmd).and_raise(Mixlib::ShellOut::ShellCommandFailed) }
      it { should be_false }
    end
  end

  describe '#service_running_in_ps?' do
    subject { given; provider.send(:service_running_in_ps?) }
    let(:given) { provider.new_resource = new_resource }

    context 'when node has a nil :ps attribute' do
      let(:ps_command) { nil }

      it "should raise Chef::Exceptions::Service" do
        lambda { subject }.should raise_error(Chef::Exceptions::Service)
      end
    end

    context 'when node has an empty :ps attribute' do
      let(:ps_command) { '' }

      it "should raise Chef::Exceptions::Service" do
        lambda { subject }.should raise_error(Chef::Exceptions::Service)
      end
    end

    context 'when node has a :ps attribute' do
      let(:given) do
        should_exec_ps_cmd
        provider.new_resource = new_resource
      end

      let(:should_exec_ps_cmd) { provider.should_receive(:shell_out!).with(ps_command).and_return(status) }

      it "should shell_out! the node's ps command" do
        should_exec_ps_cmd
        should_not be_nil
      end

      it "should read stdout of the ps command" do
        stdout.should_receive(:each_line).and_return(true)
        should_not be_nil
      end

      context 'with process output with running process' do
        let(:stdout) { ps_with_service_running }
        it { should be_true }
      end

      context 'with process output without running process' do
        let(:stdout) { ps_without_service_running }
        it { should be_false }
      end

      it "should raise an exception if ps fails" do
        provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
      end
    end
  end
end
