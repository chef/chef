#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/provider/service/init"

class Chef
  class Provider
    class Service
      class Debian < Chef::Provider::Service::Init
        provides :service, platform_family: "debian" do |node|
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:debian)
        end

        UPDATE_RC_D_ENABLED_MATCHES = /\/rc[\dS].d\/S|not installed/i
        UPDATE_RC_D_PRIORITIES = /\/rc([\dS]).d\/([SK])(\d\d)/i

        def self.supports?(resource, action)
          Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:initd)
        end

        def load_current_resource
          super
          current_resource.priority(get_priority)
          current_resource.enabled(service_currently_enabled?(current_resource.priority))
          current_resource
        end

        def define_resource_requirements
          # do not call super here, inherit only shared_requirements
          shared_resource_requirements
          requirements.assert(:all_actions) do |a|
            update_rcd = "/usr/sbin/update-rc.d"
            a.assertion { ::File.exists? update_rcd }
            a.failure_message Chef::Exceptions::Service, "#{update_rcd} does not exist!"
            # no whyrun recovery - this is a base system component of debian
            # distros and must be present
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @so_priority.exitstatus == 0 }
            a.failure_message Chef::Exceptions::Service, "/usr/sbin/update-rc.d -n -f #{current_resource.service_name} failed - #{@so_priority.inspect}"
            # This can happen if the service is not yet installed,so we'll fake it.
            a.whyrun ["Unable to determine priority of service, assuming service would have been correctly installed earlier in the run.",
                      "Assigning temporary priorities to continue.",
                      "If this service is not properly installed prior to this point, this will fail."] do
              temp_priorities = { "6" => [:stop, "20"],
                                  "0" => [:stop, "20"],
                                  "1" => [:stop, "20"],
                                  "2" => [:start, "20"],
                                  "3" => [:start, "20"],
                                  "4" => [:start, "20"],
                                  "5" => [:start, "20"] }
              current_resource.priority(temp_priorities)
            end
          end
        end

        def get_priority
          priority = {}

          @so_priority = shell_out!("/usr/sbin/update-rc.d -n -f #{current_resource.service_name} remove")

          [@so_priority.stdout, @so_priority.stderr].each do |iop|
            iop.each_line do |line|
              if UPDATE_RC_D_PRIORITIES =~ line
                # priority[runlevel] = [ S|K, priority ]
                # S = Start, K = Kill
                # debian runlevels: 0 Halt, 1 Singleuser, 2 Multiuser, 3-5 == 2, 6 Reboot
                priority[$1] = [($2 == "S" ? :start : :stop), $3]
              end
              if line =~ UPDATE_RC_D_ENABLED_MATCHES
                enabled = true
              end
            end
          end

          # Reduce existing priority back to an integer if appropriate, picking
          # runlevel 2 as a baseline
          if priority[2] && [2..5].all? { |runlevel| priority[runlevel] == priority[2] }
            priority = priority[2].last
          end

          priority
        end

        def service_currently_enabled?(priority)
          enabled = false
          priority.each do |runlevel, arguments|
            Chef::Log.debug("#{new_resource} runlevel #{runlevel}, action #{arguments[0]}, priority #{arguments[1]}")
            # if we are in a update-rc.d default startup runlevel && we start in this runlevel
            if %w{ 1 2 3 4 5 S }.include?(runlevel) && arguments[0] == :start
              enabled = true
            end
          end

          enabled
        end

        # Override method from parent to ensure priority is up-to-date
        def action_enable
          if new_resource.priority.nil?
            priority_ok = true
          else
            priority_ok = @current_resource.priority == new_resource.priority
          end
          if current_resource.enabled && priority_ok
            Chef::Log.debug("#{new_resource} already enabled - nothing to do")
          else
            converge_by("enable service #{new_resource}") do
              enable_service
              Chef::Log.info("#{new_resource} enabled")
            end
          end
          load_new_resource_state
          new_resource.enabled(true)
        end

        def enable_service
          if new_resource.priority.is_a? Integer
            shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} defaults #{new_resource.priority} #{100 - new_resource.priority}")
          elsif new_resource.priority.is_a? Hash
            # we call the same command regardless of we're enabling or disabling
            # users passing a Hash are responsible for setting their own start priorities
            set_priority
          else # No priority, go with update-rc.d defaults
            shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} defaults")
          end
        end

        def disable_service
          if new_resource.priority.is_a? Integer
            # Stop processes in reverse order of start using '100 - start_priority'
            shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} stop #{100 - new_resource.priority} 2 3 4 5 .")
          elsif new_resource.priority.is_a? Hash
            # we call the same command regardless of we're enabling or disabling
            # users passing a Hash are responsible for setting their own stop priorities
            set_priority
          else
            # no priority, using '100 - 20 (update-rc.d default)' to stop in reverse order of start
            shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} stop 80 2 3 4 5 .")
          end
        end

        def set_priority
          args = ""
          new_resource.priority.each do |level, o|
            action = o[0]
            priority = o[1]
            args += "#{action} #{priority} #{level} . "
          end
          shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
          shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} #{args}")
        end
      end
    end
  end
end
