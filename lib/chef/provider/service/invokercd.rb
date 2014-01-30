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
      class Invokercd < Chef::Provider::Service::Init

        def initialize(new_resource, run_context)
          super
          @init_command = "/usr/sbin/invoke-rc.d"
          @invokercd_init_command = "#{@init_command} #{@new_resource.service_name}"
        end

        def start_service
          if @new_resource.start_command
            shell_out!(@new_resource.start_command)
          else
            shell_out!("#{@invokercd_init_command} start")
          end
        end

        def stop_service
          if @new_resource.stop_command
            shell_out!(@new_resource.stop_command)
          else
            shell_out!("#{@invokercd_init_command} stop")
          end
        end

        def restart_service
          if @new_resource.restart_command
            shell_out!(@new_resource.restart_command)
          elsif not @new_resource.supports[:restart] == true
            stop_service
            sleep 1
            start_service
          else
            shell_out!("#{@invokercd_init_command} restart")
          end
        end

        def reload_service
          if @new_resource.reload_command
            shell_out!(@new_resource.reload_command)
          else
            shell_out!("#{@invokercd_init_command} reload")
          end
        end

        protected
          def determine_current_status!
            if @new_resource.status_command
              Chef::Log.debug("#{@new_resource} you have specified a status command, running..")

              begin
                if shell_out(@new_resource.status_command).exitstatus == 0
                  @current_resource.running true
                  Chef::Log.debug("#{@new_resource} is running")
                end
              rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
              # ShellOut sometimes throws different types of Exceptions than ShellCommandFailed.
              # Temporarily catching different types of exceptions here until we get Shellout fixed.
              # TODO: Remove the line before one we get the ShellOut fix.
                @status_load_success = false
                @current_resource.running false
                nil
              end

            elsif @new_resource.supports[:status]
              Chef::Log.debug("#{@new_resource} supports status, running")
              begin
                if shell_out("#{@invokercd_init_command} status").exitstatus == 0
                  @current_resource.running true
                  Chef::Log.debug("#{@new_resource} is running")
                end
              # ShellOut sometimes throws different types of Exceptions than ShellCommandFailed.
              # Temporarily catching different types of exceptions here until we get Shellout fixed.
              # TODO: Remove the line before one we get the ShellOut fix.
              rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
                @status_load_success = false
                @current_resource.running false
                nil
              end
            else
              Chef::Log.debug "#{@new_resource} falling back to process table inspection"
              r = Regexp.new(@new_resource.pattern)
              Chef::Log.debug "#{@new_resource} attempting to match '#{@new_resource.pattern}' (#{r.inspect}) against process list"
              begin
                shell_out!(ps_cmd).stdout.each_line do |line|
                  if r.match(line)
                    @current_resource.running true
                    break
                  end
                end

                @current_resource.running false unless @current_resource.running
                Chef::Log.debug "#{@new_resource} running: #{@current_resource.running}"
              # ShellOut sometimes throws different types of Exceptions than ShellCommandFailed.
              # Temporarily catching different types of exceptions here until we get Shellout fixed.
              # TODO: Remove the line before one we get the ShellOut fix.
              rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
                @ps_command_failed = true
              end
            end
          end
      end
    end
  end
end
