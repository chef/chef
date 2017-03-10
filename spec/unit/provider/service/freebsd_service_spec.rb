#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright 2009-2016, Bryan McLellan
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

class Chef::Provider::Service::Freebsd
  public :service_enable_variable_name
  public :determine_enabled_status!
  public :determine_current_status!
end

describe Chef::Provider::Service::Freebsd do
  let(:node) do
    node = Chef::Node.new
    node.automatic_attrs[:command] = { :ps => "ps -ax" }
    node
  end

  let(:new_resource) do
    new_resource = Chef::Resource::Service.new("apache22")
    new_resource.pattern("httpd")
    new_resource.supports({ :status => false })
    new_resource
  end

  let(:current_resource) do
    current_resource = Chef::Resource::Service.new("apache22")
    current_resource
  end

  let(:provider) do
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    provider = Chef::Provider::Service::Freebsd.new(new_resource, run_context)
    provider.action = :start
    provider
  end

  before do
    allow(Chef::Resource::Service).to receive(:new).and_return(current_resource)
  end

  def stub_etc_rcd_script
    allow(::File).to receive(:exist?).and_return(false)
    expect(::File).to receive(:exist?).with("/etc/rc.d/#{new_resource.service_name}").and_return(true)
  end

  def stub_usr_local_rcd_script
    allow(::File).to receive(:exist?).and_return(false)
    expect(::File).to receive(:exist?).with("/usr/local/etc/rc.d/#{new_resource.service_name}").and_return(true)
  end

  def run_load_current_resource
    stub_usr_local_rcd_script
    provider.load_current_resource
  end

  describe Chef::Provider::Service::Freebsd, "initialize" do
    it "should default enabled_state_found to false" do
      expect(provider.enabled_state_found).to be false
    end

    it "should find /usr/local/etc/rc.d init scripts" do
      stub_usr_local_rcd_script
      expect(provider.init_command).to eql "/usr/local/etc/rc.d/apache22"
    end

    it "should find /etc/rc.d init scripts" do
      stub_etc_rcd_script
      expect(provider.init_command).to eql "/etc/rc.d/apache22"
    end

    it "should set init_command to nil if it can't find anything" do
      allow(::File).to receive(:exist?).and_return(false)
      expect(provider.init_command).to be nil
    end
  end

  describe Chef::Provider::Service::Freebsd, "determine_current_status!" do
    before do
      stub_usr_local_rcd_script
      provider.current_resource = current_resource
      current_resource.service_name(new_resource.service_name)
    end

    context "when a status command has been specified" do
      let(:status) { double(:stdout => "", :exitstatus => 0) }

      before do
        new_resource.status_command("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        expect(provider).to receive(:shell_out).with("/bin/chefhasmonkeypants status").and_return(status)
        provider.determine_current_status!
      end
    end

    context "when the service supports status" do
      let(:status) { double(:stdout => "", :exitstatus => 0) }

      before do
        new_resource.supports({ :status => true })
      end

      it "should run '/etc/init.d/service_name status'" do
        expect(provider).to receive(:shell_out).with("/usr/local/etc/rc.d/#{new_resource.service_name} status").and_return(status)
        provider.determine_current_status!
      end

      it "should set running to true if the status command returns 0" do
        expect(provider).to receive(:shell_out).with("/usr/local/etc/rc.d/#{new_resource.service_name} status").and_return(status)
        provider.determine_current_status!
        expect(current_resource.running).to be true
      end

      it "should set running to false if the status command returns anything except 0" do
        expect(provider).to receive(:shell_out).with("/usr/local/etc/rc.d/#{new_resource.service_name} status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
        provider.determine_current_status!
        expect(current_resource.running).to be false
      end
    end

    context "when we have a 'ps' attribute" do
      let(:stdout) do
        StringIO.new(<<-PS_SAMPLE)
413  ??  Ss     0:02.51 /usr/sbin/syslogd -s
539  ??  Is     0:00.14 /usr/sbin/sshd
545  ??  Ss     0:17.53 sendmail: accepting connections (sendmail)
PS_SAMPLE
      end
      let(:status) { double(:stdout => stdout, :exitstatus => 0) }

      before do
        node.automatic_attrs[:command] = { :ps => "ps -ax" }
      end

      it "should shell_out! the node's ps command" do
        expect(provider).to receive(:shell_out!).with(node[:command][:ps]).and_return(status)
        provider.determine_current_status!
      end

      it "should read stdout of the ps command" do
        allow(provider).to receive(:shell_out!).and_return(status)
        expect(stdout).to receive(:each_line).and_return(true)
        provider.determine_current_status!
      end

      context "when the regex matches the output" do
        let(:stdout) do
          StringIO.new(<<-PS_SAMPLE)
555  ??  Ss     0:05.16 /usr/sbin/cron -s
 9881  ??  Ss     0:06.67 /usr/local/sbin/httpd -DNOHTTPACCEPT
          PS_SAMPLE
        end

        it "should set running to true" do
          allow(provider).to receive(:shell_out!).and_return(status)
          provider.determine_current_status!
          expect(current_resource.running).to be_truthy
        end
      end

      it "should set running to false if the regex doesn't match" do
        allow(provider).to receive(:shell_out!).and_return(status)
        provider.determine_current_status!
        expect(current_resource.running).to be_falsey
      end

      it "should set running to nil if ps fails" do
        allow(provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        provider.determine_current_status!
        expect(current_resource.running).to be_nil
        expect(provider.status_load_success).to be_nil
      end

      context "when ps is empty string" do
        before do
          node.automatic_attrs[:command] = { :ps => "" }
        end

        it "should set running to nil" do
          provider.determine_current_status!
          expect(current_resource.running).to be_nil
        end
      end
    end
  end

  describe Chef::Provider::Service::Freebsd, "determine_enabled_status!" do
    before do
      stub_usr_local_rcd_script
      provider.current_resource = current_resource
      current_resource.service_name(new_resource.service_name)

      allow(provider).to receive(:service_enable_variable_name).and_return("#{new_resource.service_name}_enable")
    end

    context "when /etc/rc.conf does not exist" do
      before do
        expect(::File).to receive(:exist?).with("/etc/rc.conf").and_return(false)
      end

      it "sets enabled to false" do
        provider.determine_enabled_status!
        expect(current_resource.enabled).to be false
      end
    end

    context "when /etc/rc.conf does exist" do
      before do
        expect(::File).to receive(:exist?).with("/etc/rc.conf").and_return(true)
        expect(provider).to receive(:read_rc_conf).and_return(lines)
      end

      %w{YES Yes yes yEs YeS}.each do |setting|
        context "when the enable variable is set to #{setting}" do
          let(:lines) { [ %Q{#{new_resource.service_name}_enable="#{setting}"} ] }
          it "sets enabled to true" do
            provider.determine_enabled_status!
            expect(current_resource.enabled).to be true
          end
        end
      end

      %w{No NO no nO None NONE none nOnE}.each do |setting|
        context "when the enable variable is set to #{setting}" do
          let(:lines) { [ %Q{#{new_resource.service_name}_enable="#{setting}"} ] }
          it "sets enabled to false" do
            provider.determine_enabled_status!
            expect(current_resource.enabled).to be false
          end
        end
      end

      context "when the enable variable is garbage" do
        let(:lines) { [ %Q{#{new_resource.service_name}_enable="alskdjflasdkjflakdfj"} ] }
        it "sets enabled to false" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable partial matches (left) some other service and we are disabled" do
        let(:lines) do
          [
          %Q{thing_#{new_resource.service_name}_enable="YES"},
          %Q{#{new_resource.service_name}_enable="NO"},
        ] end
        it "sets enabled based on the exact match (false)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable partial matches (right) some other service and we are disabled" do
        let(:lines) do
          [
          %Q{#{new_resource.service_name}_thing_enable="YES"},
          %Q{#{new_resource.service_name}_enable="NO"},
        ] end
        it "sets enabled based on the exact match (false)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable partial matches (left) some other disabled service and we are enabled" do
        let(:lines) do
          [
          %Q{thing_#{new_resource.service_name}_enable="NO"},
          %Q{#{new_resource.service_name}_enable="YES"},
        ] end
        it "sets enabled based on the exact match (true)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be true
        end
      end

      context "when the enable variable partial matches (right) some other disabled service and we are enabled" do
        let(:lines) do
          [
          %Q{#{new_resource.service_name}_thing_enable="NO"},
          %Q{#{new_resource.service_name}_enable="YES"},
        ] end
        it "sets enabled based on the exact match (true)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be true
        end
      end

      context "when the enable variable only partial matches (left) some other enabled service" do
        let(:lines) { [ %Q{thing_#{new_resource.service_name}_enable="YES"} ] }
        it "sets enabled to false" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable only partial matches (right) some other enabled service" do
        let(:lines) { [ %Q{#{new_resource.service_name}_thing_enable="YES"} ] }
        it "sets enabled to false" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when nothing matches" do
        let(:lines) { [] }
        it "sets enabled to true" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end
    end
  end

  describe Chef::Provider::Service::Freebsd, "service_enable_variable_name" do
    before do
      stub_usr_local_rcd_script
      provider.current_resource = current_resource
      current_resource.service_name(new_resource.service_name)

      expect(::File).to receive(:open).with("/usr/local/etc/rc.d/#{new_resource.service_name}").and_yield(rcscript)
    end

    context "when the rc script has a 'name' variable" do
      let(:rcscript) do
        StringIO.new(<<-EOF)
name="#{new_resource.service_name}"
rcvar=`set_rcvar`
EOF
      end

      it "should not raise an exception if the rcscript have a name variable" do
        expect { provider.service_enable_variable_name }.not_to raise_error
      end

      it "should not run rcvar" do
        expect(provider).not_to receive(:shell_out!)
        provider.service_enable_variable_name
      end

      it "should return the enable variable determined from the rcscript name" do
        expect(provider.service_enable_variable_name).to eql "#{new_resource.service_name}_enable"
      end
    end

    describe "when the rcscript does not have a name variable" do
      let(:rcscript) do
        StringIO.new <<-EOF
rcvar=`set_rcvar`
EOF
      end

      before do
        status = double(:stdout => rcvar_stdout, :exitstatus => 0)
        allow(provider).to receive(:shell_out!).with("/usr/local/etc/rc.d/#{new_resource.service_name} rcvar").and_return(status)
      end

      describe "when rcvar returns foobar_enable" do
        let(:rcvar_stdout) do
          rcvar_stdout = <<-EOF
# apache22
#
# #{new_resource.service_name}_enable="YES"
#   (default: "")
EOF
        end

        it "should get the service name from rcvar if the rcscript does not have a name variable" do
          expect(provider.service_enable_variable_name).to eq("#{new_resource.service_name}_enable")
        end

        it "should not raise an exception if the rcscript does not have a name variable" do
          expect { provider.service_enable_variable_name }.not_to raise_error
        end
      end

      describe "when rcvar does not return foobar_enable" do
        let(:rcvar_stdout) do
          rcvar_stdout = <<-EOF
# service_with_noname
#
EOF
        end

        it "should return nil" do
          expect(provider.service_enable_variable_name).to be nil
        end
      end
    end
  end

  describe Chef::Provider::Service::Freebsd, "load_current_resource" do
    before(:each) do
      stub_usr_local_rcd_script
      expect(provider).to receive(:determine_current_status!)
      current_resource.running(false)
      allow(provider).to receive(:service_enable_variable_name).and_return "#{new_resource.service_name}_enable"
    end

    it "should create a current resource with the name of the new resource" do
      expect(Chef::Resource::Service).to receive(:new).and_return(current_resource)
      provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      provider.load_current_resource
      expect(current_resource.service_name).to eq(new_resource.service_name)
    end

    it "should return the current resource" do
      expect(provider.load_current_resource).to eql(current_resource)
    end

  end

  context "when testing actions" do
    before(:each) do
      stub_usr_local_rcd_script
      expect(provider).to receive(:determine_current_status!)
      current_resource.running(false)
      expect(provider).to receive(:determine_enabled_status!)
      current_resource.enabled(false)
      provider.load_current_resource
    end

    describe Chef::Provider::Service::Freebsd, "start_service" do
      it "should call the start command if one is specified" do
        new_resource.start_command("/etc/rc.d/chef startyousillysally")
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/rc.d/chef startyousillysally")
        provider.start_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststart' if no start command is specified" do
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/usr/local/etc/rc.d/#{new_resource.service_name} faststart")
        provider.start_service()
      end
    end

    describe Chef::Provider::Service::Freebsd, "stop_service" do
      it "should call the stop command if one is specified" do
        new_resource.stop_command("/etc/init.d/chef itoldyoutostop")
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef itoldyoutostop")
        provider.stop_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststop' if no stop command is specified" do
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/usr/local/etc/rc.d/#{new_resource.service_name} faststop")
        provider.stop_service()
      end
    end

    describe Chef::Provider::Service::Freebsd, "restart_service" do
      it "should call 'restart' on the service_name if the resource supports it" do
        new_resource.supports({ :restart => true })
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/usr/local/etc/rc.d/#{new_resource.service_name} fastrestart")
        provider.restart_service()
      end

      it "should call the restart_command if one has been specified" do
        new_resource.restart_command("/etc/init.d/chef restartinafire")
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef restartinafire")
        provider.restart_service()
      end

      it "otherwise it should call stop and start" do
        expect(provider).to receive(:stop_service)
        expect(provider).to receive(:start_service)
        provider.restart_service()
      end
    end
  end

  describe Chef::Provider::Service::Freebsd, "define_resource_requirements" do
    before do
      provider.current_resource = current_resource
    end

    context "when the init script is not found" do
      before do
        provider.init_command = nil
        allow(provider).to receive(:service_enable_variable_name).and_return("#{new_resource.service_name}_enable")
      end

      %w{start reload restart enable}.each do |action|
        it "should raise an exception when the action is #{action}" do
          provider.define_resource_requirements
          provider.action = action
          expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
        end
      end

      %w{stop disable}.each do |action|
        it "should not raise an error when the action is #{action}" do
          provider.define_resource_requirements
          provider.action = action
          expect { provider.process_resource_requirements }.not_to raise_error
        end
      end
    end

    context "when the init script is found, but the service_enable_variable_name is nil" do
      before do
        provider.init_command = nil
        allow(provider).to receive(:service_enable_variable_name).and_return(nil)
      end

      %w{start reload restart enable}.each do |action|
        it "should raise an exception when the action is #{action}" do
          provider.action = action
          provider.define_resource_requirements
          expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
        end
      end

      %w{stop disable}.each do |action|
        it "should not raise an error when the action is #{action}" do
          provider.action = action
          provider.define_resource_requirements
          expect { provider.process_resource_requirements }.not_to raise_error
        end
      end
    end
  end

  describe Chef::Provider::Service::Freebsd, "enable_service" do
    before do
      provider.current_resource = current_resource
      allow(provider).to receive(:service_enable_variable_name).and_return("#{new_resource.service_name}_enable")
    end

    it "should enable the service if it is not enabled" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "#{new_resource.service_name}_enable=\"NO\"", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{new_resource.service_name}_enable=\"YES\""])
      provider.enable_service()
    end

    it "should not partial match an already enabled service" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "thing_#{new_resource.service_name}_enable=\"NO\"", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "thing_#{new_resource.service_name}_enable=\"NO\"", "bar", "#{new_resource.service_name}_enable=\"YES\""])
      provider.enable_service()
    end

    it "should enable the service if it is not enabled and not already specified in the rc.conf file" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).to receive(:read_rc_conf).and_return(%w{foo bar})
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{new_resource.service_name}_enable=\"YES\""])
      provider.enable_service()
    end

    it "should not enable the service if it is already enabled" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).not_to receive(:write_rc_conf)
      provider.enable_service
    end

    it "should remove commented out versions of it being enabled" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "bar", "\# #{new_resource.service_name}_enable=\"YES\"", "\# #{new_resource.service_name}_enable=\"NO\""])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{new_resource.service_name}_enable=\"YES\""])
      provider.enable_service()
    end
  end

  describe Chef::Provider::Service::Freebsd, "disable_service" do
    before do
      provider.current_resource = current_resource
      allow(provider).to receive(:service_enable_variable_name).and_return("#{new_resource.service_name}_enable")
    end

    it "should disable the service if it is not disabled" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "#{new_resource.service_name}_enable=\"YES\"", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{new_resource.service_name}_enable=\"NO\""])
      provider.disable_service()
    end

    it "should not disable an enabled service that partially matches" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "thing_#{new_resource.service_name}_enable=\"YES\"", "bar" ])
      expect(provider).to receive(:write_rc_conf).with(["foo", "thing_#{new_resource.service_name}_enable=\"YES\"", "bar", "#{new_resource.service_name}_enable=\"NO\""])
      provider.disable_service()
    end

    it "should not disable the service if it is already disabled" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).not_to receive(:write_rc_conf)
      provider.disable_service()
    end

    it "should remove commented out versions of it being disabled or enabled" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:read_rc_conf).and_return([ "foo", "bar", "\# #{new_resource.service_name}_enable=\"YES\"", "\# #{new_resource.service_name}_enable=\"NO\""])
      expect(provider).to receive(:write_rc_conf).with(["foo", "bar", "#{new_resource.service_name}_enable=\"NO\""])
      provider.disable_service()
    end
  end
end
