#
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Mark Mzyk (mmzyk@chef.io)
# Copyright:: Copyright 2008-2019, Chef Software Inc.
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

require "pp"
require "socket"
require "chef/config"
require "chef/config_fetcher"
require "chef/exceptions"
require "chef/local_mode"
require "chef/log"
require "chef/platform"
require "mixlib/cli"
require "tmpdir"
require "rbconfig"
require "chef/application/exit_code"
require "chef/dist"
require "license_acceptance/acceptor"

class Chef
  class Application
    include Mixlib::CLI

    def initialize
      super

      @chef_client = nil
      @chef_client_json = nil

      # Always switch to a readable directory. Keeps subsequent Dir.chdir() {}
      # from failing due to permissions when launched as a less privileged user.
    end

    # Configure mixlib-cli to always separate defaults from user-supplied CLI options
    def self.use_separate_defaults?
      true
    end

    # Reconfigure the application. You'll want to override and super this method.
    def reconfigure
      # In case any gems were installed for use in the config.
      Gem.clear_paths
      configure_chef
      configure_logging
      configure_encoding
      emit_warnings
    end

    # Get this party started
    def run
      setup_signal_handlers
      reconfigure
      setup_application
      check_license_acceptance
      run_application
    end

    def setup_signal_handlers
      trap("INT") do
        Chef::Application.fatal!("SIGINT received, stopping", Chef::Exceptions::SigInt.new)
      end

      trap("TERM") do
        Chef::Application.fatal!("SIGTERM received, stopping", Chef::Exceptions::SigTerm.new)
      end

      unless Chef::Platform.windows?
        trap("QUIT") do
          logger.info("SIGQUIT received, call stack:\n  " + caller.join("\n  "))
        end

        trap("HUP") do
          logger.info("SIGHUP received, reconfiguring")
          reconfigure
        end
      end
    end

    def emit_warnings
      logger.warn "chef_config[:zypper_check_gpg] is set to false which disables security checking on zypper packages" unless chef_config[:zypper_check_gpg]
    end

    # Parse configuration (options and config file)
    def configure_chef
      parse_options
      load_config_file
      chef_config.export_proxies
      chef_config.init_openssl
      File.umask chef_config[:umask]
    end

    # @api private (test injection)
    def chef_config
      Chef::Config
    end

    # @api private (test injection)
    def logger
      Chef::Log
    end

    def self.logger
      Chef::Log
    end

    # @api private (test injection)
    def chef_configfetcher
      Chef::ConfigFetcher
    end

    # Parse the config file
    def load_config_file
      # apply the default cli options first
      chef_config.merge!(default_config)

      config_fetcher = chef_configfetcher.new(config[:config_file])
      # Some config settings are derived relative to the config file path; if
      # given as a relative path, this is computed relative to cwd, but
      # chef-client will later chdir to root, so we need to get the absolute path
      # here.
      config[:config_file] = config_fetcher.expanded_path

      if config[:config_file].nil?
        logger.warn("No config file found or specified on command line. Using command line options instead.")
      elsif config_fetcher.config_missing?
        logger.warn("*****************************************")
        logger.warn("Did not find config file: #{config[:config_file]}. Using command line options instead.")
        logger.warn("*****************************************")
      else
        config_content = config_fetcher.read_config
        apply_config(config_content, config[:config_file])
      end
      extra_config_options = config.delete(:config_option)
      chef_config.merge!(config)
      apply_extra_config_options(extra_config_options)
    end

    def apply_extra_config_options(extra_config_options)
      chef_config.apply_extra_config_options(extra_config_options)
    rescue ChefConfig::UnparsableConfigOption => e
      Chef::Application.fatal!(e.message)
    end

    def set_specific_recipes
      if cli_arguments.respond_to?(:map)
        chef_config[:specific_recipes] =
          cli_arguments.map { |file| File.expand_path(file) }
      end
    end

    # Initialize and configure the logger.
    # === Loggers and Formatters
    # In Chef 10.x and previous, the Logger was the primary/only way that Chef
    # communicated information to the user. In Chef 10.14, a new system, "output
    # formatters" was added, and in Chef 11.0+ it is the default when running
    # chef in a console (detected by `STDOUT.tty?`). Because output formatters
    # are more complex than the logger system and users have less experience with
    # them, the config option `force_logger` is provided to restore the Chef 10.x
    # behavior.
    #
    # Conversely, for users who want formatter output even when chef is running
    # unattended, the `force_formatter` option is provided.
    #
    # === Auto Log Level
    # The `log_level` of `:auto` means `:warn` in the formatter and `:info` in
    # the logger.
    #
    def configure_logging
      configure_log_location
      logger.init(MonoLogger.new(chef_config[:log_location]))
      if want_additional_logger?
        configure_stdout_logger
      end
      logger.level = resolve_log_level
    rescue StandardError => error
      logger.fatal("Failed to open or create log file at #{chef_config[:log_location]}: #{error.class} (#{error.message})")
      Chef::Application.fatal!("Aborting due to invalid 'log_location' configuration", error)
    end

    # Turn `log_location :syslog` and `log_location :win_evt` into the
    # appropriate loggers.
    def configure_log_location
      log_location = chef_config[:log_location]
      return unless log_location.respond_to?(:to_sym)

      chef_config[:log_location] =
        case log_location.to_sym
          when :syslog then logger::Syslog.new
          when :win_evt then logger::WinEvt.new
          else log_location # Probably a path; let MonoLogger sort it out
        end
    end

    # Based on config and whether or not STDOUT is a tty, should we setup a
    # secondary logger for stdout?
    def want_additional_logger?
      ( Chef::Config[:log_location].class != IO ) && STDOUT.tty? && !Chef::Config[:daemonize]
    end

    def configure_stdout_logger
      stdout_logger = MonoLogger.new(STDOUT)
      stdout_logger.formatter = logger.logger.formatter
      logger.loggers << stdout_logger
    end

    # Use of output formatters is assumed if `force_formatter` is set or if `force_logger` is not set
    def using_output_formatter?
      chef_config[:force_formatter] || !chef_config[:force_logger]
    end

    def auto_log_level?
      chef_config[:log_level] == :auto
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
        chef_config[:log_level]
      end
    end

    # Sets the default external encoding to UTF-8 (users can change this, but they shouldn't)
    def configure_encoding
      Encoding.default_external = chef_config[:ruby_encoding]
    end

    # Called prior to starting the application, by the run method
    def setup_application
      raise Chef::Exceptions::Application, "#{self}: you must override setup_application"
    end

    def check_license_acceptance
      LicenseAcceptance::Acceptor.check_and_persist!("chef-client", Chef::VERSION.to_s, logger: logger)
    end

    # Actually run the application
    def run_application
      raise Chef::Exceptions::Application, "#{self}: you must override run_application"
    end

    # Initializes Chef::Client instance and runs it
    def run_chef_client(specific_recipes = [])
      unless specific_recipes.respond_to?(:size)
        raise ArgumentError, "received non-Array like specific_recipes argument"
      end

      Chef::LocalMode.with_server_connectivity do
        override_runlist = config[:override_runlist]
        @chef_client = Chef::Client.new(
          @chef_client_json,
          override_runlist: override_runlist,
          specific_recipes: specific_recipes,
          runlist: config[:runlist],
          logger: logger
        )
        @chef_client_json = nil

        if can_fork?
          fork_chef_client # allowed to run client in forked process
        else
          # Unforked interval runs are disabled, so this runs chef-client
          # once and then exits. If TERM signal is received, will "ignore"
          # the signal to finish converge.
          run_with_graceful_exit_option
        end
        @chef_client = nil
      end
    end

    private

    def can_fork?
      # win32-process gem exposes some form of :fork for Process
      # class. So we are separately ensuring that the platform we're
      # running on is not windows before forking.
      chef_config[:client_fork] && Process.respond_to?(:fork) && !Chef::Platform.windows?
    end

    # Run chef-client once and then exit. If TERM signal is received, ignores the
    # signal to finish the converge and exists.
    def run_with_graceful_exit_option
      # Override the TERM signal.
      trap("TERM") do
        logger.debug("SIGTERM received during converge," +
          " finishing converge to exit normally (send SIGINT to terminate immediately)")
      end

      @chef_client.run
      true
    end

    def fork_chef_client
      logger.info "Forking chef instance to converge..."
      pid = fork do
        # Want to allow forked processes to finish converging when
        # TERM singal is received (exit gracefully)
        trap("TERM") do
          logger.debug("SIGTERM received during converge," +
            " finishing converge to exit normally (send SIGINT to terminate immediately)")
        end

        client_solo = chef_config[:solo] ? "chef-solo" : "#{Chef::Dist::CLIENT}"
        $0 = "#{client_solo} worker: ppid=#{Process.ppid};start=#{Time.new.strftime("%R:%S")};"
        begin
          logger.trace "Forked instance now converging"
          @chef_client.run
        rescue Exception => e
          logger.error(e.to_s)
          exit Chef::Application.normalize_exit_code(e)
        else
          exit 0
        end
      end
      logger.trace "Fork successful. Waiting for new chef pid: #{pid}"
      result = Process.waitpid2(pid)
      handle_child_exit(result)
      logger.trace "Forked instance successfully reaped (pid: #{pid})"
      true
    end

    def handle_child_exit(pid_and_status)
      status = pid_and_status[1]
      return true if status.success?
      message = if status.signaled?
                  "Chef run process terminated by signal #{status.termsig} (#{Signal.list.invert[status.termsig]})"
                else
                  "Chef run process exited unsuccessfully (exit code #{status.exitstatus})"
                end
      raise Exceptions::ChildConvergeError, message
    end

    def apply_config(config_content, config_file_path)
      chef_config.from_string(config_content, config_file_path)
    rescue Exception => error
      logger.fatal("Configuration error #{error.class}: #{error.message}")
      filtered_trace = error.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
      filtered_trace.each { |line| logger.fatal("  " + line ) }
      Chef::Application.fatal!("Aborting due to error in '#{config_file_path}'", error)
    end

    # This is a hook for testing
    def env
      ENV
    end

    class << self
      def debug_stacktrace(e)
        message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"

        cause = e.cause if e.respond_to?(:cause)
        until cause.nil?
          message << "\n\n>>>> Caused by #{cause.class}: #{cause}\n#{cause.backtrace.join("\n")}"
          cause = cause.respond_to?(:cause) ? cause.cause : nil
        end

        chef_stacktrace_out = "Generated at #{Time.now}\n"
        chef_stacktrace_out += message

        Chef::FileCache.store("chef-stacktrace.out", chef_stacktrace_out)
        logger.fatal("Stacktrace dumped to #{Chef::FileCache.load("chef-stacktrace.out", false)}")
        logger.fatal("Please provide the contents of the stacktrace.out file if you file a bug report")
        logger.debug(message)
        true
      end

      def normalize_exit_code(exit_code)
        Chef::Application::ExitCode.normalize_exit_code(exit_code)
      end

      # Log a fatal error message to both STDERR and the Logger, exit the application
      def fatal!(msg, err = nil)
        logger.fatal(msg)
        Process.exit(normalize_exit_code(err))
      end

      def exit!(msg, err = nil)
        logger.debug(msg)
        Process.exit(normalize_exit_code(err))
      end
    end

  end
end
