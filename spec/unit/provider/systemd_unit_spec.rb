#
# Author:: Nathan Williams (<nath.e.will@gmail.com>)
# Copyright:: Copyright 2016-2018, Nathan Williams
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

describe Chef::Provider::SystemdUnit, :linux_only do

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:unit_name) { "sysstat-collect\\x2d.timer" }
  let(:user_name) { "joe" }
  let(:current_resource) { Chef::Resource::SystemdUnit.new(unit_name) }
  let(:new_resource) { Chef::Resource::SystemdUnit.new(unit_name) }
  let(:provider) { Chef::Provider::SystemdUnit.new(new_resource, run_context) }
  let(:unit_path_system) { "/etc/systemd/system/sysstat-collect\\x2d.timer" }
  let(:unit_path_user) { "/etc/systemd/user/sysstat-collect\\x2d.timer" }
  let(:unit_content_string) { "[Unit]\nDescription = Run system activity accounting tool every 10 minutes\n\n[Timer]\nOnCalendar = *:00/10\n\n[Install]\nWantedBy = sysstat.service\n" }
  let(:malformed_content_string) { "derp" }

  let(:unit_content_hash) do
    {
      "Unit" => {
        "Description" => "Run system activity accounting tool every 10 minutes",
      },
      "Timer" => {
        "OnCalendar" => "*:00/10",
      },
      "Install" => {
        "WantedBy" => "sysstat.service",
      },
    }
  end

  let(:user_cmd_opts) do
    {
      user: "joe",
      environment: {
        "DBUS_SESSION_BUS_ADDRESS" => "unix:path=/run/user/1000/bus",
      },
    }
  end

  let(:shell_out_success) do
    double("shell_out", exitstatus: 0, error?: false)
  end

  let(:shell_out_failure) do
    double("shell_out", exitstatus: 1, error?: true)
  end

  let(:shell_out_masked) do
    double("shell_out", exitstatus: 0, error?: false, stdout: "masked")
  end

  let(:shell_out_static) do
    double("shell_out", exitstatus: 0, error?: false, stdout: "static")
  end

  let(:shell_out_disabled) do
    double("shell_out", exitstatus: 1, error?: true, stdout: "disabled")
  end

  let(:shell_out_indirect) do
    double("shell_out", exitstatus: 0, error?: true, stdout: "indirect")
  end

  before(:each) do
    allow(Etc).to receive(:getpwnam).and_return(OpenStruct.new(uid: 1000))
    allow(Chef::Resource::SystemdUnit).to receive(:new)
      .with(unit_name)
      .and_return(current_resource)
  end

  describe "define_resource_requirements" do
    before(:each) do
      provider.action = :create
      allow(provider).to receive(:active?).and_return(false)
      allow(provider).to receive(:enabled?).and_return(false)
      allow(provider).to receive(:masked?).and_return(false)
      allow(provider).to receive(:static?).and_return(false)
    end

    it "accepts valid resource requirements" do
      new_resource.content(unit_content_string)
      provider.load_current_resource
      provider.define_resource_requirements
      expect { provider.process_resource_requirements }.to_not raise_error
    end

    it "rejects failed resource requirements" do
      new_resource.content(malformed_content_string)
      provider.load_current_resource
      provider.define_resource_requirements
      expect { provider.process_resource_requirements }.to raise_error(IniParse::ParseError)
    end
  end

  describe "load_current_resource" do
    before(:each) do
      allow(provider).to receive(:active?).and_return(false)
      allow(provider).to receive(:enabled?).and_return(false)
      allow(provider).to receive(:masked?).and_return(false)
      allow(provider).to receive(:static?).and_return(false)
      allow(provider).to receive(:indirect?).and_return(false)
    end

    it "should create a current resource with the name of the new resource" do
      expect(Chef::Resource::SystemdUnit).to receive(:new)
        .with(unit_name)
        .and_return(current_resource)
      provider.load_current_resource
    end

    it "should check if the unit is active" do
      expect(provider).to receive(:active?)
      provider.load_current_resource
    end

    it "sets the active property to true if the unit is active" do
      allow(provider).to receive(:active?).and_return(true)
      provider.load_current_resource
      expect(current_resource.active).to be true
    end

    it "sets the active property to false if the unit is not active" do
      allow(provider).to receive(:active?).and_return(false)
      provider.load_current_resource
      expect(current_resource.active).to be false
    end

    it "should check if the unit is enabled" do
      expect(provider).to receive(:enabled?)
      provider.load_current_resource
    end

    it "sets the enabled property to true if the unit is enabled" do
      allow(provider).to receive(:enabled?).and_return(true)
      provider.load_current_resource
      expect(current_resource.enabled).to be true
    end

    it "sets the enabled property to false if the unit is not enabled" do
      allow(provider).to receive(:enabled?).and_return(false)
      provider.load_current_resource
      expect(current_resource.enabled).to be false
    end

    it "should check if the unit is masked" do
      expect(provider).to receive(:masked?)
      provider.load_current_resource
    end

    it "sets the masked property to true if the unit is masked" do
      allow(provider).to receive(:masked?).and_return(true)
      provider.load_current_resource
      expect(current_resource.masked).to be true
    end

    it "sets the masked property to false if the unit is masked" do
      allow(provider).to receive(:masked?).and_return(false)
      provider.load_current_resource
      expect(current_resource.masked).to be false
    end

    it "should check if the unit is static" do
      expect(provider).to receive(:static?)
      provider.load_current_resource
    end

    it "sets the static property to true if the unit is static" do
      allow(provider).to receive(:static?).and_return(true)
      provider.load_current_resource
      expect(current_resource.static).to be true
    end

    it "sets the static property to false if the unit is not static" do
      allow(provider).to receive(:static?).and_return(false)
      provider.load_current_resource
      expect(current_resource.static).to be false
    end

    it "loads the system unit content if the file exists and user is not set" do
      allow(File).to receive(:exist?)
        .with(unit_path_system)
        .and_return(true)
      allow(File).to receive(:read)
        .with(unit_path_system)
        .and_return(unit_content_string)

      expect(File).to receive(:exist?)
        .with(unit_path_system)
      expect(File).to receive(:read)
        .with(unit_path_system)
      provider.load_current_resource
      expect(current_resource.content).to eq(unit_content_string)
    end

    it "does not load the system unit content if the unit file is not present and the user is not set" do
      allow(File).to receive(:exist?)
        .with(unit_path_system)
        .and_return(false)
      expect(File).to_not receive(:read)
        .with(unit_path_system)
      provider.load_current_resource
      expect(current_resource.content).to eq(nil)
    end

    # A password is required when specifying a user on Windows. Since systemd resources
    # won't actually run on Windows, skip these tests rather than code a workaround.
    unless windows?
      it "loads the user unit content if the file exists and user is set" do
        new_resource.user("joe")
        allow(File).to receive(:exist?)
          .with(unit_path_user)
          .and_return(true)
        allow(File).to receive(:read)
          .with(unit_path_user)
          .and_return(unit_content_string)
        expect(File).to receive(:exist?)
          .with(unit_path_user)
        expect(File).to receive(:read)
          .with(unit_path_user)
        provider.load_current_resource
        expect(current_resource.content).to eq(unit_content_string)
      end

      it "does not load the user unit if the file does not exist and user is set" do
        new_resource.user("joe")
        allow(File).to receive(:exist?)
          .with(unit_path_user)
          .and_return(false)
        expect(File).to_not receive(:read)
          .with(unit_path_user)
        provider.load_current_resource
        expect(current_resource.content).to eq(nil)
      end
    end
  end

  %w{/bin/systemctl /usr/bin/systemctl}.each do |systemctl_path|
    describe "when systemctl path is #{systemctl_path}" do
      before(:each) do
        provider.current_resource = current_resource
        allow(provider).to receive(:which)
          .with("systemctl")
          .and_return(systemctl_path)
      end

      describe "creates/deletes/presets/reverts the unit" do
        it "creates the unit file when it does not exist" do
          allow(provider).to receive(:manage_unit_file)
            .with(:create)
            .and_return(true)
          allow(provider).to receive(:daemon_reload)
            .and_return(true)
          expect(provider).to receive(:manage_unit_file).with(:create)
          provider.action_create
        end

        it "creates the file when the unit content is different" do
          allow(provider).to receive(:manage_unit_file)
            .with(:create)
            .and_return(true)
          allow(provider).to receive(:daemon_reload)
            .and_return(true)
          expect(provider).to receive(:manage_unit_file).with(:create)
          provider.action_create
        end

        it "does not create the unit file when the content is the same" do
          current_resource.content(unit_content_string)
          allow(provider).to receive(:manage_unit_file).with(:create)
          allow(provider).to receive(:daemon_reload)
            .and_return(true)
          expect(provider).to_not receive(:manage_unit_file)
          provider.action_create
        end

        context "when a user is specified" do
          it "triggers a daemon-reload when creating a unit with triggers_reload" do
            new_resource.user("joe")
            allow(provider).to receive(:manage_unit_file).with(:create)
            expect(new_resource.triggers_reload).to eq true
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "daemon-reload", **user_cmd_opts, default_env: false)
            provider.action_create
          end

          it "triggers a daemon-reload when deleting a unit with triggers_reload" do
            new_resource.user("joe")
            allow(File).to receive(:exist?)
              .with(unit_path_user)
              .and_return(true)
            allow(provider).to receive(:manage_unit_file).with(:delete)
            expect(new_resource.triggers_reload).to eq true
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "daemon-reload", **user_cmd_opts, default_env: false)
            provider.action_delete
          end

          it "does not trigger a daemon-reload when creating a unit without triggers_reload" do
            new_resource.user("joe")
            new_resource.triggers_reload(false)
            allow(provider).to receive(:manage_unit_file).with(:create)
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to_not receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "daemon-reload", **user_cmd_opts, default_env: false)
            provider.action_create
          end

          it "does not trigger a daemon-reload when deleting a unit without triggers_reload" do
            new_resource.user("joe")
            new_resource.triggers_reload(false)
            allow(File).to receive(:exist?)
              .with(unit_path_user)
              .and_return(true)
            allow(provider).to receive(:manage_unit_file).with(:delete)
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to_not receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "daemon-reload", **user_cmd_opts, default_env: false)
            provider.action_delete
          end

          it "deletes the file when it exists" do
            new_resource.user("joe")
            allow(File).to receive(:exist?)
              .with(unit_path_user)
              .and_return(true)
            allow(provider).to receive(:manage_unit_file)
              .with(:delete)
              .and_return(true)
            allow(provider).to receive(:daemon_reload)
            expect(provider).to receive(:manage_unit_file).with(:delete)
            provider.action_delete
          end

          it "does not delete the file when it is absent" do
            new_resource.user("joe")
            allow(File).to receive(:exist?)
              .with(unit_path_user)
              .and_return(false)
            allow(provider).to receive(:manage_unit_file).with(:delete)
            expect(provider).to_not receive(:manage_unit_file)
            provider.action_delete
          end

          it "presets the unit" do
            new_resource.user("joe")
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "preset", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_preset
          end

          it "reverts the unit" do
            new_resource.user("joe")
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "revert", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_revert
          end
        end

        context "when no user is specified" do
          it "triggers a daemon-reload when creating a unit with triggers_reload" do
            allow(provider).to receive(:manage_unit_file).with(:create)
            expect(new_resource.triggers_reload).to eq true
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "daemon-reload", default_env: false)
            provider.action_create
          end

          it "triggers a daemon-reload when deleting a unit with triggers_reload" do
            allow(File).to receive(:exist?)
              .with(unit_path_system)
              .and_return(true)
            allow(provider).to receive(:manage_unit_file).with(:delete)
            expect(new_resource.triggers_reload).to eq true
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "daemon-reload", default_env: false)
            provider.action_delete
          end

          it "does not trigger a daemon-reload when creating a unit without triggers_reload" do
            new_resource.triggers_reload(false)
            allow(provider).to receive(:manage_unit_file).with(:create)
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to_not receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "daemon-reload", default_env: false)
            provider.action_create
          end

          it "does not trigger a daemon-reload when deleting a unit without triggers_reload" do
            new_resource.triggers_reload(false)
            allow(File).to receive(:exist?)
              .with(unit_path_system)
              .and_return(true)
            allow(provider).to receive(:manage_unit_file).with(:delete)
            allow(provider).to receive(:shell_out_compacted!)
            expect(provider).to_not receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "daemon-reload", default_env: false)
            provider.action_delete
          end
          it "deletes the file when it exists" do
            allow(File).to receive(:exist?)
              .with(unit_path_system)
              .and_return(true)
            allow(provider).to receive(:manage_unit_file)
              .with(:delete)
            allow(provider).to receive(:daemon_reload)
            expect(provider).to receive(:manage_unit_file).with(:delete)
            provider.action_delete
          end

          it "does not delete the file when it is absent" do
            allow(File).to receive(:exist?)
              .with(unit_path_system)
              .and_return(false)
            allow(provider).to receive(:manage_unit_file).with(:delete)
            allow(provider).to receive(:daemon_reload)
            expect(provider).to_not receive(:manage_unit_file)
            provider.action_delete
          end

          it "presets the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "preset", unit_name)
              .and_return(shell_out_success)
            provider.action_preset
          end

          it "reverts the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "revert", unit_name)
              .and_return(shell_out_success)
            provider.action_revert
          end
        end
      end

      describe "enables/disables/reenables the unit" do
        context "when a user is specified" do
          it "reenables the unit" do
            current_resource.user(user_name)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "reenable", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_reenable
          end

          it "enables the unit when it is disabled" do
            current_resource.user(user_name)
            current_resource.enabled(false)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "enable", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_enable
          end

          it "does not enable the unit when it is enabled" do
            current_resource.user(user_name)
            current_resource.enabled(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_enable
          end

          it "does not enable the unit when it is static" do
            current_resource.user(user_name)
            current_resource.static(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_enable
          end

          it "disables the unit when it is enabled" do
            current_resource.user(user_name)
            current_resource.enabled(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "disable", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_disable
          end

          it "does not disable the unit when it is disabled" do
            current_resource.user(user_name)
            current_resource.enabled(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_disable
          end

          it "does not disable the unit when it is static" do
            current_resource.user(user_name)
            current_resource.static(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_disable
          end
        end

        context "when no user is specified" do
          it "reenables the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "reenable", unit_name)
              .and_return(shell_out_success)
            provider.action_reenable
          end

          it "enables the unit when it is disabled" do
            current_resource.enabled(false)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "enable", unit_name)
              .and_return(shell_out_success)
            provider.action_enable
          end

          it "does not enable the unit when it is enabled" do
            current_resource.enabled(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_enable
          end

          it "does not enable the unit when it is static" do
            current_resource.static(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_enable
          end

          it "disables the unit when it is enabled" do
            current_resource.enabled(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "disable", unit_name)
              .and_return(shell_out_success)
            provider.action_disable
          end

          it "does not disable the unit when it is disabled" do
            current_resource.enabled(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_disable
          end

          it "does not disable the unit when it is static" do
            current_resource.user(user_name)
            current_resource.static(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_disable
          end
        end
      end

      describe "masks/unmasks the unit" do
        context "when a user is specified" do
          it "masks the unit when it is unmasked" do
            current_resource.user(user_name)
            current_resource.masked(false)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "mask", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_mask
          end

          it "does not mask the unit when it is masked" do
            current_resource.user(user_name)
            current_resource.masked(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_mask
          end

          it "unmasks the unit when it is masked" do
            current_resource.user(user_name)
            current_resource.masked(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "unmask", unit_name, **user_cmd_opts)
              .and_return(shell_out_success)
            provider.action_unmask
          end

          it "does not unmask the unit when it is unmasked" do
            current_resource.user(user_name)
            current_resource.masked(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_unmask
          end
        end

        context "when no user is specified" do
          it "masks the unit when it is unmasked" do
            current_resource.masked(false)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "mask", unit_name)
              .and_return(shell_out_success)
            provider.action_mask
          end

          it "does not mask the unit when it is masked" do
            current_resource.masked(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_mask
          end

          it "unmasks the unit when it is masked" do
            current_resource.masked(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "unmask", unit_name)
              .and_return(shell_out_success)
            provider.action_unmask
          end

          it "does not unmask the unit when it is unmasked" do
            current_resource.masked(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_unmask
          end
        end
      end

      describe "starts/stops the unit" do
        context "when a user is specified" do
          it "starts the unit when it is inactive" do
            current_resource.user(user_name)
            current_resource.active(false)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "start", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_start
          end

          it "does not start the unit when it is active" do
            current_resource.user(user_name)
            current_resource.active(true)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_start
          end

          it "stops the unit when it is active" do
            current_resource.user(user_name)
            current_resource.active(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "stop", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_stop
          end

          it "does not stop the unit when it is inactive" do
            current_resource.user(user_name)
            current_resource.active(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_stop
          end
        end

        context "when no user is specified" do
          it "starts the unit when it is inactive" do
            current_resource.active(false)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "start", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_start
          end

          it "does not start the unit when it is active" do
            current_resource.active(true)
            expect(provider).to_not receive(:shell_out_compacted!)
            provider.action_start
          end

          it "stops the unit when it is active" do
            current_resource.active(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "stop", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_stop
          end

          it "does not stop the unit when it is inactive" do
            current_resource.active(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_stop
          end
        end
      end

      describe "restarts/reloads the unit" do
        context "when a user is specified" do
          it "restarts the unit" do
            current_resource.user(user_name)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "restart", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_restart
          end

          it "reloads the unit if active" do
            current_resource.user(user_name)
            current_resource.active(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "reload", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_reload
          end

          it "does not reload if the unit is inactive" do
            current_resource.user(user_name)
            current_resource.active(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_reload
          end
        end

        context "when no user is specified" do
          it "restarts the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "restart", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_restart
          end

          it "reloads the unit if active" do
            current_resource.active(true)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "reload", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_reload
          end

          it "does not reload the unit if inactive" do
            current_resource.active(false)
            expect(provider).not_to receive(:shell_out_compacted!)
            provider.action_reload
          end
        end
      end

      describe "try-restarts the unit" do
        context "when a user is specified" do
          it "try-restarts the unit" do
            current_resource.user(user_name)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "try-restart", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_try_restart
          end
        end

        context "when no user is specified" do
          it "try-restarts the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "try-restart", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_try_restart
          end
        end
      end

      describe "reload-or-restarts the unit" do
        context "when a user is specified" do
          it "reload-or-restarts the unit" do
            current_resource.user(user_name)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "reload-or-restart", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_reload_or_restart
          end
        end

        context "when no user is specified" do
          it "reload-or-restarts the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "reload-or-restart", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_reload_or_restart
          end
        end
      end

      describe "reload-or-try-restarts the unit" do
        context "when a user is specified" do
          it "reload-or-try-restarts the unit" do
            current_resource.user(user_name)
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--user", "reload-or-try-restart", unit_name, **user_cmd_opts, default_env: false)
              .and_return(shell_out_success)
            provider.action_reload_or_try_restart
          end
        end

        context "when no user is specified" do
          it "reload-or-try-restarts the unit" do
            expect(provider).to receive(:shell_out_compacted!)
              .with(systemctl_path, "--system", "reload-or-try-restart", unit_name, default_env: false)
              .and_return(shell_out_success)
            provider.action_reload_or_try_restart
          end
        end
      end

      def with_systemctl_show(systemctl_path, instance, opts, stdout)
        systemctl_show = [systemctl_path, instance, "show", "-p", "UnitFileState", "-p", "ActiveState", unit_name]
        expect(provider).to receive(:shell_out).with(*systemctl_show, **opts).and_return(double(stdout: stdout, exitstatus: 0, error?: false))
      end

      describe "systemd_unit_status" do
        before(:each) do
          provider.current_resource = current_resource
          current_resource.unit_name(unit_name)
        end

        it "should return status if '#{systemctl_path} --system show -p UnitFileState -p ActiveState unit_name' returns 0 and has nil" do
          # No unit known for this service, and inactive
          nil_and_inactive = <<-STDOUT
            ActiveState=inactive
            UnitFileState=
          STDOUT
          nil_and_inactive_h = {
            "ActiveState" => "inactive",
            "UnitFileState" => nil,
          }
          with_systemctl_show(systemctl_path, "--system", {},  nil_and_inactive)
          expect(provider.systemd_unit_status).to eql(nil_and_inactive_h)
        end

        it "should not error if '#{systemctl_path} --system show' is run against a template unit" do
          current_resource.unit_name("foo@.service")
          template_error = "Failed to get properties: Unit name foo@.service is neither a valid invocation ID nor unit name."
          systemctl_show = [systemctl_path, "--system", "show", "-p", "UnitFileState", "-p", "ActiveState", "foo@.service"]
          expect(provider).to receive(:shell_out).with(*systemctl_show).and_return(double(stdout: "", stderr: template_error, exitstatus: 1, error?: true))
          expect(provider.systemd_unit_status).to eql({})
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

      describe "#active?" do
        before(:each) do
          provider.current_resource = current_resource
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        context "when a user is specified" do
          it "returns true when unit is active" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, enabled_and_active)
            expect(provider.active?).to be true
          end

          it "returns false when unit is inactive" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, disabled_and_inactive)
            expect(provider.active?).to be false
          end
        end

        context "when no user is specified" do
          it "returns true when unit is active" do
            with_systemctl_show(systemctl_path, "--system", {}, enabled_and_active)
            expect(provider.active?).to be true
          end

          it "returns false when unit is not active" do
            with_systemctl_show(systemctl_path, "--system", {}, disabled_and_inactive)
            expect(provider.active?).to be false
          end
        end
      end

      describe "#enabled?" do
        before(:each) do
          provider.current_resource = current_resource
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        context "when a user is specified" do
          it "returns true when unit is enabled" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, enabled_and_active)
            expect(provider.enabled?).to be true
          end

          it "returns false when unit is not enabled" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, disabled_and_inactive)
            expect(provider.enabled?).to be false
          end
        end

        context "when no user is specified" do
          it "returns true when unit is enabled" do
            with_systemctl_show(systemctl_path, "--system", {}, enabled_and_active)
            expect(provider.enabled?).to be true
          end

          it "returns false when unit is not enabled" do
            with_systemctl_show(systemctl_path, "--system", {}, disabled_and_inactive)
            expect(provider.enabled?).to be false
          end
        end
      end

      describe "#masked?" do
        before(:each) do
          provider.current_resource = current_resource
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        masked_and_inactive = <<-STDOUT
          ActiveState=inactive
          UnitFileState=masked
        STDOUT

        context "when a user is specified" do
          it "returns true when the unit is masked" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, masked_and_inactive)
            expect(provider.masked?).to be true
          end

          it "returns false when the unit is not masked" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, enabled_and_active)
            expect(provider.masked?).to be false
          end
        end

        context "when no user is specified" do
          it "returns true when the unit is masked" do
            with_systemctl_show(systemctl_path, "--system", {}, masked_and_inactive)
            expect(provider.masked?).to be true
          end

          it "returns false when the unit is not masked" do
            with_systemctl_show(systemctl_path, "--system", {}, enabled_and_active)
            expect(provider.masked?).to be false
          end
        end
      end

      describe "#static?" do
        before(:each) do
          provider.current_resource = current_resource
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        static_and_active = <<-STDOUT
          ActiveState=active
          UnitFileState=static
        STDOUT

        context "when a user is specified" do
          it "returns true when the unit is static" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, static_and_active)
            expect(provider.static?).to be true
          end

          it "returns false when the unit is not static" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, enabled_and_active)
            expect(provider.static?).to be false
          end
        end

        context "when no user is specified" do
          it "returns true when the unit is static" do
            with_systemctl_show(systemctl_path, "--system", {}, static_and_active)
            expect(provider.static?).to be true
          end

          it "returns false when the unit is not static" do
            with_systemctl_show(systemctl_path, "--system", {}, enabled_and_active)
            expect(provider.static?).to be false
          end
        end
      end

      describe "#indirect?" do
        before(:each) do
          provider.current_resource = current_resource
          allow(provider).to receive(:which).with("systemctl").and_return(systemctl_path.to_s)
        end

        indirect_and_inactive = <<-STDOUT
          ActiveState=inactive
          UnitFileState=indirect
        STDOUT

        context "when a user is specified" do
          it "returns true when the unit is indirect" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, indirect_and_inactive)
            expect(provider.indirect?).to be true
          end

          it "returns false when the unit is not indirect" do
            current_resource.user(user_name)
            with_systemctl_show(systemctl_path, "--user", user_cmd_opts, enabled_and_active)
            expect(provider.indirect?).to be false
          end
        end

        context "when no user is specified" do
          it "returns true when the unit is indirect" do
            with_systemctl_show(systemctl_path, "--system", {}, indirect_and_inactive)
            expect(provider.indirect?).to be true
          end

          it "returns false when the unit is not indirect" do
            with_systemctl_show(systemctl_path, "--system", {}, enabled_and_active)
            expect(provider.indirect?).to be false
          end
        end
      end
    end
  end
end
