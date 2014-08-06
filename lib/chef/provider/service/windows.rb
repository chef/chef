#
# Author:: Nuo Yan <nuo@opscode.com>
# Author:: Bryan McLellan <btm@loftninjas.org>
# Author:: Seth Chisamore <schisamo@opscode.com>
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc
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

require 'chef/provider/service/simple'
if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require 'win32/service'
end

class Chef::Provider::Service::Windows < Chef::Provider::Service

  #Win32::Service.get_start_type
  AUTO_START = 'auto start'
  MANUAL = 'demand start'
  DISABLED = 'disabled'

  #Win32::Service.get_current_state
  RUNNING = 'running'
  STOPPED = 'stopped'
  CONTINUE_PENDING = 'continue pending'
  PAUSE_PENDING = 'pause pending'
  PAUSED = 'paused'
  START_PENDING = 'start pending'
  STOP_PENDING  = 'stop pending'

  TIMEOUT  = 60

  def whyrun_supported?
    false
  end

  def load_current_resource
    @current_resource = Chef::Resource::WindowsService.new(@new_resource.name)
    @current_resource.service_name(@new_resource.service_name)
    @current_resource.running(current_state == RUNNING)
    Chef::Log.debug "#{@new_resource} running: #{@current_resource.running}"
    @current_resource.enabled(start_type != DISABLED)
    Chef::Log.debug "#{@new_resource} enabled: #{@current_resource.enabled}"
    @current_resource
  end

  def start_service
    if Win32::Service.exists?(@new_resource.service_name)
      state = current_state
      if state == RUNNING
        Chef::Log.debug "#{@new_resource} already started - nothing to do"
      elsif state == START_PENDING
        Chef::Log.debug "#{@new_resource} already sent start signal - waiting for start"
        wait_for_state(RUNNING)
      elsif state == STOPPED
        if @new_resource.start_command
          Chef::Log.debug "#{@new_resource} starting service using the given start_command"
          shell_out!(@new_resource.start_command)
        else
          spawn_command_thread do
            Win32::Service.start(@new_resource.service_name)
          end
          wait_for_state(RUNNING)
        end
        @new_resource.updated_by_last_action(true)
      else
        raise Chef::Exceptions::Service, "Service #{@new_resource} can't be started from state [#{state}]"
      end
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def stop_service
    if Win32::Service.exists?(@new_resource.service_name)
      state = current_state
      if state == RUNNING
        if @new_resource.stop_command
          Chef::Log.debug "#{@new_resource} stopping service using the given stop_command"
          shell_out!(@new_resource.stop_command)
        else
          spawn_command_thread do
            Win32::Service.stop(@new_resource.service_name)
          end
          wait_for_state(STOPPED)
        end
        @new_resource.updated_by_last_action(true)
      elsif state == STOPPED
        Chef::Log.debug "#{@new_resource} already stopped - nothing to do"
      elsif state == STOP_PENDING
        Chef::Log.debug "#{@new_resource} already sent stop signal - waiting for stop"
        wait_for_state(STOPPED)
      else
        raise Chef::Exceptions::Service, "Service #{@new_resource} can't be stopped from state [#{state}]"
      end
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def restart_service
    if Win32::Service.exists?(@new_resource.service_name)
      if @new_resource.restart_command
        Chef::Log.debug "#{@new_resource} restarting service using the given restart_command"
        shell_out!(@new_resource.restart_command)
      else
        stop_service
        start_service
      end
      @new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def action_enable
    # Ensure the service is enabled using the specified startup_type
    if (not @current_resource.enabled) || (@current_resource.enabled && should_update_startup_type?)
      converge_by("enable service #{@new_resource}") do
        enable_service
        Chef::Log.info("#{@new_resource} enabled, startup_type: #{@new_resource.startup_type}")
      end
    else
      Chef::Log.debug("#{@new_resource} already enabled - nothing to do")
    end
    load_new_resource_state
    @new_resource.enabled(true)
  end

  def enable_service
    if Win32::Service.exists?(@new_resource.service_name)
      case @new_resource.startup_type
      when :automatic
        win32_service_startup_type = Win32::Service::AUTO_START
      when :manual
        win32_service_startup_type = Win32::Service::MANUAL
      end

      Win32::Service.configure(
        :service_name => @new_resource.service_name,
        :start_type => win32_service_startup_type
      )
      @new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def disable_service
    if Win32::Service.exists?(@new_resource.service_name)
      if start_type != DISABLED
        Win32::Service.configure(
          :service_name => @new_resource.service_name,
          :start_type => Win32::Service::DISABLED
        )
        @new_resource.updated_by_last_action(true)
      else
        Chef::Log.debug "#{@new_resource} already disabled - nothing to do"
      end
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  private
  def current_state
    Win32::Service.status(@new_resource.service_name).current_state
  end

  def start_type
    Win32::Service.config_info(@new_resource.service_name).start_type
  end

  # Helper method that waits for a status to change its state since state
  # changes aren't usually instantaneous.
  def wait_for_state(desired_state)
    retries = 0
    loop do
      break if current_state == desired_state
      raise Timeout::Error if ( retries += 1 ) > resource_timeout
      sleep 1
    end
  end

  def resource_timeout
    @resource_timeout ||= @new_resource.timeout || TIMEOUT
  end

  def spawn_command_thread
    worker = Thread.new do
      yield
    end

    Timeout.timeout(resource_timeout) do
      worker.join
    end
  end

  def should_update_startup_type?
    # We could check :disabled too, but we're dedicating action_disable to that
    return true if @new_resource.startup_type == :automatic && start_type != AUTO_START
    return true if @new_resource.startup_type == :manual && start_type != MANUAL

    false
  end
end
