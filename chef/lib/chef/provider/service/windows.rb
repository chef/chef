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

require 'chef/mixin/shell_out'
require 'chef/provider/service/simple'
if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require 'win32/service'
end

class Chef::Provider::Service::Windows < Chef::Provider::Service

  include Chef::Mixin::ShellOut

  RUNNING = 'running'
  STOPPED = 'stopped'
  AUTO_START = 'auto start'
  DISABLED = 'disabled'

  def whyrun_supported?
    false
  end

  def load_current_resource
    @current_resource = Chef::Resource::Service.new(@new_resource.name)
    @current_resource.service_name(@new_resource.service_name)
    @current_resource.running(current_state == RUNNING)
    Chef::Log.debug "#{@new_resource} running: #{@current_resource.running}"
    @current_resource.enabled(start_type == AUTO_START)
    Chef::Log.debug "#{@new_resource} enabled: #{@current_resource.enabled}"
    @current_resource
  end

  def start_service
    if Win32::Service.exists?(@new_resource.service_name)
      if current_state == RUNNING
        Chef::Log.debug "#{@new_resource} already started - nothing to do"
      else
        if @new_resource.start_command
          Chef::Log.debug "#{@new_resource} starting service using the given start_command"
          shell_out!(@new_resource.start_command)
        else
          spawn_command_thread do
            Win32::Service.start(@new_resource.service_name)
            wait_for_state(RUNNING)
          end
        end
        @new_resource.updated_by_last_action(true)
      end
    else
        Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def stop_service
    if Win32::Service.exists?(@new_resource.service_name)
      if current_state == RUNNING
        if @new_resource.stop_command
          Chef::Log.debug "#{@new_resource} stopping service using the given stop_command"
          shell_out!(@new_resource.stop_command)
        else
          spawn_command_thread do
            Win32::Service.stop(@new_resource.service_name)
            wait_for_state(STOPPED)
          end
        end
        @new_resource.updated_by_last_action(true)
      else
        Chef::Log.debug "#{@new_resource} already stopped - nothing to do"
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

  def enable_service
    if Win32::Service.exists?(@new_resource.service_name)
      if start_type == AUTO_START
        Chef::Log.debug "#{@new_resource} already enabled - nothing to do"
      else
        Win32::Service.configure(
          :service_name => @new_resource.service_name,
          :start_type => Win32::Service::AUTO_START
        )
        @new_resource.updated_by_last_action(true)
      end
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def disable_service
    if Win32::Service.exists?(@new_resource.service_name)
      if start_type == AUTO_START
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
    sleep 1 until current_state == desired_state
  end

  # There ain't no party like a thread party...
  def spawn_command_thread
    worker = Thread.new do
      yield
    end
    Timeout.timeout(60) do
      worker.join
    end
  end
end
