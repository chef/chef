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

  let(:node) do
    node = Chef::Node.new
    node.automatic_attrs[:command] = {:ps => "ps -ax"}
    node
  end

  let(:new_resource) do
    new_resource = Chef::Resource::Service.new("apache22")
    new_resource.pattern("httpd")
    new_resource.supports({:status => false})
    new_resource
  end

  let(:current_resource) do
    current_resource = Chef::Resource::Service.new("apache22")
    current_resource
  end

  let(:provider) do
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    provider = Chef::Provider::Service::Freebsd.new(new_resource,run_context)
    provider.action = :start
    provider
  end

  # ununsed?
  #  let(:init_command) { "/usr/local/etc/rc.d/apache22" }

  before do
    allow(Chef::Resource::Service).to receive(:new).and_return(current_resource)
  end

  describe "load_current_resource" do
    let(:stdout) do
      StringIO.new(<<-PS_SAMPLE)
413  ??  Ss     0:02.51 /usr/sbin/syslogd -s
539  ??  Is     0:00.14 /usr/sbin/sshd
545  ??  Ss     0:17.53 sendmail: accepting connections (sendmail)
PS_SAMPLE
    end

    let(:status) { double(:stdout => stdout, :exitstatus => 0) }

    before(:each) do
      allow(provider).to receive(:shell_out!).with(node[:command][:ps]).and_return(status)

      allow(::File).to receive(:exists?).and_return(false)
      allow(::File).to receive(:exists?).with("/usr/local/etc/rc.d/#{new_resource.service_name}").and_return(true)
      lines = double("lines")
      allow(lines).to receive(:each).and_yield("sshd_enable=\"YES\"").
                          and_yield("#{new_resource.name}_enable=\"YES\"")
      allow(::File).to receive(:open).and_return(lines)

      rc_with_name = StringIO.new(<<-RC_SAMPLE)
