#
# Author:: AJ Christensen (<aj@opscode.com>)
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

require 'socket'
require 'chef/config'
require 'chef/exceptions'
require 'chef/log'
require 'mixlib/cli'
require 'tmpdir'

class Chef::Application
  include Mixlib::CLI

  class Wakeup < Exception
  end

  def initialize
    super

    trap("TERM") do
      Chef::Application.fatal!("SIGTERM received, stopping", 1)
    end

    trap("INT") do
      Chef::Application.fatal!("SIGINT received, stopping", 2)
    end

    unless RUBY_PLATFORM =~ /mswin|mingw32|windows/
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
    rescue SocketError => error
      Chef::Application.fatal!("Error getting config file #{Chef::Config[:config_file]}", 2)
    rescue Exception => error
      Chef::Log.warn("*****************************************")
      Chef::Log.warn("Can not find config file: #{config[:config_file]}, using defaults.")
      Chef::Log.warn("#{error.message}")
      Chef::Log.warn("*****************************************")

      Chef::Config.merge!(config)
    end

  end

  # Initialize and configure the logger. If the configured log location is not
  # STDOUT, but stdout is a TTY and we're not daemonizing, we set up a secondary
  # logger with output to stdout. This way, we magically do the right thing when
  # the user has configured logging to a file but they're running chef in the
  # shell to debug something.
  def configure_logging
    Chef::Log.init(Chef::Config[:log_location])
    if ( Chef::Config[:log_location] != STDOUT ) && STDOUT.tty? && (!Chef::Config[:daemonize])
      stdout_logger = Logger.new(STDOUT)
      STDOUT.sync = true
      stdout_logger.formatter = Chef::Log.logger.formatter
      Chef::Log.loggers <<  stdout_logger
    end
    Chef::Log.level = Chef::Config[:log_level]
  end

  # Called prior to starting the application, by the run method
  def setup_application
    raise Chef::Exceptions::Application, "#{self.to_s}: you must override setup_application"
  end

  # Actually run the application
  def run_application
    raise Chef::Exceptions::Application, "#{self.to_s}: you must override run_application"
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
