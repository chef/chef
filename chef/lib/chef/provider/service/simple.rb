#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Copyright:: Copyright (c) 2009 Mathieu Sauve-Frankel
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

require 'chef/mixin/shell_out'
require 'chef/provider/service'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Simple < Chef::Provider::Service

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          determine_current_status!

          @current_resource
        end

        def start_service
          if @new_resource.start_command
            shell_out!(@new_resource.start_command)
          else
            raise Chef::Exceptions::Service, "#{self.to_s} requires that start_command to be set"
          end
        end

        def stop_service
          if @new_resource.stop_command
            shell_out!(@new_resource.stop_command)
          else
            raise Chef::Exceptions::Service, "#{self.to_s} requires that stop_command to be set"
          end
        end

        def restart_service
          if @new_resource.restart_command
            shell_out!(@new_resource.restart_command)
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def reload_service
          if @new_resource.reload_command
            shell_out!(@new_resource.reload_command)
          else
            raise Chef::Exceptions::Service, "#{self.to_s} requires that reload_command to be set"
          end
        end

      protected
        def determine_current_status!
          @current_resource.running service_running?
          Chef::Log.debug "#{@new_resource} running #{@current_resource.running}"
        end

        def service_running?
          return exec_status_cmd! == 0 if status_cmd
          return service_running_in_ps?
        end

        def service_running_in_ps?
          Chef::Log.debug "#{@new_resource} falling back to process table inspection"
          raise Chef::Exceptions::Service, "#{@new_resource} could not determine how to inspect the process table, please set this nodes 'command.ps' attribute" if ps_cmd.nil? or ps_cmd.empty?

          r = Regexp.new(@new_resource.pattern)
          Chef::Log.debug "#{@new_resource} attempting to match '#{@new_resource.pattern}' (#{r.inspect}) against process list"
          begin
            exec_ps_cmd!.stdout.each_line { |line| return true if r.match(line) }
            return false
          rescue Mixlib::ShellOut::ShellCommandFailed
            raise Chef::Exceptions::Service, "Command #{ps_cmd} failed"
          end
        end

        def exec_status_cmd!
          return false unless shell_out!(status_cmd).exitstatus == 0
          Chef::Log.debug("#{@new_resource} is running")
          true
        rescue Mixlib::ShellOut::ShellCommandFailed
          false
        end

        def status_cmd
          @_status_command ||= if @new_resource.status_command
                                 Chef::Log.debug("#{@new_resource} you have specified a status command, running..")
                                 @new_resource.status_command
                               elsif @new_resource.supports[:status]
                                 Chef::Log.debug("#{@new_resource} supports status, running")
                                 "#{@init_command} status"
                               else
                                 nil
                               end
        end

        def exec_ps_cmd!
          shell_out!(ps_cmd)
        end

        def ps_cmd
          @run_context.node[:command] && @run_context.node[:command][:ps]
        end
      end
    end
  end
end
