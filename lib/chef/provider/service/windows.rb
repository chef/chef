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
  require 'chef/win32/error'
  require 'win32/service'
end

class Chef::Provider::Service::Windows < Chef::Provider::Service
  provides :service, os: "windows"
  provides :windows_service, os: "windows"

  include Chef::Mixin::ShellOut
  include Chef::ReservedNames::Win32::API::Error rescue LoadError

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
    case current_start_type
    when AUTO_START
      @current_resource.enabled(true)
    when DISABLED
      @current_resource.enabled(false)
    end
    Chef::Log.debug "#{@new_resource} enabled: #{@current_resource.enabled}"
    @current_resource
  end

  def start_service
    if Win32::Service.exists?(@new_resource.service_name)
      # reconfiguration is idempotent, so just do it.
      new_config = {
        service_name: @new_resource.service_name,
        service_start_name: @new_resource.run_as_user,
        password: @new_resource.run_as_password,
      }.reject { |k,v| v.nil? || v.length == 0 }

      Win32::Service.configure(new_config)
      Chef::Log.info "#{@new_resource} configured with #{new_config.inspect}"

      # it would be nice to check if the user already has the logon privilege, but that turns out to be
      # nontrivial.
      if new_config.has_key?(:service_start_name)
        grant_service_logon(new_config[:service_start_name])
      end

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
            begin
              Win32::Service.start(@new_resource.service_name)
            rescue SystemCallError => ex
              if ex.errno == ERROR_SERVICE_LOGON_FAILED
                Chef::Log.error ex.message
                raise Chef::Exceptions::Service,
                "Service #{@new_resource} did not start due to a logon failure (error #{ERROR_SERVICE_LOGON_FAILED}): possibly the specified user '#{@new_resource.run_as_user}' does not have the 'log on as a service' privilege, or the password is incorrect."
              else
                raise ex
              end
            end
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

  def enable_service
    if Win32::Service.exists?(@new_resource.service_name)
      set_startup_type(:automatic)
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def disable_service
    if Win32::Service.exists?(@new_resource.service_name)
      set_startup_type(:disabled)
    else
      Chef::Log.debug "#{@new_resource} does not exist - nothing to do"
    end
  end

  def action_enable
    if current_start_type != AUTO_START
      converge_by("enable service #{@new_resource}") do
        enable_service
        Chef::Log.info("#{@new_resource} enabled")
      end
    else
      Chef::Log.debug("#{@new_resource} already enabled - nothing to do")
    end
    load_new_resource_state
    @new_resource.enabled(true)
  end

  def action_disable
    if current_start_type != DISABLED
      converge_by("disable service #{@new_resource}") do
        disable_service
        Chef::Log.info("#{@new_resource} disabled")
      end
    else
      Chef::Log.debug("#{@new_resource} already disabled - nothing to do")
    end
    load_new_resource_state
    @new_resource.enabled(false)
  end

  def action_configure_startup
    case @new_resource.startup_type
    when :automatic
      if current_start_type != AUTO_START
        converge_by("set service #{@new_resource} startup type to automatic") do
          set_startup_type(:automatic)
        end
      else
        Chef::Log.debug("#{@new_resource} startup_type already automatic - nothing to do")
      end
    when :manual
      if current_start_type != MANUAL
        converge_by("set service #{@new_resource} startup type to manual") do
          set_startup_type(:manual)
        end
      else
        Chef::Log.debug("#{@new_resource} startup_type already manual - nothing to do")
      end
    when :disabled
      if current_start_type != DISABLED
        converge_by("set service #{@new_resource} startup type to disabled") do
          set_startup_type(:disabled)
        end
      else
        Chef::Log.debug("#{@new_resource} startup_type already disabled - nothing to do")
      end
    end

    # Avoid changing enabled from true/false for now
    @new_resource.enabled(nil)
  end

  private
  def make_policy_text(username)
    text = <<-EOS
[Unicode]
Unicode=yes
[Privilege Rights]
SeServiceLogonRight = \\\\#{canonicalize_username(username)},*S-1-5-80-0
[Version]
signature="$CHICAGO$"
Revision=1
EOS
  end

  def grant_logfile_name(username)
    Chef::Util::PathHelper.canonical_path("#{Dir.tmpdir}/logon_grant-#{clean_username_for_path(username)}-#{$$}.log", prefix=false)
  end

  def grant_policyfile_name(username)
    Chef::Util::PathHelper.canonical_path("#{Dir.tmpdir}/service_logon_policy-#{clean_username_for_path(username)}-#{$$}.inf", prefix=false)
  end

  def grant_dbfile_name(username)
    "#{ENV['TEMP']}\\secedit.sdb"
  end

  def grant_service_logon(username)
    logfile = grant_logfile_name(username)
    policy_file = ::File.new(grant_policyfile_name(username), 'w')
    policy_text = make_policy_text(username)
    dbfile = grant_dbfile_name(username)        # this is just an audit file.

    begin
      Chef::Log.debug "Policy file text:\n#{policy_text}"
      policy_file.puts(policy_text)
      policy_file.close   # need to flush the buffer.

      # it would be nice to do this with APIs instead, but the LSA_* APIs are
      # particularly onerous and life is short.
      cmd = %Q{secedit.exe /configure /db "#{dbfile}" /cfg "#{policy_file.path}" /areas USER_RIGHTS SECURITYPOLICY SERVICES /log "#{logfile}"}
      Chef::Log.debug "Granting logon-as-service privilege with: #{cmd}"
      runner = shell_out(cmd)

      if runner.exitstatus != 0
        Chef::Log.fatal "Logon-as-service grant failed with output: #{runner.stdout}"
        raise Chef::Exceptions::Service, <<-EOS
Logon-as-service grant failed with policy file #{policy_file.path}.
You can look at #{logfile} for details, or do `secedit /analyze #{dbfile}`.
The failed command was `#{cmd}`.
EOS
      end

      Chef::Log.info "Grant logon-as-service to user '#{username}' successful."

      ::File.delete(dbfile) rescue nil
      ::File.delete(policy_file)
      ::File.delete(logfile) rescue nil     # logfile is not always present at end.
    end
    true
  end

  # remove characters that make for broken or wonky filenames.
  def clean_username_for_path(username)
    username.gsub(/[\/\\. ]+/, '_')
  end

  # the security policy file only seems to accept \\username, so fix .\username or .\\username.
  # TODO: this probably has to be fixed to handle various valid Windows names correctly.
  def canonicalize_username(username)
    username.sub(/^\.?\\+/, '')
  end

  def current_state
    Win32::Service.status(@new_resource.service_name).current_state
  end

  def current_start_type
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

  # Takes Win32::Service start_types
  def set_startup_type(type)
    # Set-Service Startup Type => Win32::Service Constant
    allowed_types = { :automatic => Win32::Service::AUTO_START,
                      :manual    => Win32::Service::DEMAND_START,
                      :disabled  => Win32::Service::DISABLED }
    unless allowed_types.keys.include?(type)
      raise Chef::Exceptions::ConfigurationError, "#{@new_resource.name}: Startup type '#{type}' is not supported"
    end

    Chef::Log.debug "#{@new_resource.name} setting start_type to #{type}"
    Win32::Service.configure(
      :service_name => @new_resource.service_name,
      :start_type => allowed_types[type]
    )
    @new_resource.updated_by_last_action(true)
  end
end
