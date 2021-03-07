#
# Author:: Nuo Yan <nuo@chef.io>
# Author:: Bryan McLellan <btm@loftninjas.org>
# Author:: Seth Chisamore <schisamo@chef.io>
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

require_relative "simple"
require_relative "../../win32_service_constants"
if RUBY_PLATFORM.match?(/mswin|mingw32|windows/)
  require_relative "../../win32/error"
  require "win32/service"
end

class Chef::Provider::Service::Windows < Chef::Provider::Service
  provides :service, os: "windows"
  provides :windows_service

  include Chef::Mixin::ShellOut
  include Chef::ReservedNames::Win32::API::Error rescue LoadError
  include Chef::Win32ServiceConstants

  # Win32::Service.get_start_type
  AUTO_START = "auto start".freeze
  MANUAL = "demand start".freeze
  DISABLED = "disabled".freeze

  # Win32::Service.get_current_state
  RUNNING = "running".freeze
  STOPPED = "stopped".freeze
  CONTINUE_PENDING = "continue pending".freeze
  PAUSE_PENDING = "pause pending".freeze
  PAUSED = "paused".freeze
  START_PENDING = "start pending".freeze
  STOP_PENDING  = "stop pending".freeze

  SERVICE_RIGHT = "SeServiceLogonRight".freeze

  def load_current_resource
    @current_resource = Chef::Resource::WindowsService.new(new_resource.name)
    current_resource.service_name(new_resource.service_name)

    if Win32::Service.exists?(current_resource.service_name)
      current_resource.running(current_state == RUNNING)
      logger.trace "#{new_resource} running: #{current_resource.running}"
      case current_startup_type
      when :automatic
        current_resource.enabled(true)
      when :disabled
        current_resource.enabled(false)
      end
      logger.trace "#{new_resource} enabled: #{current_resource.enabled}"

      config_info = Win32::Service.config_info(current_resource.service_name)
      current_resource.service_type(get_service_type(config_info.service_type))    if config_info.service_type
      current_resource.startup_type(start_type_to_sym(config_info.start_type))     if config_info.start_type
      current_resource.error_control(get_error_control(config_info.error_control)) if config_info.error_control
      current_resource.binary_path_name(config_info.binary_path_name) if config_info.binary_path_name
      current_resource.load_order_group(config_info.load_order_group) if config_info.load_order_group
      current_resource.dependencies(config_info.dependencies)         if config_info.dependencies
      current_resource.run_as_user(config_info.service_start_name)    if config_info.service_start_name
      current_resource.display_name(config_info.display_name)         if config_info.display_name
      current_resource.delayed_start(current_delayed_start)           if current_delayed_start
    end

    current_resource
  end

  def start_service
    if Win32::Service.exists?(@new_resource.service_name)
      configure_service_run_as_properties

      state = current_state
      if state == RUNNING
        logger.debug "#{@new_resource} already started - nothing to do"
      elsif state == START_PENDING
        logger.trace "#{@new_resource} already sent start signal - waiting for start"
        wait_for_state(RUNNING)
      elsif state == STOPPED
        if @new_resource.start_command
          logger.trace "#{@new_resource} starting service using the given start_command"
          shell_out!(@new_resource.start_command)
        else
          spawn_command_thread do

            Win32::Service.start(@new_resource.service_name)
          rescue SystemCallError => ex
            if ex.errno == ERROR_SERVICE_LOGON_FAILED
              logger.error ex.message
              raise Chef::Exceptions::Service,
                "Service #{@new_resource} did not start due to a logon failure (error #{ERROR_SERVICE_LOGON_FAILED}): possibly the specified user '#{@new_resource.run_as_user}' does not have the 'log on as a service' privilege, or the password is incorrect."
            else
              raise ex
            end

          end
          wait_for_state(RUNNING)
        end
        @new_resource.updated_by_last_action(true)
      else
        raise Chef::Exceptions::Service, "Service #{@new_resource} can't be started from state [#{state}]"
      end
    else
      logger.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def stop_service
    if Win32::Service.exists?(@new_resource.service_name)
      state = current_state
      if state == RUNNING
        if @new_resource.stop_command
          logger.trace "#{@new_resource} stopping service using the given stop_command"
          shell_out!(@new_resource.stop_command)
        else
          spawn_command_thread do
            Win32::Service.stop(@new_resource.service_name)
          end
          wait_for_state(STOPPED)
        end
        @new_resource.updated_by_last_action(true)
      elsif state == STOPPED
        logger.debug "#{@new_resource} already stopped - nothing to do"
      elsif state == STOP_PENDING
        logger.trace "#{@new_resource} already sent stop signal - waiting for stop"
        wait_for_state(STOPPED)
      else
        raise Chef::Exceptions::Service, "Service #{@new_resource} can't be stopped from state [#{state}]"
      end
    else
      logger.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def restart_service
    if Win32::Service.exists?(@new_resource.service_name)
      if @new_resource.restart_command
        logger.trace "#{@new_resource} restarting service using the given restart_command"
        shell_out!(@new_resource.restart_command)
      else
        stop_service
        start_service
      end
      @new_resource.updated_by_last_action(true)
    else
      logger.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def enable_service
    if Win32::Service.exists?(@new_resource.service_name)
      set_startup_type(:automatic)
    else
      logger.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def disable_service
    if Win32::Service.exists?(@new_resource.service_name)
      set_startup_type(:disabled)
    else
      logger.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  action :create do
    if Win32::Service.exists?(new_resource.service_name)
      logger.debug "#{new_resource} already exists - nothing to do"
      return
    end

    converge_by("create service #{new_resource.service_name}") do
      Win32::Service.new(windows_service_config)
    end

    converge_delayed_start
  end

  action :delete do
    unless Win32::Service.exists?(new_resource.service_name)
      logger.debug "#{new_resource} does not exist - nothing to do"
      return
    end

    converge_by("delete service #{new_resource.service_name}") do
      Win32::Service.delete(new_resource.service_name)
    end
  end

  action :configure do
    unless Win32::Service.exists?(new_resource.service_name)
      logger.warn "#{new_resource} does not exist. Maybe you need to prepend action :create"
      return
    end

    converge_if_changed :service_type, :startup_type, :error_control,
      :binary_path_name, :load_order_group, :dependencies,
      :run_as_user, :display_name, :description do
        Win32::Service.configure(windows_service_config(:configure))
      end

    converge_delayed_start
  end

  action :enable do
    if current_startup_type != :automatic
      converge_by("enable service #{@new_resource}") do
        enable_service
        logger.info("#{@new_resource} enabled")
      end
    else
      logger.debug("#{@new_resource} already enabled - nothing to do")
    end
    load_new_resource_state
    @new_resource.enabled(true)
  end

  action :disable do
    if current_startup_type != :disabled
      converge_by("disable service #{@new_resource}") do
        disable_service
        logger.info("#{@new_resource} disabled")
      end
    else
      logger.debug("#{@new_resource} already disabled - nothing to do")
    end
    load_new_resource_state
    @new_resource.enabled(false)
  end

  action :configure_startup do
    startup_type = @new_resource.startup_type
    if current_startup_type != startup_type
      converge_by("set service #{@new_resource} startup type to #{startup_type}") do
        set_startup_type(startup_type)
      end
    else
      logger.debug("#{@new_resource} startup_type already #{startup_type} - nothing to do")
    end

    converge_delayed_start

    # Avoid changing enabled from true/false for now
    @new_resource.enabled(nil)
  end

  private

  def configure_service_run_as_properties
    return unless new_resource.property_is_set?(:run_as_user)

    new_config = {
      service_name: new_resource.service_name,
      service_start_name: new_resource.run_as_user,
      password: new_resource.run_as_password,
    }.reject { |k, v| v.nil? || v.length == 0 }

    Win32::Service.configure(new_config)
    logger.info "#{new_resource} configured."

    grant_service_logon(new_resource.run_as_user) if new_resource.run_as_user != "localsystem"
  end

  #
  # Queries the delayed auto-start setting of the auto-start service. If
  # the service is not auto-start, this will return nil.
  #
  # @return [Boolean, nil]
  #
  def current_delayed_start
    case Win32::Service.delayed_start(new_resource.service_name)
    when 0
      false
    when 1
      true
    end
  end

  def grant_service_logon(username)
    return if Chef::ReservedNames::Win32::Security.get_account_right(canonicalize_username(username)).include?(SERVICE_RIGHT)

    begin
      Chef::ReservedNames::Win32::Security.add_account_right(canonicalize_username(username), SERVICE_RIGHT)
    rescue Chef::Exceptions::Win32APIError => err
      logger.fatal "Logon-as-service grant failed with output: #{err}"
      raise Chef::Exceptions::Service, "Logon-as-service grant failed for #{username}: #{err}"
    end

    logger.info "Grant logon-as-service to user '#{username}' successful."
    true
  end

  # remove characters that make for broken or wonky filenames.
  def clean_username_for_path(username)
    username.gsub(%r{[/\\. ]+}, "_")
  end

  def canonicalize_username(username)
    username.sub(/^\.?\\+/, "")
  end

  def current_state
    Win32::Service.status(@new_resource.service_name).current_state
  end

  def current_startup_type
    start_type = Win32::Service.config_info(@new_resource.service_name).start_type
    start_type_to_sym(start_type)
  end

  # Helper method that waits for a status to change its state since state
  # changes aren't usually instantaneous.
  def wait_for_state(desired_state)
    retries = 0
    loop do
      break if current_state == desired_state
      raise Timeout::Error if ( retries += 1 ) > @new_resource.timeout

      sleep 1
    end
  end

  def spawn_command_thread
    worker = Thread.new do
      yield
    end

    Timeout.timeout(@new_resource.timeout) do
      worker.join
    end
  end

  # @param type [Symbol]
  # @return [Integer]
  # @raise [Chef::Exceptions::ConfigurationError] if the startup type is
  #   not supported.
  # @see Chef::Resource::WindowsService::ALLOWED_START_TYPES
  def startup_type_to_int(type)
    Chef::Resource::WindowsService::ALLOWED_START_TYPES.fetch(type) do
      raise Chef::Exceptions::ConfigurationError, "#{@new_resource.name}: Startup type '#{type}' is not supported"
    end
  end

  # Takes Win32::Service start_types
  def set_startup_type(type)
    startup_type = startup_type_to_int(type)

    logger.trace "#{@new_resource.name} setting start_type to #{type}"
    Win32::Service.configure(
      service_name: @new_resource.service_name,
      start_type: startup_type
    )
    @new_resource.updated_by_last_action(true)
  end

  def windows_service_config(action = :create)
    config = {}

    config[:service_name]       = new_resource.service_name
    config[:display_name]       = new_resource.display_name                      if new_resource.display_name
    config[:service_type]       = new_resource.service_type                      if new_resource.service_type
    config[:start_type]         = startup_type_to_int(new_resource.startup_type) if new_resource.startup_type
    config[:error_control]      = new_resource.error_control                     if new_resource.error_control
    config[:binary_path_name]   = new_resource.binary_path_name                  if new_resource.binary_path_name
    config[:load_order_group]   = new_resource.load_order_group                  if new_resource.load_order_group
    config[:dependencies]       = new_resource.dependencies                      if new_resource.dependencies
    config[:service_start_name] = new_resource.run_as_user                       unless new_resource.run_as_user.empty?
    config[:password]           = new_resource.run_as_password                   unless new_resource.run_as_user.empty? || new_resource.run_as_password.empty?
    config[:description]        = new_resource.description                       if new_resource.description

    case action
    when :create
      config[:desired_access] = new_resource.desired_access if new_resource.desired_access
    end

    config
  end

  def converge_delayed_start
    converge_if_changed :delayed_start do
      config = {}
      config[:service_name]  = new_resource.service_name
      config[:delayed_start] = new_resource.delayed_start ? 1 : 0

      Win32::Service.configure(config)
    end
  end

  # @return [Symbol]
  def start_type_to_sym(start_type)
    case start_type
    when "auto start"
      :automatic
    when "boot start"
      raise("Unsupported start type, #{start_type}. Submit bug request to fix.")
    when "demand start"
      :manual
    when "disabled"
      :disabled
    when "system start"
      raise("Unsupported start type, #{start_type}. Submit bug request to fix.")
    else
      raise("Unsupported start type, #{start_type}. Submit bug request to fix.")
    end
  end

  def get_service_type(service_type)
    case service_type
    when "file system driver"
      SERVICE_FILE_SYSTEM_DRIVER
    when "kernel driver"
      SERVICE_KERNEL_DRIVER
    when "own process"
      SERVICE_WIN32_OWN_PROCESS
    when "share process"
      SERVICE_WIN32_SHARE_PROCESS
    when "recognizer driver"
      SERVICE_RECOGNIZER_DRIVER
    when "driver"
      SERVICE_DRIVER
    when "win32"
      SERVICE_WIN32
    when "all"
      SERVICE_TYPE_ALL
    when "own process, interactive"
      SERVICE_INTERACTIVE_PROCESS | SERVICE_WIN32_OWN_PROCESS
    when "share process, interactive"
      SERVICE_INTERACTIVE_PROCESS | SERVICE_WIN32_SHARE_PROCESS
    else
      raise("Unsupported service type, #{service_type}. Submit bug request to fix.")
    end
  end

  # @return [Integer]
  def get_start_type(start_type)
    case start_type
    when "auto start"
      SERVICE_AUTO_START
    when "boot start"
      SERVICE_BOOT_START
    when "demand start"
      SERVICE_DEMAND_START
    when "disabled"
      SERVICE_DISABLED
    when "system start"
      SERVICE_SYSTEM_START
    else
      raise("Unsupported start type, #{start_type}. Submit bug request to fix.")
    end
  end

  def get_error_control(error_control)
    case error_control
    when "critical"
      SERVICE_ERROR_CRITICAL
    when "ignore"
      SERVICE_ERROR_IGNORE
    when "normal"
      SERVICE_ERROR_NORMAL
    when "severe"
      SERVICE_ERROR_SEVERE
    else
      nil
    end
  end

end
