#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Author:: Davide Cavalca (<dcavalca@fb.com>)
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

describe Chef::Provider::Service::Systemd do

  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:service_name) { "rsyslog\\x2d.service" }

  let(:service_name_escaped) { "rsyslog\\\\x2d.service" }

  let(:new_resource) { Chef::Resource::Service.new(service_name) }

  let(:provider) { Chef::Provider::Service::Systemd.new(new_resource, run_context) }

  let(:shell_out_success) do
    double("shell_out", exitstatus: 0, error?: false, stdout: "")
  end

  let(:shell_out_failure) do
    double("shell_out", exitstatus: 1, error?: true, stdout: "")
  end

  let(:current_resource) { Chef::Resource::Service.new(service_name) }

  before(:each) do
    allow(Chef::Resource::Service).to receive(:new).with(service_name).and_return(current_resource)
    allow(Etc).to receive(:getpwnam).and_return(OpenStruct.new(uid: 10000))
  end

  describe "load_current_resource" do

    before(:each) do
      allow(provider).to receive(:is_active?).and_return(false)
      allow(provider).to receive(:is_enabled?).and_return(false)
      allow(provider).to receive(:is_masked?).and_return(false)
      allow(provider).to receive(:is_indirect?).and_return(false)
    end

    it "should create a current resource with the name of the new resource" do
      expect(Chef::Resource::Service).to receive(:new).with(new_resource.name).and_return(current_resource)
      provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      provider.load_current_resource
      expect(current_resource.service_name).to eql(service_name)
    end

    it "should check if the service is running" do
      expect(provider).to receive(:is_active?)
      provider.load_current_resource
    end

    it "should set running to true if the service is running" do
      allow(provider).to receive(:is_active?).and_return(true)
      provider.load_current_resource
      expect(current_resource.running).to be true
    end

    it "should set running to false if the service is not running" do
      allow(provider).to receive(:is_active?).and_return(false)
      provider.load_current_resource
      expect(current_resource.running).to be false
    end

    describe "when a status command has been specified" do
      before do
        allow(new_resource).to receive(:status_command).and_return("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        allow(provider).to receive(:shell_out).and_return(shell_out_success)
        provider.load_current_resource
        expect(current_resource.running).to be true
      end

      it "should run the services status command if one has been specified and properly set status check state" do
        allow(provider).to receive(:shell_out).with("/bin/chefhasmonkeypants status").and_return(shell_out_success)
        provider.load_current_resource
        expect(provider.status_check_success).to be true
      end

      it "should set running to false if a status command fails" do
        allow(provider).to receive(:shell_out).and_return(shell_out_failure)
        provider.load_current_resource
        expect(current_resource.running).to be false
      end

      it "should update state to indicate status check failed when a status command fails" do
        allow(provider).to receive(:shell_out).and_return(shell_out_failure)
        provider.load_current_resource
        expect(provider.status_check_success).to be false
      end
    end

    it "should check if the service is enabled" do
      expect(provider).to receive(:is_enabled?)
      provider.load_current_resource
    end

    it "should set enabled to true if the service is enabled" do
      allow(provider).to receive(:is_enabled?).and_return(true)
      provider.load_current_resource
      expect(current_resource.enabled).to be true
    end

    it "should set enabled to false if the service is not enabled" do
      allow(provider).to receive(:is_enabled?).and_return(false)
      provider.load_current_resource
      expect(current_resource.enabled).to be false
    end

    it "should check if the service is masked" do
      expect(provider).to receive(:is_masked?)
      provider.load_current_resource
    end

    it "should set masked to true if the service is masked" do
      allow(provider).to receive(:is_masked?).and_return(true)
      provider.load_current_resource
      expect(current_resource.masked).to be true
    end

    it "should set masked to false if the service is not masked" do
      allow(provider).to receive(:is_masked?).and_return(false)
      provider.load_current_resource
      expect(current_resource.masked).to be false
    end

    it "should return the current resource" do
      expect(provider.load_current_resource).to eql(current_resource)
    end
  end

  def setup_current_resource
    provider.current_resource = current_resource
    current_resource.service_name(service_name)
  end

  %w{/usr/bin/systemctl /bin/systemctl}.each do |systemctl_path|
    describe "when systemctl path is #{systemctl_path}" do
      before(:each) do
        setup_current_resource
        allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path)
      end

      describe "start and stop service" do

        it "should call the start command if one is specified" do
          allow(new_resource).to receive(:start_command).and_return("/sbin/rsyslog startyousillysally")
          expect(provider).to receive(:shell_out!).with("/sbin/rsyslog startyousillysally", default_env: false)
          provider.start_service
        end

        context "when a user is not specified" do
          it "should call '#{systemctl_path} --system start service_name' if no start command is specified" do
            expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "start", service_name, default_env: false, timeout: 900).and_return(shell_out_success)
            provider.start_service
          end

          it "should not call '#{systemctl_path} --system start service_name' if it is already running" do
            current_resource.running(true)
            expect(provider).not_to receive(:shell_out_compacted!).with(systemctl_path, "--system", "start", service_name, timeout: 900)
            provider.start_service
          end
        end

        context "when a user is specified" do
          it "should call '#{systemctl_path} --user start service_name' if no start command is specified" do
            current_resource.user("joe")
            expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--user", "start", service_name, environment: { "DBUS_SESSION_BUS_ADDRESS" => "unix:path=/run/user/10000/bus" }, user: "joe", default_env: false, timeout: 900).and_return(shell_out_success)
            provider.start_service
          end

          it "should not call '#{systemctl_path} --user start service_name' if it is already running" do
            current_resource.running(true)
            current_resource.user("joe")
            expect(provider).not_to receive(:shell_out_compacted!).with(systemctl_path, "--user", "start", service_name, environment: { "DBUS_SESSION_BUS_ADDRESS" => "unix:path=/run/user/10000/bus" }, user: "joe", timeout: 900)
            provider.start_service
          end
        end

        it "should call the restart command if one is specified" do
          current_resource.running(true)
          allow(new_resource).to receive(:restart_command).and_return("/sbin/rsyslog restartyousillysally")
          expect(provider).to receive(:shell_out!).with("/sbin/rsyslog restartyousillysally", default_env: false)
          provider.restart_service
        end

        it "should call '#{systemctl_path} --system restart service_name' if no restart command is specified" do
          current_resource.running(true)
          expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "restart", service_name, default_env: false, timeout: 900).and_return(shell_out_success)
          provider.restart_service
        end

        describe "reload service" do
          context "when a reload command is specified" do
            it "should call the reload command" do
              current_resource.running(true)
              allow(new_resource).to receive(:reload_command).and_return("/sbin/rsyslog reloadyousillysally")
              expect(provider).to receive(:shell_out!).with("/sbin/rsyslog reloadyousillysally", default_env: false)
              provider.reload_service
            end
          end

          context "when a reload command is not specified" do
            it "should call '#{systemctl_path} --system reload service_name' if the service is running" do
              current_resource.running(true)
              expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "reload", service_name, default_env: false, timeout: 900).and_return(shell_out_success)
              provider.reload_service
            end

            it "should start the service if the service is not running" do
              current_resource.running(false)
              expect(provider).to receive(:start_service).and_return(true)
              provider.reload_service
            end
          end
        end

        it "should call the stop command if one is specified" do
          current_resource.running(true)
          allow(new_resource).to receive(:stop_command).and_return("/sbin/rsyslog stopyousillysally")
          expect(provider).to receive(:shell_out!).with("/sbin/rsyslog stopyousillysally", default_env: false)
          provider.stop_service
        end

        it "should call '#{systemctl_path} --system stop service_name' if no stop command is specified" do
          current_resource.running(true)
          expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "stop", service_name, timeout: 900, default_env: false).and_return(shell_out_success)
          provider.stop_service
        end

        it "should not call '#{systemctl_path} --system stop service_name' if it is already stopped" do
          current_resource.running(false)
          expect(provider).not_to receive(:shell_out_compacted!).with(systemctl_path, "--system", "stop", service_name, timeout: 900)
          provider.stop_service
        end
      end

      describe "enable and disable service" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        it "should call '#{systemctl_path} --system enable service_name' to enable the service" do
          expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "enable", service_name, timeout: 900).and_return(shell_out_success)
          provider.enable_service
        end

        it "should call '#{systemctl_path} --system disable service_name' to disable the service" do
          expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "disable", service_name, timeout: 900).and_return(shell_out_success)
          provider.disable_service
        end
      end

      describe "mask and unmask service" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        it "should call '#{systemctl_path} --system mask service_name' to mask the service" do
          expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "mask", service_name, timeout: 900).and_return(shell_out_success)
          provider.mask_service
        end

        it "should call '#{systemctl_path} --system unmask service_name' to unmask the service" do
          expect(provider).to receive(:shell_out_compacted!).with(systemctl_path, "--system", "unmask", service_name, timeout: 900).and_return(shell_out_success)
          provider.unmask_service
        end
      end

      enabled_and_active = <<-STDOUT
        ActiveState=active
        UnitFileState=enabled
      STDOUT
      disabled_and_inactive = <<-STDOUT
        ActiveState=disabled
        UnitFileState=inactive
      STDOUT
      # No unit known for this service, and inactive
      nil_and_inactive = <<-STDOUT
        ActiveState=inactive
        UnitFileState=
      STDOUT

      def with_systemctl_show(systemctl_path, stdout)
        systemctl_show = [systemctl_path, "--system", "show", "-p", "UnitFileState", "-p", "ActiveState", service_name]
        expect(provider).to receive(:shell_out!).with(*systemctl_show).and_return(double(stdout: stdout, exitstatus: 0, error?: false))
      end

      describe "systemd_service_status" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
        end

        it "should return status if '#{systemctl_path} --system show -p UnitFileState -p ActiveState service_name' returns 0 and has nil" do
          nil_and_inactive_h = {
            "ActiveState" => "inactive",
            "UnitFileState" => nil,
          }
          with_systemctl_show(systemctl_path, nil_and_inactive)
          expect(provider.systemd_service_status).to eql(nil_and_inactive_h)
        end

        it "should error if '#{systemctl_path} --system show -p UnitFileState -p ActiveState service_name' misses fields" do
          partial_systemctl_stdout = <<-STDOUT
            ActiveState=inactive
          STDOUT
          with_systemctl_show(systemctl_path, partial_systemctl_stdout)
          expect { provider.systemd_service_status }.to raise_error(Chef::Exceptions::Service)
        end

        it "should error if '#{systemctl_path} --system show -p UnitFileState -p ActiveState service_name' returns non 0" do
          systemctl_show = [systemctl_path, "--system", "show", "-p", "UnitFileState", "-p", "ActiveState", service_name]
          allow(provider).to receive(:shell_out!).with(*systemctl_show).and_return(shell_out_failure)
          expect { provider.systemd_service_status }.to raise_error(Chef::Exceptions::Service)
        end
      end

      describe "is_active?" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        it "should return true if service is active" do
          with_systemctl_show(systemctl_path, enabled_and_active)
          expect(provider.is_active?).to be true
        end

        it "should return false if service is not active" do
          with_systemctl_show(systemctl_path, disabled_and_inactive)
          expect(provider.is_active?).to be false
        end

        it "should return false if service is activating" do
          enabled_and_activating = <<-STDOUT
            ActiveState=activating
            UnitFileState=enabled
          STDOUT
          with_systemctl_show(systemctl_path, enabled_and_activating)
          expect(provider.is_active?).to be false
        end
      end

      describe "is_enabled?" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        it "should return true if service is enabled" do
          with_systemctl_show(systemctl_path, enabled_and_active)
          expect(provider.is_enabled?).to be true
        end

        it "should return false if service is disabled" do
          with_systemctl_show(systemctl_path, disabled_and_inactive)
          expect(provider.is_enabled?).to be false
        end

        it "should return false if service has no unit file" do
          with_systemctl_show(systemctl_path, nil_and_inactive)
          expect(provider.is_enabled?).to be false
        end

        it "should return true if service is static" do
          static_and_active = <<-STDOUT
            ActiveState=active
            UnitFileState=static
          STDOUT
          with_systemctl_show(systemctl_path, static_and_active)
          expect(provider.is_enabled?).to be true
        end

        it "should return false if service is enabled-runtime" do
          enabled_runtime_and_active = <<-STDOUT
            ActiveState=active
            UnitFileState=enabled-runtime
          STDOUT
          with_systemctl_show(systemctl_path, enabled_runtime_and_active)
          expect(provider.is_enabled?).to be false
        end

        it "should shellout to 'is-enabled' and return false if unit file is bad and sysv compat isn't enabled" do
          bad_and_inactive = <<-STDOUT
            ActiveState=inactive
            UnitFileState=bad
          STDOUT
          with_systemctl_show(systemctl_path, bad_and_inactive)
          systemctl_isenabled = [systemctl_path, "--system", "is-enabled", service_name, "--quiet"]
          expect(provider).to receive(:shell_out).with(*systemctl_isenabled).and_return(shell_out_failure)
          expect(provider.is_enabled?).to be false
        end

        it "should shellout to 'is-enabled' and return true if unit file is bad and sysv compat is enabled" do
          bad_and_inactive = <<-STDOUT
            ActiveState=inactive
            UnitFileState=bad
          STDOUT
          with_systemctl_show(systemctl_path, bad_and_inactive)
          systemctl_isenabled = [systemctl_path, "--system", "is-enabled", service_name, "--quiet"]
          expect(provider).to receive(:shell_out).with(*systemctl_isenabled).and_return(shell_out_success)
          expect(provider.is_enabled?).to be true
        end
      end

      describe "is_masked?" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        it "should return true if service is masked" do
          masked_and_inactive = <<-STDOUT
            ActiveState=inactive
            UnitFileState=masked
          STDOUT
          with_systemctl_show(systemctl_path, masked_and_inactive)
          expect(provider.is_masked?).to be true
        end

        it "should return false if service is masked-runtime" do
          masked_runtime_and_inactive = <<-STDOUT
            ActiveState=inactive
            UnitFileState=masked-runtime
          STDOUT
          with_systemctl_show(systemctl_path, masked_runtime_and_inactive)
          expect(provider.is_masked?).to be false
        end

        it "should return false if service is enabled" do
          with_systemctl_show(systemctl_path, enabled_and_active)
          expect(provider.is_masked?).to be false
        end

        it "should return false if service has no known unit file" do
          with_systemctl_show(systemctl_path, nil_and_inactive)
          expect(provider.is_masked?).to be false
        end
      end

      describe "is_indirect?" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.service_name(service_name)
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        it "should return true if service is indirect" do
          indirect_and_inactive = <<-STDOUT
            ActiveState=inactive
            UnitFileState=indirect
          STDOUT
          with_systemctl_show(systemctl_path, indirect_and_inactive)
          expect(provider.is_indirect?).to be true
        end

        it "should return false if service not indirect" do
          with_systemctl_show(systemctl_path, enabled_and_active)
          expect(provider.is_indirect?).to be false
        end

        it "should return false if service has no known unit file" do
          with_systemctl_show(systemctl_path, nil_and_inactive)
          expect(provider.is_indirect?).to be false
        end
      end
    end
  end
end
