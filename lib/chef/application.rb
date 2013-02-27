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
require 'socket'
require 'chef/config'
require 'chef/exceptions'
require 'chef/log'
require 'chef/platform'
require 'mixlib/cli'
require 'tmpdir'
require 'rbconfig'

class Chef::Application
  include Mixlib::CLI

  def initialize
    super

    @chef_client = nil
    @chef_client_json = nil
    trap("TERM") do
      Chef::Application.fatal!("SIGTERM received, stopping", 1)
    end

    trap("INT") do
      Chef::Application.fatal!("SIGINT received, stopping", 2)
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

    # Always switch to a readable directory. Keeps subsequent Dir.chdir() {}
    # from failing due to permissions when launched as a less privileged user.
  end

  # Reconfigure the application. You'll want to override and super this method.
  def reconfigure
    configure_chef
    configure_logging
  end

  # Get this party started
  def run
    reconfigure
    setup_application
    run_application
  end

  # Parse the configuration file
  def configure_chef
    parse_options

    begin
      case config[:config_file]
      when /^(http|https):\/\//
        Chef::REST.new("", nil, nil).fetch(config[:config_file]) { |f| apply_config(f.path) }
      else
        ::File::open(config[:config_file]) { |f| apply_config(f.path) }
      end
    rescue Errno::ENOENT => error
      Chef::Log.warn("*****************************************")
      Chef::Log.warn("Did not find config file: #{config[:config_file]}, using command line options.")
      Chef::Log.warn("*****************************************")

      Chef::Config.merge!(config)
    rescue SocketError => error
      Chef::Application.fatal!("Error getting config file #{Chef::Config[:config_file]}", 2)
    rescue Chef::Exceptions::ConfigurationError => error
      Chef::Application.fatal!("Error processing config file #{Chef::Config[:config_file]} with error #{error.message}", 2)
    rescue Exception => error
      Chef::Application.fatal!("Unknown error processing config file #{Chef::Config[:config_file]} with error #{error.message}", 2)
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
  end

  def configure_stdout_logger
    stdout_logger = MonoLogger.new(STDOUT)
    STDOUT.sync = true
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

  # Called prior to starting the application, by the run method
  def setup_application
    raise Chef::Exceptions::Application, "#{self.to_s}: you must override setup_application"
  end

  # Actually run the application
  def run_application
    raise Chef::Exceptions::Application, "#{self.to_s}: you must override run_application"
  end

  # Initializes Chef::Client instance and runs it
  def run_chef_client
    @chef_client = Chef::Client.new(
      @chef_client_json, 
      :override_runlist => config[:override_runlist]
    )
    @chef_client_json = nil

    @chef_client.run
    @chef_client = nil
  end

  private

  def apply_config(config_file_path)
    Chef::Config.from_file(config_file_path)
    Chef::Config.merge!(config)
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
