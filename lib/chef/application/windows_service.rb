#
# Author:: Christopher Maier (<maier@lambda.local>)
# Copyright:: Copyright 2011-2017, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef"
require "chef/monologger"
require "chef/application"
require "chef/client"
require "chef/config"
require "chef/handler/error_report"
require "chef/log"
require "chef/http"
require "mixlib/cli"
require "socket"
require "uri"
require "win32/daemon"
require "chef/mixin/shell_out"

class Chef
  class Application
    class WindowsService < ::Win32::Daemon
      include Mixlib::CLI
      include Chef::Mixin::ShellOut

      option :config_file,
        :short => "-c CONFIG",
        :long => "--config CONFIG",
        :default => "#{ENV['SYSTEMDRIVE']}/chef/client.rb",
        :description => ""

      option :log_location,
        :short        => "-L LOGLOCATION",
        :long         => "--logfile LOGLOCATION",
        :description  => "Set the log file location"

      option :splay,
        :short        => "-s SECONDS",
        :long         => "--splay SECONDS",
        :description  => "The splay time for running at intervals, in seconds",
        :proc         => lambda { |s| s.to_i }

      option :interval,
        :short        => "-i SECONDS",
        :long         => "--interval SECONDS",
        :description  => "Set the number of seconds to wait between chef-client runs",
        :proc         => lambda { |s| s.to_i }

      DEFAULT_LOG_LOCATION ||= "#{ENV['SYSTEMDRIVE']}/chef/client.log"

      def service_init
        @service_action_mutex = Mutex.new
        @service_signal = ConditionVariable.new

        reconfigure
        Chef::Log.info("Chef Client Service initialized")
      end

      def service_main(*startup_parameters)
        # Chef::Config is initialized during service_init
        # Set the initial timeout to splay sleep time
        timeout = rand Chef::Config[:splay]

        while running?
          # Grab the service_action_mutex to make a chef-client run
          @service_action_mutex.synchronize do
            begin
              Chef::Log.info("Next chef-client run will happen in #{timeout} seconds")
              @service_signal.wait(@service_action_mutex, timeout)

              # Continue only if service is RUNNING
              next if state != RUNNING

              # Reconfigure each time through to pick up any changes in the client file
              Chef::Log.info("Reconfiguring with startup parameters")
              reconfigure(startup_parameters)
              timeout = Chef::Config[:interval]

              # Honor splay sleep config
              timeout += rand Chef::Config[:splay]

              # run chef-client only if service is in RUNNING state
              next if state != RUNNING

              Chef::Log.info("Chef-Client service is starting a chef-client run...")
              run_chef_client
            rescue SystemExit => e
              # Do not raise any of the errors here in order to
              # prevent service crash
              Chef::Log.error("#{e.class}: #{e}")
            rescue Exception => e
              Chef::Log.error("#{e.class}: #{e}")
            end
          end
        end

        # Daemon class needs to have all the signal callbacks return
        # before service_main returns.
        Chef::Log.debug("Giving signal callbacks some time to exit...")
        sleep 1
        Chef::Log.debug("Exiting service...")
      end

      ################################################################################
      # Control Signal Callback Methods
      ################################################################################

      def service_stop
        run_warning_displayed = false
        Chef::Log.info("STOP request from operating system.")
        loop do
          # See if a run is in flight
          if @service_action_mutex.try_lock
            # Run is not in flight. Wake up service_main to exit.
            @service_signal.signal
            @service_action_mutex.unlock
            break
          else
            unless run_warning_displayed
              Chef::Log.info("Currently a chef run is happening on this system.")
              Chef::Log.info("Service  will stop when run is completed.")
              run_warning_displayed = true
            end

            Chef::Log.debug("Waiting for chef-client run...")
            sleep 1
          end
        end
        Chef::Log.info("Service is stopping....")
      end

      def service_pause
        Chef::Log.info("PAUSE request from operating system.")

        # We don't need to wake up the service_main if it's waiting
        # since this is a PAUSE signal.

        if @service_action_mutex.locked?
          Chef::Log.info("Currently a chef-client run is happening.")
          Chef::Log.info("Service will pause once it's completed.")
        else
          Chef::Log.info("Service is pausing....")
        end
      end

      def service_resume
        # We don't need to wake up the service_main if it's waiting
        # since this is a RESUME signal.

        Chef::Log.info("RESUME signal received from the OS.")
        Chef::Log.info("Service is resuming....")
      end

      def service_shutdown
        Chef::Log.info("SHUTDOWN signal received from the OS.")

        # Treat shutdown similar to stop.

        service_stop
      end

      ################################################################################
      # Internal Methods
      ################################################################################

      private

      # Initializes Chef::Client instance and runs it
      def run_chef_client
        # The chef client will be started in a new process. We have used shell_out to start the chef-client.
        # The log_location and config_file of the parent process is passed to the new chef-client process.
        # We need to add the --no-fork, as by default it is set to fork=true.

        Chef::Log.info "Starting chef-client in a new process"
        # Pass config params to the new process
        config_params = " --no-fork"
        config_params += " -c #{Chef::Config[:config_file]}" unless Chef::Config[:config_file].nil?
        # log_location might be an event logger and if so we cannot pass as a command argument
        # but shed no tears! If the logger is an event logger, it must have been configured
        # as such in the config file and chef-client will use that when no arg is passed here
        config_params += " -L #{resolve_log_location}" if resolve_log_location.is_a?(String)

        # Starts a new process and waits till the process exits

        result = shell_out(
          "chef-client.bat #{config_params}",
          :timeout => Chef::Config[:windows_service][:watchdog_timeout],
          :logger => Chef::Log
        )
        Chef::Log.debug "#{result.stdout}"
        Chef::Log.debug "#{result.stderr}"
      rescue Mixlib::ShellOut::CommandTimeout => e
        Chef::Log.error "chef-client timed out\n(#{e})"
        Chef::Log.error(<<-EOF)
            Your chef-client run timed out. You can increase the time chef-client is given
            to complete by configuring windows_service.watchdog_timeout in your client.rb.
          EOF
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Chef::Log.warn "Not able to start chef-client in new process (#{e})"
      rescue => e
        Chef::Log.error e
      ensure
        # Once process exits, we log the current process' pid
        Chef::Log.info "Child process exited (pid: #{Process.pid})"
      end

      def apply_config(config_file_path)
        Chef::Config.from_file(config_file_path)
        Chef::Config.merge!(config)
      end

      # Lifted from Chef::Application, with addition of optional startup parameters
      # for playing nicely with Windows Services
      def reconfigure(startup_parameters = [])
        configure_chef startup_parameters
        configure_logging

        Chef::Config[:chef_server_url] = config[:chef_server_url] if config.has_key? :chef_server_url
        unless Chef::Config[:exception_handlers].any? { |h| Chef::Handler::ErrorReport === h }
          Chef::Config[:exception_handlers] << Chef::Handler::ErrorReport.new
        end

        Chef::Config[:interval] ||= 1800
      end

      # Lifted from application.rb
      # See application.rb for related comments.

      def configure_logging
        Chef::Log.init(MonoLogger.new(resolve_log_location))
        if want_additional_logger?
          configure_stdout_logger
        end
        Chef::Log.level = resolve_log_level
      end

      def configure_stdout_logger
        stdout_logger = MonoLogger.new(STDOUT)
        stdout_logger.formatter = Chef::Log.logger.formatter
        Chef::Log.loggers << stdout_logger
      end

      # Based on config and whether or not STDOUT is a tty, should we setup a
      # secondary logger for stdout?
      def want_additional_logger?
        ( Chef::Config[:log_location] != STDOUT ) && STDOUT.tty? && !Chef::Config[:daemonize]
      end

      # Use of output formatters is assumed if `force_formatter` is set or if
      # `force_logger` is not set
      def using_output_formatter?
        Chef::Config[:force_formatter] || !Chef::Config[:force_logger]
      end

      def auto_log_level?
        Chef::Config[:log_level] == :auto
      end

      def resolve_log_location
        # STDOUT is the default log location, but makes no sense for a windows service
        Chef::Config[:log_location] == STDOUT ? DEFAULT_LOG_LOCATION : Chef::Config[:log_location]
      end

      # if log_level is `:auto`, convert it to :warn (when using output formatter)
      # or :info (no output formatter). See also +using_output_formatter?+
      def resolve_log_level
        if auto_log_level?
          if using_output_formatter?
            :warn
          else
            :info
          end
        else
          Chef::Config[:log_level]
        end
      end

      def configure_chef(startup_parameters)
        # Bit of a hack ahead:
        # It is possible to specify a service's binary_path_name with arguments, like "foo.exe -x argX".
        # It is also possible to specify startup parameters separately, either via the Services manager
        # or by using the registry (I think).

        # In order to accommodate all possible sources of parameterization, we first parse any command line
        # arguments.  We then parse any startup parameters.  This works, because Mixlib::CLI reuses its internal
        # 'config' hash; thus, anything in startup parameters will override any command line parameters that
        # might be set via the service's binary_path_name
        #
        # All these parameters then get layered on top of those from Chef::Config

        parse_options # Operates on ARGV by default
        parse_options startup_parameters

        begin
          case config[:config_file]
          when /^(http|https):\/\//
            Chef::HTTP.new("").streaming_request(config[:config_file]) { |f| apply_config(f.path) }
          else
            ::File.open(config[:config_file]) { |f| apply_config(f.path) }
          end
        rescue Errno::ENOENT
          Chef::Log.warn("*****************************************")
          Chef::Log.warn("Did not find config file: #{config[:config_file]}, using command line options.")
          Chef::Log.warn("*****************************************")

          Chef::Config.merge!(config)
        rescue SocketError
          Chef::Application.fatal!("Error getting config file #{Chef::Config[:config_file]}")
        rescue Chef::Exceptions::ConfigurationError => error
          Chef::Application.fatal!("Error processing config file #{Chef::Config[:config_file]} with error #{error.message}")
        rescue Exception => error
          Chef::Application.fatal!("Unknown error processing config file #{Chef::Config[:config_file]} with error #{error.message}")
        end
      end

    end
  end
end

# To run this file as a service, it must be called as a script from within
# the Windows Service framework.  In that case, kick off the main loop!
if __FILE__ == $0
  Chef::Application::WindowsService.mainloop
end
