#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2010-2016, Bryan McLellan
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

require_relative "../../resource/service"
require_relative "simple"
require_relative "../../util/file_edit"

class Chef
  class Provider
    class Service
      class Upstart < Chef::Provider::Service::Simple

        # to maintain a local state of service across restart's internal calls
        attr_accessor :upstart_service_running

        UPSTART_STATE_FORMAT = %r{\S+ \(?(start|stop)?\)? ?[/ ](\w+)}.freeze

        # Returns true if the configs for the service name has upstart variable
        def self.supports?(resource, action)
          service_script_exist?(:upstart, resource.service_name)
        end

        # Upstart does more than start or stop a service, creating multiple 'states' [1] that a service can be in.
        # In chef, when we ask a service to start, we expect it to have started before performing the next step
        # since we have top down dependencies. Which is to say we may follow with a resource next that requires
        # that service to be running. According to [2] we can trust that sending a 'goal' such as start will not
        # return until that 'goal' is reached, or some error has occurred.
        #
        # [1] http://upstart.ubuntu.com/wiki/JobStates
        # [2] http://www.netsplit.com/2008/04/27/upstart-05-events/

        def initialize(new_resource, run_context)
          # TODO: re-evaluate if this is needed after integrating cookbook fix
          raise ArgumentError, "run_context cannot be nil" unless run_context

          super

          run_context.node

          # dup so we can mutate @job
          @job = @new_resource.service_name.dup

          if @new_resource.parameters
            @new_resource.parameters.each do |key, value|
              @job << " #{key}=#{value}"
            end
          end

          @upstart_job_dir = "/etc/init"
          @upstart_conf_suffix = ".conf"
          @command_success = true # new_resource.status_command= false, means upstart used
          @config_file_found = true
          @upstart_command_success = true
        end

        def define_resource_requirements
          # Do not call super, only call shared requirements
          shared_resource_requirements
          requirements.assert(:all_actions) do |a|
            unless @command_success
              whyrun_msg = if @new_resource.status_command
                             "Provided status command #{@new_resource.status_command} failed."
                           else
                             "Could not determine upstart state for service"
                           end
            end
            a.assertion { @command_success }
            # no failure here, just document the assumptions made.
            a.whyrun "#{whyrun_msg} Assuming service installed and not running."
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @config_file_found }
            # no failure here, just document the assumptions made.
            a.whyrun "Could not find #{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}. Assuming service is disabled."
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          # Get running/stopped state
          # We do not support searching for a service via ps when using upstart since status is a native
          # upstart function. We will however support status_command in case someone wants to do something special.
          if @new_resource.status_command
            logger.trace("#{@new_resource} you have specified a status command, running..")

            begin
              if shell_out!(@new_resource.status_command).exitstatus == 0
                @upstart_service_running = true
              end
            rescue
              @command_success = false
              @upstart_service_running = false
              nil
            end
          else
            begin
              if upstart_goal_state == "start"
                @upstart_service_running = true
              else
                @upstart_service_running = false
              end
            rescue Chef::Exceptions::Exec
              @command_success = false
              @upstart_service_running = false
              nil
            end
          end
          # Get enabled/disabled state by reading job configuration file
          if ::File.exist?("#{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}")
            logger.trace("#{@new_resource} found #{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}")
            ::File.open("#{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}", "r") do |file|
              while line = file.gets
                case line
                when /^start on/
                  logger.trace("#{@new_resource} enabled: #{line.chomp}")
                  @current_resource.enabled true
                  break
                when /^#start on/
                  logger.trace("#{@new_resource} disabled: #{line.chomp}")
                  @current_resource.enabled false
                  break
                end
              end
            end
          else
            @config_file_found = false
            logger.trace("#{@new_resource} did not find #{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}")
            @current_resource.enabled false
          end

          @current_resource.running @upstart_service_running
          @current_resource
        end

        def start_service
          # Calling start on a service that is already started will return 1
          # Our 'goal' when we call start is to ensure the service is started
          if @upstart_service_running
            logger.trace("#{@new_resource} already running, not starting")
          else
            if @new_resource.start_command
              super
            else
              shell_out!("/sbin/start #{@job}", default_env: false)
            end
          end

          @upstart_service_running = true
        end

        def stop_service
          # Calling stop on a service that is already stopped will return 1
          # Our 'goal' when we call stop is to ensure the service is stopped
          unless @upstart_service_running
            logger.trace("#{@new_resource} not running, not stopping")
          else
            if @new_resource.stop_command
              super
            else
              shell_out!("/sbin/stop #{@job}", default_env: false)
            end
          end

          @upstart_service_running = false
        end

        def restart_service
          if @new_resource.restart_command
            super
          # Upstart always provides restart functionality so we don't need to mimic it with stop/sleep/start.
          # Older versions of upstart would fail on restart if the service was currently stopped, check for that. LP:430883
          # But for safe working of latest upstart job config being loaded, 'restart' can't be used as per link
          # http://upstart.ubuntu.com/cookbook/#restart (it doesn't uses latest jon config from disk but retains old)
          else
            if @upstart_service_running
              stop_service
              sleep 1
              start_service
            else
              start_service
            end
          end

          @upstart_service_running = true
        end

        def reload_service
          if @new_resource.reload_command
            super
          else
            # upstart >= 0.6.3-4 supports reload (HUP)
            shell_out!("/sbin/reload #{@job}", default_env: false)
          end

          @upstart_service_running = true
        end

        # https://bugs.launchpad.net/upstart/+bug/94065

        def enable_service
          logger.trace("#{@new_resource} upstart lacks inherent support for enabling services, editing job config file")
          conf = Chef::Util::FileEdit.new("#{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}")
          conf.search_file_replace(/^#start on/, "start on")
          conf.write_file
        end

        def disable_service
          logger.trace("#{@new_resource} upstart lacks inherent support for disabling services, editing job config file")
          conf = Chef::Util::FileEdit.new("#{@upstart_job_dir}/#{@new_resource.service_name}#{@upstart_conf_suffix}")
          conf.search_file_replace(/^start on/, "#start on")
          conf.write_file
        end

        def upstart_goal_state
          command = "/sbin/status #{@job}"
          so = shell_out(command)
          so.stdout.each_line do |line|
            # service goal/state
            # OR
            # service (instance) goal/state
            # OR
            # service (goal) state
            line =~ UPSTART_STATE_FORMAT
            data = Regexp.last_match
            return data[1]
          end
        end

      end
    end
  end
end
