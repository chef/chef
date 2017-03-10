#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Scott Bonds (scott@ggr.com)
# Copyright:: Copyright 2009-2016, Bryan McLellan
# Copyright:: Copyright 2014-2016, Scott Bonds
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

class Chef::Provider::Service::Openbsd
  public :builtin_service_enable_variable_name
  public :determine_enabled_status!
  public :determine_current_status!
  public :is_enabled?
  attr_accessor :rc_conf, :rc_conf_local
end

describe Chef::Provider::Service::Openbsd do
  let(:node) do
    node = Chef::Node.new
    node.automatic_attrs[:command] = { :ps => "ps -ax" }
    node
  end

  let(:supports) { { :status => false } }

  let(:new_resource) do
    new_resource = Chef::Resource::Service.new("sndiod")
    new_resource.pattern("sndiod")
    new_resource.supports(supports)
    new_resource
  end

  let(:current_resource) do
    current_resource = Chef::Resource::Service.new("sndiod")
    current_resource
  end

  let(:provider) do
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    allow(::File).to receive(:read).with("/etc/rc.conf").and_return("")
    allow(::File).to receive(:read).with("/etc/rc.conf.local").and_return("")
    provider = Chef::Provider::Service::Openbsd.new(new_resource, run_context)
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

  def run_load_current_resource
    stub_etc_rcd_script
    provider.load_current_resource
  end

  describe Chef::Provider::Service::Openbsd, "initialize" do
    it "should find /etc/rc.d init scripts" do
      stub_etc_rcd_script
      expect(provider.init_command).to eql "/etc/rc.d/sndiod"
    end

    it "should set init_command to nil if it can't find anything" do
      expect(::File).to receive(:exist?).with("/etc/rc.d/sndiod").and_return(false)
      expect(provider.init_command).to be nil
    end
  end

  describe Chef::Provider::Service::Openbsd, "determine_current_status!" do
    before do
      stub_etc_rcd_script
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

      let(:supports) { { :status => true } }

      it "should run '/etc/rc.d/service_name status'" do
        expect(provider).to receive(:shell_out).with("/etc/rc.d/#{new_resource.service_name} check").and_return(status)
        provider.determine_current_status!
      end

      it "should set running to true if the status command returns 0" do
        expect(provider).to receive(:shell_out).with("/etc/rc.d/#{new_resource.service_name} check").and_return(status)
        provider.determine_current_status!
        expect(current_resource.running).to be true
      end

      it "should set running to false if the status command returns anything except 0" do
        expect(provider).to receive(:shell_out).with("/etc/rc.d/#{new_resource.service_name} check").and_raise(Mixlib::ShellOut::ShellCommandFailed)
        provider.determine_current_status!
        expect(current_resource.running).to be false
      end
    end
  end

  describe Chef::Provider::Service::Openbsd, "determine_enabled_status!" do
    before do
      stub_etc_rcd_script
      provider.current_resource = current_resource
      current_resource.service_name(new_resource.service_name)

      allow(provider).to receive(:service_enable_variable_name).and_return("#{new_resource.service_name}_enable")
    end

    context "when the service is builtin" do
      before do
        expect(::File).to receive(:open).with("/etc/rc.d/#{new_resource.service_name}")
        provider.rc_conf = "#{provider.builtin_service_enable_variable_name}=NO"
        provider.rc_conf_local = lines.join("\n")
      end

      %w{YES Yes yes yEs YeS}.each do |setting|
        context "when the enable variable is set to #{setting}" do
          let(:lines) { [ %Q{#{provider.builtin_service_enable_variable_name}="#{setting}"} ] }
          it "sets enabled to true" do
            provider.determine_enabled_status!
            expect(current_resource.enabled).to be true
          end
        end
      end

      %w{No NO no nO None NONE none nOnE}.each do |setting|
        context "when the enable variable is set to #{setting}" do
          let(:lines) { [ %Q{#{provider.builtin_service_enable_variable_name}="#{setting}"} ] }
          it "sets enabled to false" do
            provider.determine_enabled_status!
            expect(current_resource.enabled).to be false
          end
        end
      end

      context "when the enable variable is garbage" do
        let(:lines) { [ %Q{#{provider.builtin_service_enable_variable_name}_enable="alskdjflasdkjflakdfj"} ] }
        it "sets enabled to false" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable partial matches (left) some other service and we are disabled" do
        let(:lines) do
          [
          %Q{thing_#{provider.builtin_service_enable_variable_name}="YES"},
          %Q{#{provider.builtin_service_enable_variable_name}="NO"},
        ] end
        it "sets enabled based on the exact match (false)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable partial matches (right) some other service and we are disabled" do
        let(:lines) do
          [
          %Q{#{provider.builtin_service_enable_variable_name}_thing="YES"},
          %Q{#{provider.builtin_service_enable_variable_name}},
        ] end
        it "sets enabled based on the exact match (false)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable partial matches (left) some other disabled service and we are enabled" do
        let(:lines) do
          [
          %Q{thing_#{provider.builtin_service_enable_variable_name}="NO"},
          %Q{#{provider.builtin_service_enable_variable_name}="YES"},
        ] end
        it "sets enabled based on the exact match (true)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be true
        end
      end

      context "when the enable variable partial matches (right) some other disabled service and we are enabled" do
        let(:lines) do
          [
          %Q{#{provider.builtin_service_enable_variable_name}_thing="NO"},
          %Q{#{provider.builtin_service_enable_variable_name}="YES"},
        ] end
        it "sets enabled based on the exact match (true)" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be true
        end
      end

      context "when the enable variable only partial matches (left) some other enabled service" do
        let(:lines) { [ %Q{thing_#{provider.builtin_service_enable_variable_name}_enable="YES"} ] }
        it "sets enabled to false" do
          provider.determine_enabled_status!
          expect(current_resource.enabled).to be false
        end
      end

      context "when the enable variable only partial matches (right) some other enabled service" do
        let(:lines) { [ %Q{#{provider.builtin_service_enable_variable_name}_thing_enable="YES"} ] }
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

  describe Chef::Provider::Service::Openbsd, "load_current_resource" do
    before(:each) do
      stub_etc_rcd_script
      expect(provider).to receive(:determine_current_status!)
      current_resource.running(false)
      allow(provider).to receive(:service_enable_variable_name).and_return "#{new_resource.service_name}_enable"
      expect(::File).to receive(:open).with("/etc/rc.d/#{new_resource.service_name}")
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
      stub_etc_rcd_script
      expect(provider).to receive(:determine_current_status!)
      current_resource.running(false)
      expect(provider).to receive(:determine_enabled_status!)
      current_resource.enabled(false)
      provider.load_current_resource
    end

    describe Chef::Provider::Service::Openbsd, "start_service" do
      it "should call the start command if one is specified" do
        new_resource.start_command("/etc/rc.d/chef startyousillysally")
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/rc.d/chef startyousillysally")
        provider.start_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name start' if no start command is specified" do
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/rc.d/#{new_resource.service_name} start")
        provider.start_service()
      end
    end

    describe Chef::Provider::Service::Openbsd, "stop_service" do
      it "should call the stop command if one is specified" do
        new_resource.stop_command("/etc/init.d/chef itoldyoutostop")
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/init.d/chef itoldyoutostop")
        provider.stop_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name stop' if no stop command is specified" do
        expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/rc.d/#{new_resource.service_name} stop")
        provider.stop_service()
      end
    end

    describe Chef::Provider::Service::Openbsd, "restart_service" do
      context "when the new_resource supports restart" do
        let(:supports) { { restart: true } }
        it "should call 'restart' on the service_name if the resource supports it" do
          expect(provider).to receive(:shell_out_with_systems_locale!).with("/etc/rc.d/#{new_resource.service_name} restart")
          provider.restart_service()
        end
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

  describe Chef::Provider::Service::Openbsd, "define_resource_requirements" do
    before do
      provider.current_resource = current_resource
    end

    context "when the init script is not found" do
      before do
        provider.init_command = nil
        allow(provider).to receive(:builtin_service_enable_variable_name).and_return("#{new_resource.service_name}_enable")
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
        allow(provider).to receive(:builtin_service_enable_variable_name).and_return(nil)
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

  describe Chef::Provider::Service::Openbsd, "enable_service" do
    before do
      provider.current_resource = current_resource
      allow(FileUtils).to receive(:touch).with("/etc/rc.conf.local")
    end
    context "is builtin and disabled by default" do
      before do
        provider.rc_conf = "#{provider.builtin_service_enable_variable_name}=NO"
      end
      context "is enabled" do
        before do
          provider.rc_conf_local = "#{provider.builtin_service_enable_variable_name}=\"\""
        end
        it "should not change rc.conf.local since it is already enabled" do
          expect(::File).not_to receive(:write)
          provider.enable_service
        end
      end
      context "is disabled" do
        before do
          provider.rc_conf_local = ""
        end
        it "should enable the service by adding a line to rc.conf.local" do
          expect(::File).to receive(:write).with("/etc/rc.conf.local", include("#{provider.builtin_service_enable_variable_name}=\"\""))
          expect(provider.is_enabled?).to be false
          provider.enable_service
          expect(provider.is_enabled?).to be true
        end
      end
    end
    context "is builtin and enabled by default" do
      before do
        provider.rc_conf = "#{provider.builtin_service_enable_variable_name}=\"\""
      end
      context "is enabled" do
        before do
          provider.rc_conf_local = ""
        end
        it "should not change rc.conf.local since it is already enabled" do
          expect(::File).not_to receive(:write)
          provider.enable_service
        end
      end
      context "is disabled" do
        before do
          provider.rc_conf_local = "#{provider.builtin_service_enable_variable_name}=NO"
        end
        it "should enable the service by removing a line from rc.conf.local" do
          expect(::File).to receive(:write).with("/etc/rc.conf.local", /^(?!#{provider.builtin_service_enable_variable_name})$/)
          expect(provider.is_enabled?).to be false
          provider.enable_service
          expect(provider.is_enabled?).to be true
        end
      end
    end
    context "is not builtin" do
      before do
        provider.rc_conf = ""
      end
      context "is enabled" do
        before do
          provider.rc_conf_local = "pkg_scripts=\"#{new_resource.service_name}\"\n"
        end
        it "should not change rc.conf.local since it is already enabled" do
          expect(::File).not_to receive(:write)
          provider.enable_service
        end
      end
      context "is disabled" do
        before do
          provider.rc_conf_local = ""
        end
        it "should enable the service by adding it to the pkg_scripts list" do
          expect(::File).to receive(:write).with("/etc/rc.conf.local", "\npkg_scripts=\"#{new_resource.service_name}\"\n")
          expect(provider.is_enabled?).to be false
          provider.enable_service
          expect(provider.is_enabled?).to be true
        end
      end
    end
  end

  describe Chef::Provider::Service::Openbsd, "disable_service" do
    before do
      provider.current_resource = current_resource
      allow(FileUtils).to receive(:touch).with("/etc/rc.conf.local")
    end
    context "is builtin and disabled by default" do
      before do
        provider.rc_conf = "#{provider.builtin_service_enable_variable_name}=NO"
      end
      context "is enabled" do
        before do
          provider.rc_conf_local = "#{provider.builtin_service_enable_variable_name}=\"\""
        end
        it "should disable the service by removing its line from rc.conf.local" do
          expect(::File).to receive(:write).with("/etc/rc.conf.local", /^(?!#{provider.builtin_service_enable_variable_name})$/)
          expect(provider.is_enabled?).to be true
          provider.disable_service
          expect(provider.is_enabled?).to be false
        end
      end
      context "is disabled" do
        before do
          provider.rc_conf_local = ""
        end
        it "should not change rc.conf.local since it is already disabled" do
          expect(::File).not_to receive(:write)
          provider.disable_service
        end
      end
    end
    context "is builtin and enabled by default" do
      before do
        provider.rc_conf = "#{provider.builtin_service_enable_variable_name}=\"\""
      end
      context "is enabled" do
        before do
          provider.rc_conf_local = ""
        end
        it "should disable the service by adding a line to rc.conf.local" do
          expect(::File).to receive(:write).with("/etc/rc.conf.local", include("#{provider.builtin_service_enable_variable_name}=\"NO\""))
          expect(provider.is_enabled?).to be true
          provider.disable_service
          expect(provider.is_enabled?).to be false
        end
      end
      context "is disabled" do
        before do
          provider.rc_conf_local = "#{provider.builtin_service_enable_variable_name}=NO"
        end
        it "should not change rc.conf.local since it is already disabled" do
          expect(::File).not_to receive(:write)
          provider.disable_service
        end
      end
    end
    context "is not builtin" do
      before do
        provider.rc_conf = ""
      end
      context "is enabled" do
        before do
          provider.rc_conf_local = "pkg_scripts=\"#{new_resource.service_name}\"\n"
        end
        it "should disable the service by removing it from the pkg_scripts list" do
          expect(::File).to receive(:write).with("/etc/rc.conf.local", /^(?!#{new_resource.service_name})$/)
          expect(provider.is_enabled?).to be true
          provider.disable_service
          expect(provider.is_enabled?).to be false
        end
      end
      context "is disabled" do
        before do
          provider.rc_conf_local = ""
        end
        it "should not change rc.conf.local since it is already disabled" do
          expect(::File).not_to receive(:write)
          provider.disable_service
        end
      end
    end
  end

end
