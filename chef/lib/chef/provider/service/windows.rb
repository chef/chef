#
# Author:: Nuo Yan <nuo@opscode.com>
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2010 Opscode, Inc
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

# pick up popen4 from chef/mixin/command/windows
require 'chef/mixin/command'
require 'chef/provider/service/simple'

class Chef::Provider::Service::Windows < Chef::Provider::Service::Simple

  def initialize(new_resource, run_context)
    super
    @init_command = "sc"
  end

  def io_popen(command)
    io = IO.popen(command)
    entries = io.readlines
    io.close
    entries
  end

  def load_current_resource
    @current_resource = Chef::Resource::Service.new(@new_resource.name)
    @current_resource.service_name(@new_resource.service_name)
    begin
      # Check if service is running
      status = popen4("#{@init_command} query #{@new_resource.service_name}") do |pid, stdin, stdout, stderr|
        stdout.each_line do |line|
          raise Chef::Exceptions::Service, "Service #{@new_resource.service_name} does not exist.\n#{stdout}\n" if line =~ /FAILED 1060/
          @current_resource.running true if line =~/RUNNING/
        end
      end

      # Check if service is enabled
      status = popen4("#{@init_command} qc #{@new_resource.service_name}") do |pid, stdin, stdout, stderr|
        stdout.each_line do |line|
          raise Chef::Exceptions::Service, "Service #{@new_resource.service_name} does not exist.\n#{stdout}\n" if line =~ /FAILED 1060/
          @current_resource.enabled true if line =~/AUTO_START/
        end
      end

      Chef::Log.debug "#{@new_resource} running: #{@current_resource.running}"
    rescue Exception => e
      raise Chef::Exceptions::Service, "Exception determining state of service #{@new_resource.service_name}: #{e.message}"
    end
    @current_resource
  end

  def start_service
    begin
      if @new_resource.start_command
        popen4(@new_resource.start_command) do |pid, stdin, stdout, stderr|
          Chef::Log.debug stdout.readlines
        end
      else
        popen4("#{@init_command} start #{@new_resource.service_name}") do |pid, stdin, stdout, stderr|
          output = stdout.readlines
          Chef::Log.debug output.join
          output.join =~ /RUNNING/ || output.join =~ /START_PENDING/ ? true : false
        end
      end
    rescue Exception => e
      raise Chef::Exceptions::Service, "Failed to start service #{@new_resource.service_name}: #{e.message}"
    end
  end

  def stop_service
    begin
      if @new_resource.stop_command
        Chef::Log.debug "#{@new_resource} stopping service using the given stop_command"
        popen4(@new_resource.stop_command) do |pid, stdin, stdout, stderr|
          Chef::Log.debug stdout.readlines
        end
      else
        popen4("#{@init_command} stop #{@new_resource.service_name}") do |pid, stdin, stdout, stderr|
          output = stdout.readlines
          Chef::Log.debug output.join
          raise Chef::Exceptions::Service, "Service #{@new_resource.service_name} has dependencies and cannot be stopped.\n" if output.join =~ /FAILED 1051/
          output.join =~ /1/
        end
      end
    rescue Exception => e
      raise Chef::Exceptions::Service, "Failed to start service #{@new_resource.service_name}: #{e.message}"
    end
  end

  def restart_service
    begin
      if @new_resource.restart_command
        Chef::Log.debug "#{@new_resource} restarting service using the given restart_command"
        popen4(@new_resource.restart_command) do |pid, stdin, stdout, stderr|
          Chef::Log.debug stdout.readlines
        end
      else
        stop_service
        sleep 1
        start_service
      end
    rescue Exception => e
      raise Chef::Exceptions::Service, "Failed to start service #{@new_resource.service_name}: #{e.message}"
    end
  end

  def enable_service()
    begin
      popen4("#{@init_command} config #{@new_resource.service_name} start= #{determine_startup_type}") do |pid, stdin, stdout, stderr|
        stdout.readlines.join =~ /SUCCESS/
      end
    rescue Exception => e
      raise Chef::Exceptions::Service, "Failed to start service #{@new_resource.service_name}: #{e.message}"
    end
  end

  def disable_service()
    begin
      popen4("#{@init_command} config #{@new_resource.service_name} start= disabled") do |pid, stdin, stdout, stderr|
        stdout.readlines.join =~ /SUCCESS/
      end
    rescue Exception => e
      raise Chef::Exceptions::Service, "Failed to start service #{@new_resource.service_name}: #{e.message}"
    end
  end

  private

  def determine_startup_type
    {:automatic => 'auto', :mannual => 'demand'}[@new_resource.startup_type]
  end

end
