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

require_relative "../provider"
require_relative "../mixin/which"
require_relative "../mixin/shell_out"
require_relative "../resource/file"
require_relative "../resource/file/verification/systemd_unit"
require "iniparse"
require "shellwords" unless defined?(Shellwords)

class Chef
  class Provider
    class SystemdUnit < Chef::Provider
      include Chef::Mixin::Which
      include Chef::Mixin::ShellOut

      provides :systemd_unit

      def load_current_resource
        @current_resource = Chef::Resource::SystemdUnit.new(new_resource.name)

        current_resource.unit_name(new_resource.unit_name)
        current_resource.content(::File.read(unit_path)) if ::File.exist?(unit_path)
        current_resource.user(new_resource.user)
        current_resource.enabled(enabled?)
        current_resource.active(active?)
        current_resource.masked(masked?)
        current_resource.static(static?)
        current_resource.triggers_reload(new_resource.triggers_reload)

        current_resource
      end

      def define_resource_requirements
        super

        requirements.assert(:create) do |a|
          a.assertion { IniParse.parse(new_resource.to_ini) }
          a.failure_message "Unit content is not valid INI text"
        end
      end

      def action_create
        if current_resource.content != new_resource.to_ini
          converge_by("creating unit: #{new_resource.unit_name}") do
            manage_unit_file(:create)
            daemon_reload if new_resource.triggers_reload
          end
        end
      end

      def action_delete
        if ::File.exist?(unit_path)
          converge_by("deleting unit: #{new_resource.unit_name}") do
            manage_unit_file(:delete)
            daemon_reload if new_resource.triggers_reload
          end
        end
      end

      def action_preset
        converge_by("restoring enable/disable preset configuration for unit: #{new_resource.unit_name}") do
          systemctl_execute!(:preset, new_resource.unit_name)
        end
      end

      def action_revert
        converge_by("reverting to vendor version of unit: #{new_resource.unit_name}") do
          systemctl_execute!(:revert, new_resource.unit_name)
        end
      end

      def action_enable
        if current_resource.static
          logger.trace("#{new_resource.unit_name} is a static unit, enabling is a NOP.")
        end

        unless current_resource.enabled || current_resource.static
          converge_by("enabling unit: #{new_resource.unit_name}") do
            systemctl_execute!(:enable, new_resource.unit_name)
          end
        end
      end

      def action_disable
        if current_resource.static
          logger.trace("#{new_resource.unit_name} is a static unit, disabling is a NOP.")
        end

        if current_resource.enabled && !current_resource.static
          converge_by("disabling unit: #{new_resource.unit_name}") do
            systemctl_execute!(:disable, new_resource.unit_name)
          end
        end
      end

      def action_reenable
        converge_by("reenabling unit: #{new_resource.unit_name}") do
          systemctl_execute!(:reenable, new_resource.unit_name)
        end
      end

      def action_mask
        unless current_resource.masked
          converge_by("masking unit: #{new_resource.unit_name}") do
            systemctl_execute!(:mask, new_resource.unit_name)
          end
        end
      end

      def action_unmask
        if current_resource.masked
          converge_by("unmasking unit: #{new_resource.unit_name}") do
            systemctl_execute!(:unmask, new_resource.unit_name)
          end
        end
      end

      def action_start
        unless current_resource.active
          converge_by("starting unit: #{new_resource.unit_name}") do
            systemctl_execute!(:start, new_resource.unit_name, default_env: false)
          end
        end
      end

      def action_stop
        if current_resource.active
          converge_by("stopping unit: #{new_resource.unit_name}") do
            systemctl_execute!(:stop, new_resource.unit_name, default_env: false)
          end
        end
      end

      def action_restart
        converge_by("restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!(:restart, new_resource.unit_name, default_env: false)
        end
      end

      def action_reload
        if current_resource.active
          converge_by("reloading unit: #{new_resource.unit_name}") do
            systemctl_execute!(:reload, new_resource.unit_name, default_env: false)
          end
        else
          logger.trace("#{new_resource.unit_name} is not active, skipping reload.")
        end
      end

      def action_try_restart
        converge_by("try-restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!("try-restart", new_resource.unit_name, default_env: false)
        end
      end

      def action_reload_or_restart
        converge_by("reload-or-restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!("reload-or-restart", new_resource.unit_name, default_env: false)
        end
      end

      def action_reload_or_try_restart
        converge_by("reload-or-try-restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!("reload-or-try-restart", new_resource.unit_name, default_env: false)
        end
      end

      def active?
        systemctl_execute("is-active", new_resource.unit_name).exitstatus == 0
      end

      def enabled?
        systemctl_execute("is-enabled", new_resource.unit_name).exitstatus == 0
      end

      def masked?
        systemctl_execute("status", new_resource.unit_name).stdout.include?("masked")
      end

      def static?
        systemctl_execute("is-enabled", new_resource.unit_name).stdout.include?("static")
      end

      private

      def unit_path
        if new_resource.user
          "/etc/systemd/user/#{new_resource.unit_name}"
        else
          "/etc/systemd/system/#{new_resource.unit_name}"
        end
      end

      def manage_unit_file(action = :nothing)
        Chef::Resource::File.new(unit_path, run_context).tap do |f|
          f.owner "root"
          f.group "root"
          f.mode "0644"
          f.content new_resource.to_ini
          f.verify :systemd_unit if new_resource.verify
        end.run_action(action)
      end

      def daemon_reload
        shell_out!(systemctl_cmd, "daemon-reload", **systemctl_opts, default_env: false)
      end

      def systemctl_execute!(action, unit, **options)
        shell_out!(systemctl_cmd, action, unit, **systemctl_opts.merge(options))
      end

      def systemctl_execute(action, unit, **options)
        shell_out(systemctl_cmd, action, unit, **systemctl_opts.merge(options))
      end

      def systemctl_cmd
        @systemctl_cmd ||= [ systemctl_path, systemctl_args ]
      end

      def systemctl_path
        @systemctl_path ||= which("systemctl")
      end

      def systemctl_args
        @systemctl_args ||= new_resource.user ? "--user" : "--system"
      end

      def systemctl_opts
        @systemctl_opts ||=
          if new_resource.user
            uid = Etc.getpwnam(new_resource.user).uid
            {
              user: new_resource.user,
              environment: {
                "DBUS_SESSION_BUS_ADDRESS" => "unix:path=/run/user/#{uid}/bus",
              },
            }
          else
            {}
          end
      end
    end
  end
end
