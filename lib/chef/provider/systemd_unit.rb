#
# Author:: Nathan Williams (<nath.e.will@gmail.com>)
# Copyright:: Copyright 2016, Nathan Williams
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

require "chef/provider"
require "chef/mixin/which"
require "chef/mixin/shell_out"
require "chef/resource/file"
require "chef/resource/file/verification/systemd_unit"
require "iniparse"

class Chef
  class Provider
    class SystemdUnit < Chef::Provider
      include Chef::Mixin::Which
      include Chef::Mixin::ShellOut

      provides :systemd_unit, os: "linux"

      def load_current_resource
        @current_resource = Chef::Resource::SystemdUnit.new(new_resource.name)

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
          converge_by("creating unit: #{new_resource.name}") do
            manage_unit_file(:create)
            daemon_reload if new_resource.triggers_reload
          end
        end
      end

      def action_delete
        if ::File.exist?(unit_path)
          converge_by("deleting unit: #{new_resource.name}") do
            manage_unit_file(:delete)
            daemon_reload if new_resource.triggers_reload
          end
        end
      end

      def action_enable
        if current_resource.static
          Chef::Log.debug("#{new_resource.name} is a static unit, enabling is a NOP.")
        end

        unless current_resource.enabled || current_resource.static
          converge_by("enabling unit: #{new_resource.name}") do
            systemctl_execute!(:enable, new_resource.name)
          end
        end
      end

      def action_disable
        if current_resource.static
          Chef::Log.debug("#{new_resource.name} is a static unit, disabling is a NOP.")
        end

        if current_resource.enabled && !current_resource.static
          converge_by("disabling unit: #{new_resource.name}") do
            systemctl_execute!(:disable, new_resource.name)
          end
        end
      end

      def action_mask
        unless current_resource.masked
          converge_by("masking unit: #{new_resource.name}") do
            systemctl_execute!(:mask, new_resource.name)
          end
        end
      end

      def action_unmask
        if current_resource.masked
          converge_by("unmasking unit: #{new_resource.name}") do
            systemctl_execute!(:unmask, new_resource.name)
          end
        end
      end

      def action_start
        unless current_resource.active
          converge_by("starting unit: #{new_resource.name}") do
            systemctl_execute!(:start, new_resource.name)
          end
        end
      end

      def action_stop
        if current_resource.active
          converge_by("stopping unit: #{new_resource.name}") do
            systemctl_execute!(:stop, new_resource.name)
          end
        end
      end

      def action_restart
        converge_by("restarting unit: #{new_resource.name}") do
          systemctl_execute!(:restart, new_resource.name)
        end
      end

      def action_reload
        if current_resource.active
          converge_by("reloading unit: #{new_resource.name}") do
            systemctl_execute!(:reload, new_resource.name)
          end
        else
          Chef::Log.debug("#{new_resource.name} is not active, skipping reload.")
        end
      end

      def action_try_restart
        converge_by("try-restarting unit: #{new_resource.name}") do
          systemctl_execute!("try-restart", new_resource.name)
        end
      end

      def action_reload_or_restart
        converge_by("reload-or-restarting unit: #{new_resource.name}") do
          systemctl_execute!("reload-or-restart", new_resource.name)
        end
      end

      def action_reload_or_try_restart
        converge_by("reload-or-try-restarting unit: #{new_resource.name}") do
          systemctl_execute!("reload-or-try-restart", new_resource.name)
        end
      end

      def active?
        systemctl_execute("is-active", new_resource.name).exitstatus == 0
      end

      def enabled?
        systemctl_execute("is-enabled", new_resource.name).exitstatus == 0
      end

      def masked?
        systemctl_execute(:status, new_resource.name).stdout.include?("masked")
      end

      def static?
        systemctl_execute("is-enabled", new_resource.name).stdout.include?("static")
      end

      private

      def unit_path
        if new_resource.user
          "/etc/systemd/user/#{new_resource.name}"
        else
          "/etc/systemd/system/#{new_resource.name}"
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
        shell_out_with_systems_locale!("#{systemctl_path} daemon-reload")
      end

      def systemctl_execute!(action, unit)
        shell_out_with_systems_locale!("#{systemctl_cmd} #{action} #{unit}", systemctl_opts)
      end

      def systemctl_execute(action, unit)
        shell_out("#{systemctl_cmd} #{action} #{unit}", systemctl_opts)
      end

      def systemctl_cmd
        @systemctl_cmd ||= "#{systemctl_path} #{systemctl_args}"
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
            {
              :user => new_resource.user,
              :environment => {
                "DBUS_SESSION_BUS_ADDRESS" => "unix:path=/run/user/#{node['etc']['passwd'][new_resource.user]['uid']}/bus",
              },
            }
          else
            {}
          end
      end
    end
  end
end
