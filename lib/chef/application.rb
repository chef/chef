#
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Mark Mzyk (mmzyk@opscode.com)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'pp'
require 'uri'
require 'socket'
require 'chef/config'
require 'chef/config_fetcher'
require 'chef/exceptions'
require 'chef/local_mode'
require 'chef/log'
require 'chef/platform'
require 'mixlib/cli'
require 'tmpdir'
require 'rbconfig'

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

    # Reconfigure the application. You'll want to override and super this method.
    def reconfigure
      configure_chef
      configure_logging
      configure_proxy_environment_variables
      configure_encoding
      emit_warnings
    end

    # Get this party started
    def run
      setup_signal_handlers
      reconfigure
      setup_application
      run_application
    end

    def setup_signal_handlers
      trap("INT") do
        Chef::Application.fatal!("SIGINT received, stopping", 2)
      end

      trap("TERM") do
        Chef::Application.fatal!("SIGTERM received, stopping", 3)
      end

      unless Chef::Platform.windows?
        trap("QUIT") do
          Chef::Log.info("SIGQUIT received, call stack:\n  " + caller.join("\n  "))
        end

        trap("HUP") do
          Chef::Log.info("SIGHUP received, reconfiguring")
          reconfigure
        end
      end
    end

    # Parse configuration (options and config file)
    def configure_chef
      parse_options
      load_config_file
    end

    # Parse the config file
    def load_config_file
      config_fetcher = Chef::ConfigFetcher.new(config[:config_file])
      if config[:config_file].nil?
        Chef::Log.warn("No config file found or specified on command line, using command line options.")
      elsif config_fetcher.config_missing?
        pp config_missing: true
        Chef::Log.warn("*****************************************")
        Chef::Log.warn("Did not find config file: #{config[:config_file]}, using command line options.")
        Chef::Log.warn("*****************************************")
      else
        config_content = config_fetcher.read_config
        apply_config(config_content, config[:config_file])
      end
      Chef::Config.merge!(config)
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
    # When `log_level` is set to `:auto` (default), the log level will be `:warn`
    # when the primary output mode is an output formatter (see
    # +using_output_formatter?+) and `:info` otherwise.
    #
    # === Automatic STDOUT Logging
    # When `force_logger` is configured (e.g., Chef 10 mode), a second logger
    # with output on STDOUT is added when running in a console (STDOUT is a tty)
    # and the configured log_location isn't STDOUT. This accounts for the case
    # that a user has configured a log_location in client.rb, but is running
    # chef-client by hand to troubleshoot a problem.
    def configure_logging
      Chef::Log.init(MonoLogger.new(Chef::Config[:log_location]))
      if want_additional_logger?
        configure_stdout_logger
      end
      Chef::Log.level = resolve_log_level
    rescue StandardError => error
      Chef::Log.fatal("Failed to open or create log file at #{Chef::Config[:log_location]}: #{error.class} (#{error.message})")
      Chef::Application.fatal!("Aborting due to invalid 'log_location' configuration", 2)
    end

    def configure_stdout_logger
      stdout_logger = MonoLogger.new(STDOUT)
      stdout_logger.formatter = Chef::Log.logger.formatter
      Chef::Log.loggers <<  stdout_logger
    end

    # Based on config and whether or not STDOUT is a tty, should we setup a
    # secondary logger for stdout?
    def want_additional_logger?
      ( Chef::Config[:log_location] != STDOUT ) && STDOUT.tty? && (!Chef::Config[:daemonize]) && (Chef::Config[:force_logger])
    end

    # Use of output formatters is assumed if `force_formatter` is set or if
    # `force_logger` is not set and STDOUT is to a console (tty)
    def using_output_formatter?
      Chef::Config[:force_formatter] || (!Chef::Config[:force_logger] && STDOUT.tty?)
    end

    def auto_log_level?
      Chef::Config[:log_level] == :auto
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

    # Configure and set any proxy environment variables according to the config.
    def configure_proxy_environment_variables
      configure_http_proxy
      configure_https_proxy
      configure_ftp_proxy
      configure_no_proxy
    end

    # Sets the default external encoding to UTF-8 (users can change this, but they shouldn't)
    def configure_encoding
      Encoding.default_external = Chef::Config[:ruby_encoding]
    end

    # Called prior to starting the application, by the run method
    def setup_application
      raise Chef::Exceptions::Application, "#{self.to_s}: you must override setup_application"
    end

    # Actually run the application
    def run_application
      raise Chef::Exceptions::Application, "#{self.to_s}: you must override run_application"
    end

    # Initializes Chef::Client instance and runs it
    def run_chef_client(specific_recipes = [])
      Chef::LocalMode.with_server_connectivity do
        override_runlist = config[:override_runlist]
        if specific_recipes.size > 0
          override_runlist ||= []
        end
        @chef_client = Chef::Client.new(
          @chef_client_json,
          :override_runlist => config[:override_runlist],
          :specific_recipes => specific_recipes,
          :runlist => config[:runlist]
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
      Chef::Config[:client_fork] && Process.respond_to?(:fork) && !Chef::Platform.windows?
    end

    # Run chef-client once and then exit. If TERM signal is received, ignores the
    # signal to finish the converge and exists.
    def run_with_graceful_exit_option
      # Override the TERM signal.
      trap('TERM') do
        Chef::Log.debug("SIGTERM received during converge," +
                        " finishing converge to exit normally (send SIGINT to terminate immediately)")
      end

      @chef_client.run
      true
    end

    def fork_chef_client
      Chef::Log.info "Forking chef instance to converge..."
      pid = fork do
        # Want to allow forked processes to finish converging when
        # TERM singal is received (exit gracefully)
        trap('TERM') do
          Chef::Log.debug("SIGTERM received during converge," +
                          " finishing converge to exit normally (send SIGINT to terminate immediately)")
        end

        client_solo = Chef::Config[:solo] ? "chef-solo" : "chef-client"
        $0 = "#{client_solo} worker: ppid=#{Process.ppid};start=#{Time.new.strftime("%R:%S")};"
        begin
          Chef::Log.debug "Forked instance now converging"
          @chef_client.run
        rescue Exception => e
          Chef::Log.error(e.to_s)
          exit 1
        else
          exit 0
        end
      end
      Chef::Log.debug "Fork successful. Waiting for new chef pid: #{pid}"
      result = Process.waitpid2(pid)
      handle_child_exit(result)
      Chef::Log.debug "Forked instance successfully reaped (pid: #{pid})"
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
      Chef::Config.from_string(config_content, config_file_path)
    rescue Exception => error
      Chef::Log.fatal("Configuration error #{error.class}: #{error.message}")
      filtered_trace = error.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
      filtered_trace.each {|line| Chef::Log.fatal("  " + line )}
      Chef::Application.fatal!("Aborting due to error in '#{config_file_path}'", 2)
    end

    # Set ENV['http_proxy']
    def configure_http_proxy
      if http_proxy = Chef::Config[:http_proxy]
        http_proxy_string = configure_proxy("http", http_proxy,
                                            Chef::Config[:http_proxy_user], Chef::Config[:http_proxy_pass])
        env['http_proxy'] = http_proxy_string unless env['http_proxy']
        env['HTTP_PROXY'] = http_proxy_string unless env['HTTP_PROXY']
      end
    end

    # Set ENV['https_proxy']
    def configure_https_proxy
      if https_proxy = Chef::Config[:https_proxy]
        https_proxy_string = configure_proxy("https", https_proxy,
                                             Chef::Config[:https_proxy_user], Chef::Config[:https_proxy_pass])
        env['https_proxy'] = https_proxy_string unless env['https_proxy']
        env['HTTPS_PROXY'] = https_proxy_string unless env['HTTPS_PROXY']
      end
    end

    # Set ENV['ftp_proxy']
    def configure_ftp_proxy
      if ftp_proxy = Chef::Config[:ftp_proxy]
        ftp_proxy_string = configure_proxy("ftp", ftp_proxy,
                                           Chef::Config[:ftp_proxy_user], Chef::Config[:ftp_proxy_pass])
        env['ftp_proxy'] = ftp_proxy_string unless env['ftp_proxy']
        env['FTP_PROXY'] = ftp_proxy_string unless env['FTP_PROXY']
      end
    end

    # Set ENV['no_proxy']
    def configure_no_proxy
      if Chef::Config[:no_proxy]
        env['no_proxy'] = Chef::Config[:no_proxy] unless env['no_proxy']
        env['NO_PROXY'] = Chef::Config[:no_proxy] unless env['NO_PROXY']
      end
    end

    # Builds a proxy uri. Examples:
    #   http://username:password@hostname:port
    #   https://username@hostname:port
    #   ftp://hostname:port
    # when
    #   scheme = "http", "https", or "ftp"
    #   hostport = hostname:port
    #   user = username
    #   pass = password
    def configure_proxy(scheme, path, user, pass)
      begin
        path = "#{scheme}://#{path}" unless path.include?('://')
        # URI.split returns the following parts:
        # [scheme, userinfo, host, port, registry, path, opaque, query, fragment]
        parts = URI.split(URI.encode(path))
        # URI::Generic.build requires an integer for the port, but URI::split gives
        # returns a string for the port.
        parts[3] = parts[3].to_i if parts[3]
        if user
          userinfo = URI.encode(URI.encode(user), '@:')
          if pass
            userinfo << ":#{URI.encode(URI.encode(pass), '@:')}"
          end
          parts[1] = userinfo
        end

        return URI::Generic.build(parts).to_s
      rescue URI::Error => e
        # URI::Error messages generally include the offending string. Including a message
        # for which proxy config item has the issue should help deduce the issue when
        # the URI::Error message is vague.
        raise Chef::Exceptions::BadProxyURI, "Cannot configure #{scheme} proxy. Does not comply with URI scheme. #{e.message}"
      end
    end

    # This is a hook for testing
    def env
      ENV
    end

    def emit_warnings
      if Chef::Config[:chef_gem_compile_time]
        Chef::Log.warn "setting chef_gem_compile_time to true is deprecated"
      end
    end

    class << self
      def debug_stacktrace(e)
        message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
        chef_stacktrace_out = "Generated at #{Time.now.to_s}\n"
        chef_stacktrace_out += message

        Chef::FileCache.store("chef-stacktrace.out", chef_stacktrace_out)
        Chef::Log.fatal("Stacktrace dumped to #{Chef::FileCache.load("chef-stacktrace.out", false)}")
        Chef::Log.debug(message)
        true
      end

      # Log a fatal error message to both STDERR and the Logger, exit the application
      def fatal!(msg, err = -1)
        Chef::Log.fatal(msg)
        Process.exit err
      end

      def exit!(msg, err = -1)
        Chef::Log.debug(msg)
        Process.exit err
      end
    end

  end
end
