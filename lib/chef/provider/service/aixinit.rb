#
# Author:: kaustubh (<kaustubh@clogeny.com>)
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
      class AixInit < Chef::Provider::Service::Init
        RC_D_SCRIPT_NAME = %r{/etc/rc.d/rc2.d/([SK])(\d\d|)}i.freeze

        def initialize(new_resource, run_context)
          super
          @init_command = "/etc/rc.d/init.d/#{@new_resource.service_name}"
        end

        def load_current_resource
          super
          @priority_success = true
          @rcd_status = nil

          set_current_resource_attributes
          @current_resource
        end

        action :enable do
          if @new_resource.priority.nil?
            priority_ok = true
          else
            priority_ok = @current_resource.priority == @new_resource.priority
          end
          if @current_resource.enabled && priority_ok
            logger.debug("#{@new_resource} already enabled - nothing to do")
          else
            converge_by("enable service #{@new_resource}") do
              enable_service
              logger.info("#{@new_resource} enabled")
            end
          end
          load_new_resource_state
          @new_resource.enabled(true)
        end

        def enable_service
          Dir.glob(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).each { |f| ::File.delete(f) }

          if @new_resource.priority.is_a? Integer
            create_symlink(2, "S", @new_resource.priority)

          elsif @new_resource.priority.is_a? Hash
            @new_resource.priority.each do |level, o|
              create_symlink(level, (o[0] == :start ? "S" : "K"), o[1])
            end
          else
            create_symlink(2, "S", "")
          end
        end

        def disable_service
          Dir.glob(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).each { |f| ::File.delete(f) }

          if @new_resource.priority.is_a? Integer
            create_symlink(2, "K", 100 - @new_resource.priority)
          elsif @new_resource.priority.is_a? Hash
            @new_resource.priority.each do |level, o|
              create_symlink(level, "K", 100 - o[1]) if o[0] == :stop
            end
          else
            create_symlink(2, "K", "")
          end
        end

        def create_symlink(run_level, status, priority)
          ::File.symlink("/etc/rc.d/init.d/#{@new_resource.service_name}", "/etc/rc.d/rc#{run_level}.d/#{status}#{priority}#{@new_resource.service_name}")
        end

        def set_current_resource_attributes
          # assuming run level 2 for aix
          is_enabled = false
          files = Dir.glob(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"])

          priority = {}

          files.each do |file|
            if RC_D_SCRIPT_NAME =~ file
              priority[2] = [($1 == "S" ? :start : :stop), ($2.empty? ? "" : $2.to_i)]
              if $1 == "S"
                is_enabled = true
              end
            end
          end

          if is_enabled && files.length == 1
            priority = priority[2][1]
          end
          @current_resource.enabled(is_enabled)
          @current_resource.priority(priority)
        end
      end
    end
  end
end