name="apache22"
rcvar=`set_rcvar`
RC_SAMPLE
      allow(::File).to receive(:open).with("/usr/local/etc/rc.d/#{new_resource.service_name}").and_return(rc_with_name)
      allow(provider).to receive(:service_enable_variable_name).and_return nil
    end

    it "should create a current resource with the name of the new resource" do
      expect(Chef::Resource::Service).to receive(:new).and_return(current_resource)
      provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      provider.load_current_resource
      expect(current_resource.service_name).to eq(new_resource.service_name)
    end

    it "should not raise an exception if the rcscript have a name variable" do
      provider.load_current_resource
      expect { provider.service_enable_variable_name }.not_to raise_error
    end

    describe "when the service supports status" do
      before do
        new_resource.supports({:status => true})
      end

      it "should run '/etc/init.d/service_name status'" do
        expect(provider).to receive(:shell_out).with("/usr/local/etc/rc.d/#{current_resource.service_name} status").and_return(status)
        provider.load_current_resource
      end

      it "should set running to true if the status command returns 0" do
        expect(provider).to receive(:shell_out).with("/usr/local/etc/rc.d/#{current_resource.service_name} status").and_return(status)
        expect(current_resource).to receive(:running).with(true)
        provider.load_current_resource
      end

      it "should set running to false if the status command returns anything except 0" do
        expect(provider).to receive(:shell_out).with("/usr/local/etc/rc.d/#{current_resource.service_name} status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
        expect(current_resource).to receive(:running).with(false)
        provider.load_current_resource
       # provider.current_resource.running.should be_false
      end
    end

    describe "when a status command has been specified" do
      before do
        new_resource.status_command("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        expect(provider).to receive(:shell_out).with("/bin/chefhasmonkeypants status").and_return(status)
        provider.load_current_resource
      end

    end

    it "should raise error if the node has a nil ps attribute and no other means to get status" do
      node.automatic_attrs[:command] = {:ps => nil}
      provider.define_resource_requirements
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
    end

    it "should raise error if the node has an empty ps attribute and no other means to get status" do
      node.automatic_attrs[:command] = {:ps => ""}
      provider.define_resource_requirements
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
    end

    describe "when executing assertions" do
      it "should verify that /etc/rc.conf exists" do
        expect(::File).to receive(:exists?).with("/etc/rc.conf")
        allow(provider).to receive(:service_enable_variable_name).and_return("#{current_resource.service_name}_enable")
        provider.load_current_resource
      end

      context "and the init script is not found" do
        [ "start", "reload", "restart", "enable" ].each do |action|
          it "should raise an exception when the action is #{action}" do
            allow(::File).to receive(:exists?).and_return(false)
            provider.load_current_resource
            provider.define_resource_requirements
            expect(provider.instance_variable_get("@rcd_script_found")).to be_false
            provider.action = action
            expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
          end
        end

        [ "stop", "disable" ].each do |action|
          it "should not raise an error when the action is #{action}" do
            provider.action = action
            expect { provider.process_resource_requirements }.not_to raise_error
          end
        end
      end

      it "update state when current resource enabled state could not be determined" do
        expect(::File).to receive(:exists?).with("/etc/rc.conf").and_return false
        provider.load_current_resource
        expect(provider.instance_variable_get("@enabled_state_found")).to be_false
      end

      it "update state when current resource enabled state could be determined" do
        allow(::File).to receive(:exist?).with("/usr/local/etc/rc.d/#{new_resource.service_name}").and_return(true)
        expect(::File).to receive(:exists?).with("/etc/rc.conf").and_return  true
        provider.load_current_resource
        expect(provider.instance_variable_get("@enabled_state_found")).to be_false
        expect(provider.instance_variable_get("@rcd_script_found")).to be_true
        provider.define_resource_requirements
        expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service,
          "Could not find the service name in /usr/local/etc/rc.d/#{current_resource.service_name} and rcvar")
      end

      it "should throw an exception if service line is missing from rc.d script" do
          pending "not implemented" do
            expect(false).to be_true
          end
      end

    end

    describe "when we have a 'ps' attribute" do
      before do
        node.automatic_attrs[:command] = {:ps => "ps -ax"}
      end

      it "should shell_out! the node's ps command" do
        expect(provider).to receive(:shell_out!).with(node[:command][:ps]).and_return(status)
        provider.load_current_resource
      end

      it "should read stdout of the ps command" do
        allow(provider).to receive(:shell_out!).and_return(status)
        expect(stdout).to receive(:each_line).and_return(true)
        provider.load_current_resource
      end

      it "should set running to true if the regex matches the output" do
        allow(stdout).to receive(:each_line).and_yield("555  ??  Ss     0:05.16 /usr/sbin/cron -s").
                                  and_yield(" 9881  ??  Ss     0:06.67 /usr/local/sbin/httpd -DNOHTTPACCEPT")
        provider.load_current_resource
        expect(current_resource.running).to be_true
      end

      it "should set running to false if the regex doesn't match" do
        allow(provider).to receive(:shell_out!).and_return(status)
        provider.load_current_resource
        expect(current_resource.running).to be_false
      end

      it "should raise an exception if ps fails" do
        allow(provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        provider.load_current_resource
        provider.define_resource_requirements
        expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
      end
    end

    it "should return the current resource" do
      expect(provider.load_current_resource).to eql(current_resource)
    end

    describe "when starting the service" do
      it "should call the start command if one is specified" do
        new_resource.start_command("/etc/rc.d/chef startyousillysally")
        expect(provider).to receive(:shell_out!).with("/etc/rc.d/chef startyousillysally")
        provider.load_current_resource
        provider.start_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststart' if no start command is specified" do
        expect(provider).to receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} faststart")
        provider.load_current_resource
        provider.start_service()
      end
    end

    describe Chef::Provider::Service::Init, "stop_service" do
      it "should call the stop command if one is specified" do
        new_resource.stop_command("/etc/init.d/chef itoldyoutostop")
        expect(provider).to receive(:shell_out!).with("/etc/init.d/chef itoldyoutostop")
        provider.load_current_resource
        provider.stop_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststop' if no stop command is specified" do
        expect(provider).to receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} faststop")
        provider.load_current_resource
        provider.stop_service()
      end
    end

    describe "when restarting a service" do
      it "should call 'restart' on the service_name if the resource supports it" do
        new_resource.supports({:restart => true})
        expect(provider).to receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} fastrestart")
        provider.load_current_resource
        provider.restart_service()
      end

      it "should call the restart_command if one has been specified" do
        new_resource.restart_command("/etc/init.d/chef restartinafire")
        expect(provider).to receive(:shell_out!).with("/etc/init.d/chef restartinafire")
        provider.load_current_resource
        provider.restart_service()
      end
    end

    describe "when the rcscript does not have a name variable" do
      before do
        rc_with_noname = StringIO.new(<<-RC_SAMPLE)
