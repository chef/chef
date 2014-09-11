#
# Author:: kaustubh (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/provider/service/init'

class Chef
  class Provider
    class Service
      class Aix < Chef::Provider::Service
        attr_reader :status_load_success

        def initialize(new_resource, run_context)
          super
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          @status_load_success = true
          @priority_success = true
          @is_resource_group = false

          determine_current_status!
          is_resource_group?

          @current_resource
        end

        def whyrun_supported?
          true
        end

        def start_service
          if @new_resource.start_command
            shell_out(@new_resource.start_command)
          elsif @is_resource_group
            shell_out!("startsrc -g #{@new_resource.service_name}")
          else
            shell_out!("startsrc -s #{@new_resource.service_name}")
          end
        end

        def stop_service
          if @new_resource.stop_command
            shell_out(@new_resource.start_command)
          elsif @is_resource_group
            shell_out!("stopsrc -g #{@new_resource.service_name}")
          else
            shell_out!("stopsrc -s #{@new_resource.service_name}")
          end
        end

        def restart_service
          stop_service
          start_service
        end

        def reload_service
          if @new_resource.reload_command
            shell_out(@new_resource.start_command)
          elsif @is_resource_group
            shell_out!("refresh -g #{@new_resource.service_name}")
          else
            shell_out!("refresh -s #{@new_resource.service_name}")
          end
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
        end

        protected
          def determine_current_status!
            if @new_resource.status_command
              Chef::Log.debug("#{@new_resource} you have specified a status command, running..")

              begin
                if shell_out(@new_resource.status_command).exitstatus == 0
                  @current_resource.running(true)
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
            else
              Chef::Log.debug "#{@new_resource} using lssrc to check the status "
              begin
                if shell_out!("lssrc -a | grep #{@new_resource}").stdout.split(' ')[3] == "active"
                  @current_resource.runing(true)
                else
                  @current_resource.running false
                end
                Chef::Log.debug "#{@new_resource} running: #{@current_resource.running}"
              # ShellOut sometimes throws different types of Exceptions than ShellCommandFailed.
              # Temporarily catching different types of exceptions here until we get Shellout fixed.
              # TODO: Remove the line before one we get the ShellOut fix.
              rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError
                @status_load_success = false
                @current_resource.running false
                nil
              end
            end
          end

          def is_resource_group?
            if shell_out!("lssrc -a | grep #{@new_resource}").stdout.split(' ')[1] != ""
              @is_resource_group = true
            end
          end
        end
      end
    end
  end
end

