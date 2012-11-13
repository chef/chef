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

        include Chef::Mixin::ShellOut

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          @status_load_success = true
          @ps_command_failed = false

          determine_current_status!

          @current_resource
        end

        def whyrun_supported?
          true
        end

        def shared_resource_requirements
          super
          requirements.assert(:all_actions) do |a| 
            a.assertion { @status_load_success } 
            a.whyrun ["Service status not available. Assuming a prior action would have installed the service.", "Assuming status of not running."]
          end
        end

        def define_resource_requirements
          # FIXME? need reload from service.rb
          shared_resource_requirements
          requirements.assert(:start) do |a|
            a.assertion { @new_resource.start_command }
            a.failure_message Chef::Exceptions::Service, "#{self.to_s} requires that start_command be set"
          end
          requirements.assert(:stop) do |a|
            a.assertion { @new_resource.stop_command }
            a.failure_message Chef::Exceptions::Service, "#{self.to_s} requires that stop_command be set"
          end

          requirements.assert(:restart) do |a|
            a.assertion { @new_resource.restart_command  || ( @new_resource.start_command && @new_resource.stop_command ) }
            a.failure_message Chef::Exceptions::Service, "#{self.to_s} requires a restart_command or both start_command and stop_command be set in order to perform a restart"
          end

          requirements.assert(:reload) do |a|
            a.assertion { @new_resource.reload_command }
            a.failure_message Chef::Exceptions::UnsupportedAction, "#{self.to_s} requires a reload_command be set in order to perform a reload"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @new_resource.status_command or @new_resource.supports[:status] or 
              (!ps_cmd.nil? and !ps_cmd.empty?) } 
            a.failure_message Chef::Exceptions::Service, "#{@new_resource} could not determine how to inspect the process table, please set this node's 'command.ps' attribute"
          end
          requirements.assert(:all_actions) do |a| 
            a.assertion { !@ps_command_failed } 
            a.failure_message Chef::Exceptions::Service, "Command #{ps_cmd} failed to execute, cannot determine service current status"
          end
        end

        def start_service
          shell_out!(@new_resource.start_command)
        end

        def stop_service
          shell_out!(@new_resource.stop_command)
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
          shell_out!(@new_resource.reload_command)
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
              if shell_out("#{default_init_command} status").exitstatus == 0
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

        def ps_cmd
          @run_context.node[:command] && @run_context.node[:command][:ps]
        end
      end
    end
  end
end
