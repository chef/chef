#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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

require_relative "init"

class Chef
  class Provider
    class Service
      class Debian < Chef::Provider::Service::Init
        provides :service, platform_family: "debian" do
          debianrcd?
        end

        UPDATE_RC_D_ENABLED_MATCHES = %r{/rc[\dS].d/S|not installed}i.freeze
        UPDATE_RC_D_PRIORITIES = %r{/rc([\dS]).d/([SK])(\d\d)}i.freeze
        RUNLEVELS = %w{ 1 2 3 4 5 S }.freeze

        def self.supports?(resource, action)
          service_script_exist?(:initd, resource.service_name)
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
            a.assertion { ::File.exist? update_rcd }
            a.failure_message Chef::Exceptions::Service, "#{update_rcd} does not exist!"
            # no whyrun recovery - this is a base system component of debian
            # distros and must be present
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @got_priority == true }
            a.failure_message Chef::Exceptions::Service, "Unable to determine priority for service"
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

        # returns a list of levels that the service should be stopped or started on
        def parse_init_file(path)
          return [] unless ::File.exist?(path)

          in_info = false
          ::File.readlines(path).each_with_object([]) do |line, acc|
            if /^### BEGIN INIT INFO/.match?(line)
              in_info = true
            elsif /^### END INIT INFO/.match?(line)
              break acc
            elsif in_info
              if line =~ /Default-(Start|Stop):\s+(\d.*)/
                acc << $2.split(" ")
              end
            end
          end.flatten
        end

        def get_priority
          priority = {}
          rc_files = []

          levels = parse_init_file(@init_command)
          levels.each do |level|
            rc_files.push Dir.glob("/etc/rc#{level}.d/[SK][0-9][0-9]#{current_resource.service_name}")
          end

          rc_files.flatten.each do |line|
            if UPDATE_RC_D_PRIORITIES =~ line
              # priority[runlevel] = [ S|K, priority ]
              # S = Start, K = Kill
              # debian runlevels: 0 Halt, 1 Singleuser, 2 Multiuser, 3-5 == 2, 6 Reboot
              priority[$1] = [($2 == "S" ? :start : :stop), $3]
            end
          end

          # Reduce existing priority back to an integer if appropriate, picking
          # runlevel 2 as a baseline
          if priority[2] && [2..5].all? { |runlevel| priority[runlevel] == priority[2] }
            priority = priority[2].last
          end

          @got_priority = true
          priority
        end

        def service_currently_enabled?(priority)
          enabled = false
          priority.each do |runlevel, arguments|
            logger.trace("#{new_resource} runlevel #{runlevel}, action #{arguments[0]}, priority #{arguments[1]}")
            # if we are in a update-rc.d default startup runlevel && we start in this runlevel
            if RUNLEVELS.include?(runlevel) && arguments[0] == :start
              enabled = true
            end
          end

          enabled
        end

        # Override method from parent to ensure priority is up-to-date
        action :enable do
          if new_resource.priority.nil?
            priority_ok = true
          else
            priority_ok = @current_resource.priority == new_resource.priority
          end
          if current_resource.enabled && priority_ok
            logger.debug("#{new_resource} already enabled - nothing to do")
          else
            converge_by("enable service #{new_resource}") do
              enable_service
              logger.info("#{new_resource} enabled")
            end
          end
          load_new_resource_state
          new_resource.enabled(true)
        end

        def enable_service
          # We call the same command regardless if we're enabling or disabling
          # Users passing a Hash are responsible for setting their own stop priorities
          if new_resource.priority.is_a? Hash
            set_priority
            return
          end

          start_priority = new_resource.priority.is_a?(Integer) ? new_resource.priority : 20
          # Stop processes in reverse order of start using '100 - start_priority'.
          stop_priority = 100 - start_priority

          shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
          shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} defaults #{start_priority} #{stop_priority}")
        end

        def disable_service
          if new_resource.priority.is_a? Hash
            # We call the same command regardless if we're enabling or disabling
            # Users passing a Hash are responsible for setting their own stop priorities
            set_priority
            return
          end

          shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")
          shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} defaults")
          shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} disable")
        end

        def set_priority
          shell_out!("/usr/sbin/update-rc.d -f #{new_resource.service_name} remove")

          # Reset priorities to default values before applying customizations. This way
          # the final state will always be consistent, regardless if all runlevels were
          # provided.
          shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} defaults")
          new_resource.priority.each do |level, (action, _priority)|
            disable_or_enable = (action == :start ? "enable" : "disable")

            shell_out!("/usr/sbin/update-rc.d #{new_resource.service_name} #{disable_or_enable} #{level}")
          end
        end
      end
    end
  end
end
