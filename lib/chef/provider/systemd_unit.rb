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
require_relative "../resource/file"
require_relative "../resource/file/verification/systemd_unit"
require "iniparse"
require "shellwords" unless defined?(Shellwords)

class Chef
  class Provider
    class SystemdUnit < Chef::Provider
      include Chef::Mixin::Which

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
        current_resource.indirect(indirect?)
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

      def systemd_unit_status
        @systemd_unit_status ||= begin
          # Collect all the status information for a unit and return it at once
          # This may fail if we are managing a template unit (e.g. with '@'), in which case
          # we just ignore the error because unit status is irrelevant in that case
          s = shell_out(*systemctl_cmd, "show", "-p", "UnitFileState", "-p", "ActiveState", new_resource.unit_name, **systemctl_opts)
          # e.g. /bin/systemctl --system show -p UnitFileState -p ActiveState syslog.socket
          # Returns something like:
          # ActiveState=inactive
          # UnitFileState=static
          status = {}
          s.stdout.each_line do |line|
            k, v = line.strip.split("=")
            status[k] = v
          end

          status
        end
      end

      action :create do
        if current_resource.content != new_resource.to_ini
          converge_by("creating unit: #{new_resource.unit_name}") do
            manage_unit_file(:create)
            daemon_reload if new_resource.triggers_reload
          end
        end
      end

      action :delete do
        if ::File.exist?(unit_path)
          converge_by("deleting unit: #{new_resource.unit_name}") do
            manage_unit_file(:delete)
            daemon_reload if new_resource.triggers_reload
          end
        end
      end

      action :preset do
        converge_by("restoring enable/disable preset configuration for unit: #{new_resource.unit_name}") do
          systemctl_execute!(:preset, new_resource.unit_name)
        end
      end

      action :revert do
        converge_by("reverting to vendor version of unit: #{new_resource.unit_name}") do
          systemctl_execute!(:revert, new_resource.unit_name)
        end
      end

      action :enable do
        if current_resource.static
          logger.debug("#{new_resource.unit_name} is a static unit, enabling is a NOP.")
        end
        if current_resource.indirect
          logger.debug("#{new_resource.unit_name} is an indirect unit, enabling is a NOP.")
        end

        unless current_resource.enabled || current_resource.static || current_resource.indirect
          converge_by("enabling unit: #{new_resource.unit_name}") do
            systemctl_execute!(:enable, new_resource.unit_name)
            logger.info("#{new_resource} enabled")
          end
        end
      end

      action :disable do
        if current_resource.static
          logger.debug("#{new_resource.unit_name} is a static unit, disabling is a NOP.")
        end

        if current_resource.indirect
          logger.debug("#{new_resource.unit_name} is an indirect unit, enabling is a NOP.")
        end

        if current_resource.enabled && !current_resource.static && !current_resource.indirect
          converge_by("disabling unit: #{new_resource.unit_name}") do
            systemctl_execute!(:disable, new_resource.unit_name)
            logger.info("#{new_resource} disabled")
          end
        end
      end

      action :reenable do
        converge_by("reenabling unit: #{new_resource.unit_name}") do
          systemctl_execute!(:reenable, new_resource.unit_name)
          logger.info("#{new_resource} reenabled")
        end
      end

      action :mask do
        unless current_resource.masked
          converge_by("masking unit: #{new_resource.unit_name}") do
            systemctl_execute!(:mask, new_resource.unit_name)
            logger.info("#{new_resource} masked")
          end
        end
      end

      action :unmask do
        if current_resource.masked
          converge_by("unmasking unit: #{new_resource.unit_name}") do
            systemctl_execute!(:unmask, new_resource.unit_name)
            logger.info("#{new_resource} unmasked")
          end
        end
      end

      action :start do
        unless current_resource.active
          converge_by("starting unit: #{new_resource.unit_name}") do
            systemctl_execute!(:start, new_resource.unit_name, default_env: false)
            logger.info("#{new_resource} started")
          end
        end
      end

      action :stop do
        if current_resource.active
          converge_by("stopping unit: #{new_resource.unit_name}") do
            systemctl_execute!(:stop, new_resource.unit_name, default_env: false)
            logger.info("#{new_resource} stopped")
          end
        end
      end

      action :restart do
        converge_by("restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!(:restart, new_resource.unit_name, default_env: false)
          logger.info("#{new_resource} restarted")
        end
      end

      action :reload do
        if current_resource.active
          converge_by("reloading unit: #{new_resource.unit_name}") do
            systemctl_execute!(:reload, new_resource.unit_name, default_env: false)
            logger.info("#{new_resource} reloaded")
          end
        else
          logger.debug("#{new_resource.unit_name} is not active, skipping reload.")
        end
      end

      action :try_restart do
        converge_by("try-restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!("try-restart", new_resource.unit_name, default_env: false)
          logger.info("#{new_resource} try-restarted")
        end
      end

      action :reload_or_restart do
        converge_by("reload-or-restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!("reload-or-restart", new_resource.unit_name, default_env: false)
          logger.info("#{new_resource} reload-or-restarted")
        end
      end

      action :reload_or_try_restart do
        converge_by("reload-or-try-restarting unit: #{new_resource.unit_name}") do
          systemctl_execute!("reload-or-try-restart", new_resource.unit_name, default_env: false)
          logger.info("#{new_resource} reload-or-try-restarted")
        end
      end

      def active?
        # Note: "activating" is not active (as with type=notify or a oneshot)
        systemd_unit_status["ActiveState"] == "active"
      end

      def enabled?
        # See https://github.com/systemd/systemd/blob/master/src/systemctl/systemctl-is-enabled.c
        # Note: enabled-runtime is excluded because this is volatile, and the state of enabled-runtime
        # specifically means that the service is not enabled
        %w{enabled static generated alias indirect}.include?(systemd_unit_status["UnitFileState"])
      end

      def masked?
        # Note: masked-runtime is excluded, because runtime is volatile, and
        # because masked-runtime is not masked.
        systemd_unit_status["UnitFileState"] == "masked"
      end

      def static?
        systemd_unit_status["UnitFileState"] == "static"
      end

      def indirect?
        systemd_unit_status["UnitFileState"] == "indirect"
      end

      private

      def unit_path
        if new_resource.user
          "/etc/systemd/user/#{new_resource.unit_name}"
        else
          "/etc/systemd/system/#{new_resource.unit_name}"
        end
      end

      def manage_unit_file(the_action = :nothing)
        file unit_path do
          owner "root"
          group "root"
          mode "0644"
          sensitive new_resource.sensitive
          content new_resource.to_ini
          verify :systemd_unit if new_resource.verify
          action the_action
        end
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
