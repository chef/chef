#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Service::Freebsd do
  include SpecHelpers::Providers::Service

  let(:ps_command) { 'ps -ax' }
  let(:service_name) { 'apache22' }

  let(:new_resource) { Chef::Resource::Service.new(service_name).tap(&with_attributes.call(new_resource_attributes)) }
  let(:new_resource_attributes) do
    { :pattern => 'httpd',
      :supports => { :status => false } }
  end

  describe "#load_current_resource" do
    before(:each) do
      ::File.stub!(:exists?).and_return(false)
      ::File.stub!(:exists?).with("/usr/local/etc/rc.d/apache22").and_return(true)
      ::File.stub!(:open).and_return(rc_d_content)
    end

    let(:rc_d_content) { StringIO.new(<<-RC_D_APACHE22) }
sshd_enable="YES"
apache22_enable="YES"
RC_D_APACHE22

    context 'with defaults' do
      before(:each) { provider.stub!(:exec_ps_cmd!).and_return(status) }

      let(:new_resource) { current_resource }

      it "should return the current resource" do
        Chef::Resource::Service.stub!(:new).and_return(current_resource)
        provider.load_current_resource.should eql(current_resource)
      end

      it "should create a current resource with the name of the new resource" do
        Chef::Resource::Service.should_receive(:new).and_return(current_resource)
        provider.load_current_resource
      end

      it "should set the current resources service name to the new resources service name" do
        provider.load_current_resource
        current_resource.service_name.should == new_resource.service_name
      end
    end

    context "when the service supports status" do
      let(:new_resource_attributes) do
        { :pattern => 'httpd',
          :supports => { :status => true } }
      end

      it "should run '/etc/init.d/service_name status'" do
        provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/apache22 status").and_return(status)
        provider.load_current_resource
      end

      it "should set running to true if the the status command returns 0" do
        provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/apache22 status").and_return(status)
        provider.load_current_resource
        provider.current_resource.running.should be_true
      end

      it "should set running to false if the status command returns anything except 0" do
        provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/apache22 status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
        provider.load_current_resource
        provider.current_resource.running.should be_false
      end
    end

    describe "when a status command has been specified" do
      let(:new_resource_attributes) do
        { :pattern => 'httpd',
          :status_command => status_command,
          :supports => { :status => false } }
      end

      let(:status_command) { "/bin/chefhasmonkeypants status" }

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

    context "when we have a 'ps' attribute" do
      let(:ps_command) { 'ps -ax' }
      let(:stdout) { StringIO.new(<<-PS_OUTPUT) }
 555  ??  Ss     0:05.16 /usr/sbin/cron -s
9881  ??  Ss     0:06.67 /usr/local/sbin/httpd -DNOHTTPACCEPT
PS_OUTPUT

      it "should shell_out! the node's ps command" do
        provider.should_receive(:shell_out!).with(ps_command).and_return(status)
        provider.load_current_resource
      end

      it "should read stdout of the ps command" do
        provider.stub!(:shell_out!).and_return(status)
        stdout.should_receive(:each_line).and_return(true)
        provider.load_current_resource
      end

      it "should set running to true if the regex matches the output" do
        provider.stub!(:shell_out!).and_return(status)
        provider.load_current_resource
        provider.current_resource.running.should be_true
      end

      it "should set running to false if the regex doesn't match" do
        provider.stub!(:shell_out!).and_return(status)
        provider.load_current_resource
        current_resource.running.should be_false
      end

      it "should raise an exception if ps fails" do
        provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
      end
    end

    describe "#start_service" do
      before(:each) { provider.stub!(:exec_ps_cmd!).and_return(status) }

      it "should call the start command if one is specified" do
        new_resource.start_command("/etc/rc.d/chef startyousillysally")
        provider.should_receive(:shell_out!).with("/etc/rc.d/chef startyousillysally")
        provider.load_current_resource
        provider.start_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststart' if no start command is specified" do
        provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} faststart")
        provider.load_current_resource
        provider.start_service()
      end
    end

    describe "#stop_service" do
      before(:each) { provider.stub!(:exec_ps_cmd!).and_return(status) }

      it "should call the stop command if one is specified" do
        new_resource.stop_command("/etc/init.d/chef itoldyoutostop")
        provider.should_receive(:shell_out!).with("/etc/init.d/chef itoldyoutostop")
        provider.load_current_resource
        provider.stop_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststop' if no stop command is specified" do
        provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} faststop")
        provider.load_current_resource
        provider.stop_service()
      end
    end

    describe "#restart_service" do
      before(:each) { provider.stub!(:exec_ps_cmd!).and_return(status) }

      it "should call 'restart' on the service_name if the resource supports it" do
        new_resource.supports({:restart => true})
        provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} fastrestart")
        provider.load_current_resource
        provider.restart_service()
      end

      it "should call the restart_command if one has been specified" do
        new_resource.restart_command("/etc/init.d/chef restartinafire")
        provider.should_receive(:shell_out!).with("/etc/init.d/chef restartinafire")
        provider.load_current_resource
        provider.restart_service()
      end
    end

  end

  describe "#enable_service" do
    before do
      provider.current_resource = current_resource
      provider.stub!(:service_enable_variable_name).and_return("apache22_enable")
    end

    it "should should enable the service if it is not enabled" do
      current_resource.stub!(:enabled).and_return(false)
      provider.should_receive(:read_rc_conf).and_return([ "foo", "apache22_enable=\"NO\"", "bar" ])
      provider.should_receive(:write_rc_conf).with(["foo", "bar", "apache22_enable=\"YES\""])
      provider.enable_service()
    end

    it "should enable the service if it is not enabled and not already specified in the rc.conf file" do
      current_resource.stub!(:enabled).and_return(false)
      provider.should_receive(:read_rc_conf).and_return([ "foo", "bar" ])
      provider.should_receive(:write_rc_conf).with(["foo", "bar", "apache22_enable=\"YES\""])
      provider.enable_service()
    end

    it "should not enable the service if it is already enabled" do
      current_resource.stub!(:enabled).and_return(true)
      provider.should_not_receive(:write_rc_conf)
      provider.enable_service
    end
  end

  describe "#disable_service" do
    before do
      provider.current_resource = current_resource
      provider.stub!(:service_enable_variable_name).and_return("apache22_enable")
    end

    it "should should disable the service if it is not disabled" do
      current_resource.stub!(:enabled).and_return(true)
      provider.should_receive(:read_rc_conf).and_return([ "foo", "apache22_enable=\"YES\"", "bar" ])
      provider.should_receive(:write_rc_conf).with(["foo", "bar", "apache22_enable=\"NO\""])
      provider.disable_service()
    end

    it "should not disable the service if it is already disabled" do
      current_resource.stub!(:enabled).and_return(false)
      provider.should_not_receive(:write_rc_conf)
      provider.disable_service()
    end
  end
end
