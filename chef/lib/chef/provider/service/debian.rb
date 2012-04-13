#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/provider/service'
require 'chef/provider/service/init'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Debian < Chef::Provider::Service::Init
        include Chef::Mixin::Command

        UPDATE_RC_D_ENABLED_MATCHES = /\/rc[\dS].d\/S|not installed/i
        UPDATE_RC_D_PRIORITIES = /\/rc([\dS]).d\/([SK])(\d\d)/i

        def load_current_resource
          super

          @current_resource.priority(get_priority)
          @current_resource.enabled(service_currently_enabled?(@current_resource.priority))
          @current_resource
        end

        def assert_update_rcd_available
          unless ::File.exists? "/usr/sbin/update-rc.d"
            raise Chef::Exceptions::Service, "/usr/sbin/update-rc.d does not exist!"
          end
        end

        def get_priority
          assert_update_rcd_available
          priority = {}

          status = popen4("/usr/sbin/update-rc.d -n -f #{@current_resource.service_name} remove") do |pid, stdin, stdout, stderr|

            [stdout, stderr].each do |iop|
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
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Service, "/usr/sbin/update-rc.d -n -f #{@current_resource.service_name} failed - #{status.inspect}"
          end
          priority
        end

        def service_currently_enabled?(priority)
          enabled = false

          priority.each { |runlevel, arguments|
            Chef::Log.debug("#{@new_resource} runlevel #{runlevel}, action #{arguments[0]}, priority #{arguments[1]}")
            
            # if we are in a update-rc.d default startup runlevel && we start in this runlevel
            if (2..5).include?(runlevel.to_i) && arguments[0] == :start
              enabled = true
            end
          }

          enabled
        end

        def enable_service()
          if @new_resource.priority.is_a? Integer
            shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d #{@new_resource.service_name} defaults #{@new_resource.priority} #{100 - @new_resource.priority}")
          elsif @new_resource.priority.is_a? Hash
            # we call the same command regardless of we're enabling or disabling  
            # users passing a Hash are responsible for setting their own start priorities
            set_priority()
          else # No priority, go with update-rc.d defaults
            shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d #{@new_resource.service_name} defaults")
          end

        end

        def disable_service()
          if @new_resource.priority.is_a? Integer
            # Stop processes in reverse order of start using '100 - start_priority'
            shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} stop #{100 - @new_resource.priority} 2 3 4 5 .")
          elsif @new_resource.priority.is_a? Hash
            # we call the same command regardless of we're enabling or disabling  
            # users passing a Hash are responsible for setting their own stop priorities
            set_priority()
          else 
            # no priority, using '100 - 20 (update-rc.d default)' to stop in reverse order of start
            shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")
            shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} stop 80 2 3 4 5 .")
          end
        end

        def set_priority()
          args = ""
          @new_resource.priority.each do |level, o|
            action = o[0]
            priority = o[1]
            args += "#{action} #{priority} #{level} . "
          end
          shell_out!("/usr/sbin/update-rc.d -f #{@new_resource.service_name} remove")
          shell_out!("/usr/sbin/update-rc.d #{@new_resource.service_name} #{args}")
        end
      end
    end
  end
end
