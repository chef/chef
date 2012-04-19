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

require 'spec_helper'

describe Chef::Provider::Service::Upstart do
  include SpecHelpers::Providers::Service

  let(:service_name) { 'rsyslog' }
  let(:node) { Chef::Node.new.tap(&inject_hash.call(node_attributes)) }
  let(:node_attributes) { default_node_attributes }
  let(:default_node_attributes) do
    { :name => 'upstarter',
      :platform => 'ubuntu',
      :platform_version => platform_version }
  end

  let(:platform_version) { '9.10' }
  let(:provider) { Chef::Provider::Service::Upstart.new(new_resource, run_context) }

  describe "#initialize" do
    subject { provider }
    let(:platform) { nil }

    context 'on Ubuntu 9.04' do
      let(:platform_version) { '9.04' }
      its(:upstart_job_dir) { should eql('/etc/event.d') }
      its(:upstart_conf_suffix) { should eql('') }
    end

    context 'on Ubuntu 9.10' do
      let(:platform_version) { '9.10' }

      its(:upstart_job_dir) { should eql('/etc/init') }
      its(:upstart_conf_suffix) { should eql('.conf') }
    end

    context 'on default Ubuntu' do
      let(:platform_version) { '9000' }

      its(:upstart_job_dir) { should eql('/etc/init') }
      its(:upstart_conf_suffix) { should eql('.conf') }
    end
  end

  describe "#load_current_resource" do
    before(:each) do
      provider.stub!(:service_running?).and_return(true)
      provider.stub!(:service_enabled?).and_return(true)
    end

    let(:new_resource) { current_resource }
    let(:node_attributes) { default_node_attributes.merge({ :command => { :ps => 'ps -ax' }}) }

    it "should create a current resource with the name of the new resource" do
      provider.load_current_resource
      provider.current_resource.name.should eql(new_resource.name)
    end

    it "should set the current resources service name to the new resources service name" do
      provider.load_current_resource
      provider.current_resource.service_name.should eql(new_resource.service_name)
    end

    it "should return the current resource" do
      provider.load_current_resource.should eql(provider.current_resource)
    end

    it 'should set running state' do
      provider.load_current_resource
      provider.current_resource.running.should_not be_nil
    end

    it 'should set enable state' do
      provider.load_current_resource
      provider.current_resource.enabled.should_not be_nil
    end
  end

  context "when enabling and disabling service" do
    before(:each) do
      provider.current_resource = current_resource
      Chef::Util::FileEdit.stub!(:new)
    end

    it "should enable the service if it is not enabled" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      file = Object.new
      Chef::Util::FileEdit.stub!(:new).and_return(file)
      current_resource.stub!(:enabled).and_return(false)
      file.should_receive(:search_file_replace)
      file.should_receive(:write_file)
      provider.enable_service()
    end

    it "should disable the service if it is enabled" do
      Chef::Resource::Service.stub!(:new).and_return(current_resource)
      file = Object.new
      Chef::Util::FileEdit.stub!(:new).and_return(file)
      current_resource.stub!(:enabled).and_return(true)
      file.should_receive(:search_file_replace)
      file.should_receive(:write_file)
      provider.disable_service()
    end
  end

  context "when starting and stoping service" do
    before(:each) do
      provider.current_resource = current_resource
    end

    it "should call the start command if one is specified" do
      new_resource.stub!(:start_command).and_return("/sbin/rsyslog startyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog startyousillysally")
      provider.start_service()
    end

    it "should call '/sbin/start service_name' if no start command is specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("/sbin/start #{new_resource.service_name}").and_return(0)
      provider.start_service()
    end

    it "should not call '/sbin/start service_name' if it is already running" do
      current_resource.stub!(:running).and_return(true)
      provider.should_not_receive(:shell_out_with_systems_locale!).with("/sbin/start #{new_resource.service_name}").and_return(0)
      provider.start_service()
    end

    context 'with parameters' do
      let(:parameters) { { 'OSD_ID' => '2' } }

      it "should pass parameters to the start command if they are provided" do
        new_resource.parameters parameters
        provider.current_resource = current_resource
        provider.should_receive(:shell_out_with_systems_locale!).with("/sbin/start rsyslog OSD_ID=2").and_return(0)
        provider.start_service()
      end
    end

    it "should call the restart command if one is specified" do
      current_resource.stub!(:running).and_return(true)
      new_resource.stub!(:restart_command).and_return("/sbin/rsyslog restartyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog restartyousillysally")
      provider.restart_service()
    end

    it "should call '/sbin/restart service_name' if no restart command is specified" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:shell_out_with_systems_locale!).with("/sbin/restart #{new_resource.service_name}").and_return(0)
      provider.restart_service()
    end

    it "should call '/sbin/start service_name' if restart_service is called for a stopped service" do
      current_resource.stub!(:running).and_return(false)
      provider.should_receive(:shell_out_with_systems_locale!).with("/sbin/start #{new_resource.service_name}").and_return(0)
      provider.restart_service()
    end

    it "should call the reload command if one is specified" do
      current_resource.stub!(:running).and_return(true)
      new_resource.stub!(:reload_command).and_return("/sbin/rsyslog reloadyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog reloadyousillysally")
      provider.reload_service()
    end

    it "should call '/sbin/reload service_name' if no reload command is specified" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:shell_out_with_systems_locale!).with("/sbin/reload #{new_resource.service_name}").and_return(0)
      provider.reload_service()
    end

    it "should call the stop command if one is specified" do
      current_resource.stub!(:running).and_return(true)
      new_resource.stub!(:stop_command).and_return("/sbin/rsyslog stopyousillysally")
      provider.should_receive(:shell_out!).with("/sbin/rsyslog stopyousillysally")
      provider.stop_service()
    end

    it "should call '/sbin/stop service_name' if no stop command is specified" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:shell_out_with_systems_locale!).with("/sbin/stop #{new_resource.service_name}").and_return(0)
      provider.stop_service()
    end

    it "should not call '/sbin/stop service_name' if it is already stopped" do
      current_resource.stub!(:running).and_return(false)
      provider.should_not_receive(:shell_out_with_systems_locale!).with("/sbin/stop #{new_resource.service_name}").and_return(0)
      provider.stop_service()
    end
  end

  describe '#upstart_state' do
    subject { should_request_status; provider.upstart_state }
    let(:stdout) { StringIO.new("rsyslog start/running") }
    let(:should_request_status) { provider.should_receive(:shell_out!).with("/sbin/status rsyslog").and_return(status) }

    it "should run '/sbin/status <service name>'" do
      should_not be_nil
    end

    context "when the status command uses the new format" do
      context 'when process is running' do
        let(:stdout) { StringIO.new("rsyslog start/running") }
        it { should eql('running') }
      end

      context 'when process is not running' do
        let(:stdout) { StringIO.new("rsyslog stop/waiting") }
        it { should eql('waiting') }
      end
    end

    context "when the status command uses the old format" do
      context 'when process is running' do
        let(:stdout) { StringIO.new("rsyslog (start) running, process 32225") }
        it { should eql('running') }
      end

      context 'when process is not running' do
        let(:stdout) { StringIO.new("rsyslog (stop) waiting") }
        it { should eql('waiting') }
      end
    end
  end

  describe '#service_running?' do
    subject { given; provider.service_running? }

    context 'when checking upstart state' do
      let(:given) { assume_upstart_state }
      let(:assume_upstart_state) { provider.should_receive(:upstart_state).and_return(upstart_state) }

      context "when #upstart_state returns 'running'" do
        let(:upstart_state) { 'running' }
        it { should be_true }
      end

      context "when #upstart_state returns 'waiting'" do
        let(:upstart_state) { 'waiting' }
        it { should be_false }
      end

      context 'when #upstart_state throws Mixlib::ShellOut::ShellCommandFailed' do
        let(:given) { assume_shell_command_failed }
        let(:assume_shell_command_failed) { provider.stub!(:upstart_state).and_raise(Mixlib::ShellOut::ShellCommandFailed) }
        it { should be_false }
      end
    end

    context "when a status command has been specified" do
      let(:given) { assume_status_command }
      let(:assume_status_command) { new_resource.stub!(:status_command).and_return("/bin/chefhasmonkeypants status") }

      it "should run the services status command if one has been specified" do
        provider.stub!(:shell_out_with_systems_locale!).with("/bin/chefhasmonkeypants status").and_return(0)
        should be_true
      end

      it "should set running to false if it catches a Mixlib::ShellOut::ShellCommandFailed when using a status command" do
        provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        should be_false
      end
    end

  end

  describe '#service_enabled?' do
    subject { given; provider.service_enabled? }

    let(:given) do
      assume_upstart_conf_exists
      assume_upstart_conf_content
    end

    let(:assume_upstart_conf_exists) { ::File.stub!(:exists?).and_return(:upstart_conf_exists?) }
    let(:assume_upstart_conf_content) { ::File.stub!(:open).and_yield(upstart_conf) }
    let(:upstart_conf) { mock('/etc/init/rsyslog.conf', :gets => upstart_conf_content) }
    let(:upstart_conf_exists?) { true }
    let(:upstart_conf_content) { nil }

    context "when job configuration contains 'start on filesystem'" do
      let(:upstart_conf_content) { 'start on filesystem' }
      it { should be_true }
    end

    context "when job configuration contains '#start on filesystem'" do
      let(:upstart_conf_content) { '#start on filesystem' }
      it { should be_false }
    end

    context 'when no job configuration file is found' do
      let(:upstart_conf_exists?) { false }
      it { should be_false }
    end
  end
end