rcvar=`set_rcvar`
RC_SAMPLE
        allow(::File).to receive(:open).with("/usr/local/etc/rc.d/#{current_resource.service_name}").and_return(rc_with_noname)
        provider.current_resource = current_resource
      end

      describe "when rcvar returns foobar_enable" do
        let(:rcvar_stdout) do
          rcvar_stdout = <<RCVAR_SAMPLE
# apache22
#
# #{current_resource.service_name}_enable="YES"
#   (default: "")
RCVAR_SAMPLE
        end

        before do
          status = double(:stdout => rcvar_stdout, :exitstatus => 0)
          allow(provider).to receive(:shell_out!).with("/usr/local/etc/rc.d/#{current_resource.service_name} rcvar").and_return(status)
        end

        it "should get the service name from rcvar if the rcscript does not have a name variable" do
          provider.load_current_resource
          allow(provider).to receive(:service_enable_variable_name).and_call_original
          expect(provider.service_enable_variable_name).to eq("#{current_resource.service_name}_enable")
        end

        it "should not raise an exception if the rcscript does not have a name variable" do
          provider.load_current_resource
          expect { provider.service_enable_variable_name }.not_to raise_error
        end
      end

      describe "when rcvar does not return foobar_enable" do
        let(:rcvar_stdout) do
          rcvar_stdout = <<RCVAR_SAMPLE
# service_with_noname
#
RCVAR_SAMPLE
        end

        before do
          status = double(:stdout => rcvar_stdout, :exitstatus => 0)
          allow(provider).to receive(:shell_out!).with("/usr/local/etc/rc.d/#{current_resource.service_name} rcvar").and_return(status)
        end

        [ "start", "reload", "restart", "enable" ].each do |action|
          it "should raise an exception when the action is #{action}" do
            provider.action = action
            provider.load_current_resource
            provider.define_resource_requirements
            expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
          end
        end

        [ "stop", "disable" ].each do |action|
          it "should not raise an error when the action is #{action}" do
            allow(::File).to receive(:exist?).with("/usr/local/etc/rc.d/#{new_resource.service_name}").and_return(true)
            provider.action = action
            provider.load_current_resource
            provider.define_resource_requirements
            expect { provider.process_resource_requirements }.not_to raise_error
          end
        end
      end
    end
  end

  describe Chef::Provider::Service::Freebsd, "enable_service" do
    before do
      provider.current_resource = current_resource
      allow(provider).to receive(:service_enable_variable_name).and_return("#{current_resource.service_name}_enable")
    end

    it "should enable the service if it is not enabled" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "#{current_resource.service_name}_enable=\"NO\"", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{current_resource.service_name}_enable=\"YES\""])
      provider.enable_service()
    end

    it "should enable the service if it is not enabled and not already specified in the rc.conf file" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{current_resource.service_name}_enable=\"YES\""])
      provider.enable_service()
    end

    it "should not enable the service if it is already enabled" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).not_to receive(:write_rc_conf)
      provider.enable_service
    end
  end

  describe Chef::Provider::Service::Freebsd, "disable_service" do
    before do
      provider.current_resource = current_resource
      allow(provider).to receive(:service_enable_variable_name).and_return("#{current_resource.service_name}_enable")
    end

    it "should should disable the service if it is not disabled" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "#{current_resource.service_name}_enable=\"YES\"", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{current_resource.service_name}_enable=\"NO\""])
      provider.disable_service()
    end

    it "should not disable the service if it is already disabled" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).not_to receive(:write_rc_conf)
      provider.disable_service()
    end
  end
end
