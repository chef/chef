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

require 'spec_helper'
require 'ostruct'

# most of this code has been ripped from init_service_spec.rb
# and is only slightly modified to match "arch" needs.

describe Chef::Provider::Service::Arch do
  include SpecHelpers::Providers::Service

  before(:each) do
    ::File.stub!(:exists?).with("/etc/rc.conf").and_return(true)
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network apache sshd)")
  end

  let(:ps_command) { 'ps -ef' }
  let(:new_resource) { Chef::Resource::Service.new(service_name).tap(&with_attributes.call(new_resource_attributes)) }

  let(:new_resource_attributes) do
    { :pattern => 'chef',
      :supports => { :status => false } }
  end

  describe '#load_current_resource' do
    context "when first created" do
      let(:status) { mock('Status', :exitstatus => 0, :stdout => '') }
      it "should set the current resources service name to the new resources service name" do
        provider.stub(:shell_out!).and_return(status)

        provider.load_current_resource
        provider.current_resource.service_name.should eql(service_name)
      end
    end

    context "when the service supports status" do
      let(:new_resource_attributes) do
        { :pattern => 'chef',
          :supports => { :status => true } }
      end

      let(:status) { mock('Status', :exitstatus => 0, :stdout => '') }

      it "should run '/etc/rc.d/service_name status'" do
        provider.should_receive(:shell_out!).with("/etc/rc.d/chef status").and_return(status)
        provider.load_current_resource
      end

      it "should set running to true if the the status command returns 0" do
        provider.stub!(:exec_status_cmd!).and_return(0)
        provider.load_current_resource
        provider.current_resource.running.should be_true
      end

      context 'with a non-zero exit status' do
        let(:status) { mock('Status', :exitstatus => 1, :stdout => '') }

        it "should set running to false if the status command returns anything except 0" do
          provider.stub!(:shell_out!).with("/etc/rc.d/chef status").and_return(status)
          provider.load_current_resource
          provider.current_resource.running.should be_false
        end
      end

      it "should set running to false if the status command raises" do
        provider.stub!(:shell_out).with("/etc/rc.d/chef status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
        provider.load_current_resource
        provider.current_resource.running.should be_false
      end

    end


    context "when a status command has been specified" do
      let(:status_command) { "/etc/rc.d/chefhasmonkeypants status" }
      let(:new_resource_attributes) do
        { :pattern => 'chef',
          :supports => { :status => false },
          :status_command => status_command }
      end

      let(:status) { mock('Status', :exitstatus => 0, :stdout => '') }

      it "should run the services status command if one has been specified" do
        provider.should_receive(:shell_out!).with(status_command).and_return(status)
        provider.load_current_resource
      end
    end

    context 'when node has a nil :ps attribute' do
      let(:ps_command) { nil }

      it "should set running to false if the node has a nil ps attribute" do
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
      end
    end

    context 'when node has an empty :ps attribute' do
      let(:ps_command) { '' }

      it "should set running to false if the node has an empty ps attribute" do
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
      end
    end

    it "should fail if file /etc/rc.conf does not exist" do
      ::File.stub!(:exists?).with("/etc/rc.conf").and_return(false)
      lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end

    it "should fail if file /etc/rc.conf does not contain DAEMONS array" do
      ::File.stub!(:read).with("/etc/rc.conf").and_return("")
      lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end

    context "when discovering service status with ps" do
      before do
        provider.stub!(:shell_out!).and_return(status)
      end

      context 'when service is running' do
        let(:stdout) { ps_with_service_running }

        it 'should set running to true' do
          provider.load_current_resource
          provider.current_resource.running.should be_true
        end
      end

      context 'when service is not running' do
        let(:stdout) { ps_without_service_running }

        it 'should set running to false' do
          provider.load_current_resource
          provider.current_resource.running.should be_false
        end
      end

      it "should raise an exception if ps fails" do
        provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
      end
    end

    it "should return existing entries in DAEMONS array" do
      ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network !apache ssh)")
      provider.daemons.should == ['network', '!apache', 'ssh']
    end
  end

  context "when the current service status is known" do
    before do
      provider.current_resource = current_resource
    end

    let(:current_resource) { Chef::Resource::Service.new(service_name) }

    describe "#enable_service" do
      it "should add chef to DAEMONS array" do
        ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network)")
        provider.should_receive(:update_daemons).with(['network', 'chef'])
        provider.enable_service()
      end
    end

    describe "#disable_service" do
      it "should remove chef from DAEMONS array" do
        ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network chef)")
        provider.should_receive(:update_daemons).with(['network', '!chef'])
        provider.disable_service()
      end
    end


    describe "#start_service" do
      it "should call the start command if one is specified" do
        new_resource.stub!(:start_command).and_return("/etc/rc.d/chef startyousillysally")
        provider.should_receive(:shell_out!).with("/etc/rc.d/chef startyousillysally")
        provider.start_service()
      end

      it "should call '/etc/rc.d/service_name start' if no start command is specified" do
        provider.should_receive(:shell_out!).with("/etc/rc.d/#{new_resource.service_name} start")
        provider.start_service()
      end
    end

    describe "#stop_service" do
      it "should call the stop command if one is specified" do
        new_resource.stub!(:stop_command).and_return("/etc/rc.d/chef itoldyoutostop")
        provider.should_receive(:shell_out!).with("/etc/rc.d/chef itoldyoutostop")
        provider.stop_service()
      end

      it "should call '/etc/rc.d/service_name stop' if no stop command is specified" do
        provider.should_receive(:shell_out!).with("/etc/rc.d/#{new_resource.service_name} stop")
        provider.stop_service()
      end
    end

    describe "#restart_service" do
      it "should call 'restart' on the service_name if the resource supports it" do
        new_resource.stub!(:supports).and_return({:restart => true})
        provider.should_receive(:shell_out!).with("/etc/rc.d/#{new_resource.service_name} restart")
        provider.restart_service()
      end

      it "should call the restart_command if one has been specified" do
        new_resource.stub!(:restart_command).and_return("/etc/rc.d/chef restartinafire")
        provider.should_receive(:shell_out!).with("/etc/rc.d/#{new_resource.service_name} restartinafire")
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
      it "should call 'reload' on the service if it supports it" do
        new_resource.stub!(:supports).and_return({:reload => true})
        provider.should_receive(:shell_out!).with("/etc/rc.d/#{new_resource.service_name} reload")
        provider.reload_service()
      end

      it "should should run the user specified reload command if one is specified and the service doesn't support reload" do
        new_resource.stub!(:reload_command).and_return("/etc/rc.d/chef lollerpants")
        provider.should_receive(:shell_out!).with("/etc/rc.d/#{new_resource.service_name} lollerpants")
        provider.reload_service()
      end
    end
  end
end
