#
# Author:: AJ Christensen (<aj@opscode.com)
# Author:: Christopher Brown (<cb@opscode.com>)
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

require 'chef/application'
require 'chef/client'
require 'chef/config'
require 'chef/daemon'
require 'chef/log'
require 'chef/config_fetcher'
require 'chef/handler/error_report'

class Chef::Application::Client < Chef::Application

  # Mimic self_pipe sleep from Unicorn to capture signals safely
  SELF_PIPE = []

  option :config_file,
    :short => "-c CONFIG",
    :long  => "--config CONFIG",
    :description => "The configuration file to use"

  option :formatter,
    :short        => "-F FORMATTER",
    :long         => "--format FORMATTER",
    :description  => "output format to use",
    :proc         => lambda { |format| Chef::Config.add_formatter(format) }

  option :force_logger,
    :long         => "--force-logger",
    :description  => "Use logger output instead of formatter output",
    :boolean      => true,
    :default      => false

  option :force_formatter,
    :long         => "--force-formatter",
    :description  => "Use formatter output instead of logger output",
    :boolean      => true,
    :default      => false

  option :color,
    :long         => '--[no-]color',
    :boolean      => true,
    :default      => !Chef::Platform.windows?,
    :description  => "Use colored output, defaults to false on Windows, true otherwise"

  option :log_level,
    :short        => "-l LEVEL",
    :long         => "--log_level LEVEL",
    :description  => "Set the log level (debug, info, warn, error, fatal)",
    :proc         => lambda { |l| l.to_sym }

  option :log_location,
    :short        => "-L LOGLOCATION",
    :long         => "--logfile LOGLOCATION",
    :description  => "Set the log file location, defaults to STDOUT - recommended for daemonizing",
    :proc         => nil

  option :help,
    :short        => "-h",
    :long         => "--help",
    :description  => "Show this message",
    :on           => :tail,
    :boolean      => true,
    :show_options => true,
    :exit         => 0

  option :user,
    :short => "-u USER",
    :long => "--user USER",
    :description => "User to set privilege to",
    :proc => nil

  option :group,
    :short => "-g GROUP",
    :long => "--group GROUP",
    :description => "Group to set privilege to",
    :proc => nil

  unless Chef::Platform.windows?
    option :daemonize,
      :short => "-d",
      :long => "--daemonize",
      :description => "Daemonize the process",
      :proc => lambda { |p| true }
  end

  option :pid_file,
    :short        => "-P PID_FILE",
    :long         => "--pid PIDFILE",
    :description  => "Set the PID file location, defaults to /tmp/chef-client.pid",
    :proc         => nil

  option :interval,
    :short => "-i SECONDS",
    :long => "--interval SECONDS",
    :description => "Run chef-client periodically, in seconds",
    :proc => lambda { |s| s.to_i }

  option :once,
    :long => "--once",
    :description => "Cancel any interval or splay options, run chef once and exit",
    :boolean => true

  option :json_attribs,
    :short => "-j JSON_ATTRIBS",
    :long => "--json-attributes JSON_ATTRIBS",
    :description => "Load attributes from a JSON file or URL",
    :proc => nil

  option :node_name,
    :short => "-N NODE_NAME",
    :long => "--node-name NODE_NAME",
    :description => "The node name for this client",
    :proc => nil

  option :splay,
    :short => "-s SECONDS",
    :long => "--splay SECONDS",
    :description => "The splay time for running at intervals, in seconds",
    :proc => lambda { |s| s.to_i }

  option :chef_server_url,
    :short => "-S CHEFSERVERURL",
    :long => "--server CHEFSERVERURL",
    :description => "The chef server URL",
    :proc => nil

  option :validation_key,
    :short        => "-K KEY_FILE",
    :long         => "--validation_key KEY_FILE",
    :description  => "Set the validation key file location, used for registering new clients",
    :proc         => nil

  option :client_key,
    :short        => "-k KEY_FILE",
    :long         => "--client_key KEY_FILE",
    :description  => "Set the client key file location",
    :proc         => nil

  option :environment,
    :short        => '-E ENVIRONMENT',
    :long         => '--environment ENVIRONMENT',
    :description  => 'Set the Chef Environment on the node'

  option :version,
    :short        => "-v",
    :long         => "--version",
    :description  => "Show chef version",
    :boolean      => true,
    :proc         => lambda {|v| puts "Chef: #{::Chef::VERSION}"},
    :exit         => 0

  option :override_runlist,
    :short        => "-o RunlistItem,RunlistItem...",
    :long         => "--override-runlist RunlistItem,RunlistItem...",
    :description  => "Replace current run list with specified items for a single run",
    :proc         => lambda{|items|
      items = items.split(',')
      items.compact.map{|item|
        Chef::RunList::RunListItem.new(item)
      }
    }

  option :runlist,
    :short        => "-r RunlistItem,RunlistItem...",
    :long         => "--runlist RunlistItem,RunlistItem...",
    :description  => "Permanently replace current run list with specified items",
    :proc         => lambda{|items|
      items = items.split(',')
      items.compact.map{|item|
        Chef::RunList::RunListItem.new(item)
      }
    }
  option :why_run,
    :short        => '-W',
    :long         => '--why-run',
    :description  => 'Enable whyrun mode',
    :boolean      => true

  option :client_fork,
    :short        => "-f",
    :long         => "--[no-]fork",
    :description  => "Fork client",
    :boolean      => true

  option :enable_reporting,
    :short        => "-R",
    :long         => "--enable-reporting",
    :description  => "Enable reporting data collection for chef runs",
    :boolean      => true

  option :local_mode,
    :short        => "-z",
    :long         => "--local-mode",
    :description  => "Point chef-client at local repository",
    :boolean      => true

  option :chef_zero_host,
    :long         => "--chef-zero-host HOST",
    :description  => "Host to start chef-zero on"

  option :chef_zero_port,
    :long         => "--chef-zero-port PORT",
    :description  => "Port to start chef-zero on"

  option :config_file_jail,
    :long         => "--config-file-jail PATH",
    :description  => "Directory under which config files are allowed to be loaded (no client.rb or knife.rb outside this path will be loaded)."

  option :run_lock_timeout,
    :long         => "--run-lock-timeout SECONDS",
    :description  => "Set maximum duration to wait for another client run to finish, default is indefinitely.",
    :proc         => lambda { |s| s.to_i }

  if Chef::Platform.windows?
    option :fatal_windows_admin_check,
      :short        => "-A",
      :long         => "--fatal-windows-admin-check",
      :description  => "Fail the run when chef-client doesn't have administrator privileges on Windows",
      :boolean      => true
  end

  IMMEDIATE_RUN_SIGNAL = "1".freeze
  GRACEFUL_EXIT_SIGNAL = "2".freeze

  attr_reader :chef_client_json

  # Reconfigure the chef client
  # Re-open the JSON attributes and load them into the node
  def reconfigure
    super

    Chef::Config[:specific_recipes] = cli_arguments.map { |file| File.expand_path(file) }

    Chef::Config[:chef_server_url] = config[:chef_server_url] if config.has_key? :chef_server_url

    Chef::Config.local_mode = config[:local_mode] if config.has_key?(:local_mode)
    if Chef::Config.local_mode && !Chef::Config.has_key?(:cookbook_path) && !Chef::Config.has_key?(:chef_repo_path)
      Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Dir.pwd)
    end
    Chef::Config.chef_zero.host = config[:chef_zero_host] if config[:chef_zero_host]
    Chef::Config.chef_zero.port = config[:chef_zero_port] if config[:chef_zero_port]

    if Chef::Config[:daemonize]
      Chef::Config[:interval] ||= 1800
    end

    if Chef::Config[:once]
      Chef::Config[:interval] = nil
      Chef::Config[:splay] = nil
    end

    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @chef_client_json = config_fetcher.fetch_json
    end
  end

  def load_config_file
    Chef::Config.config_file_jail = config[:config_file_jail] if config[:config_file_jail]
    if !config.has_key?(:config_file)
      if config[:local_mode]
        require 'chef/knife'
        config[:config_file] = Chef::Knife.locate_config_file
      else
        config[:config_file] = Chef::Config.platform_specific_path("/etc/chef/client.rb")
      end
    end
    super
  end

  def configure_logging
    super
    Mixlib::Authentication::Log.use_log_devices( Chef::Log )
    Ohai::Log.use_log_devices( Chef::Log )
  end

  def setup_application
    Chef::Daemon.change_privilege
  end

  # Run the chef client, optionally daemonizing or looping at intervals.
  def run_application
    unless Chef::Platform.windows?
      SELF_PIPE.replace IO.pipe

      trap("USR1") do
        Chef::Log.info("SIGUSR1 received, waking up")
        SELF_PIPE[1].putc(IMMEDIATE_RUN_SIGNAL) # wakeup master process from select
      end

      # see CHEF-5172
      if Chef::Config[:daemonize] || Chef::Config[:interval]
        trap("TERM") do
          Chef::Log.info("SIGTERM received, exiting gracefully")
          SELF_PIPE[1].putc(GRACEFUL_EXIT_SIGNAL)
        end
      end
    end

    if Chef::Config[:version]
      puts "Chef version: #{::Chef::VERSION}"
    end

    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize("chef-client")
    end

    signal = nil

    loop do
      begin
        Chef::Application.exit!("Exiting", 0) if signal == GRACEFUL_EXIT_SIGNAL

        if Chef::Config[:splay] and signal != IMMEDIATE_RUN_SIGNAL
          splay = rand Chef::Config[:splay]
          Chef::Log.debug("Splay sleep #{splay} seconds")
          sleep splay
        end

        signal = nil
        run_chef_client(Chef::Config[:specific_recipes])

        if Chef::Config[:interval]
          Chef::Log.debug("Sleeping for #{Chef::Config[:interval]} seconds")
          signal = interval_sleep
        else
          Chef::Application.exit! "Exiting", 0
        end
      rescue SystemExit => e
        raise
      rescue Exception => e
        if Chef::Config[:interval]
          Chef::Log.error("#{e.class}: #{e}")
          Chef::Log.error("Sleeping for #{Chef::Config[:interval]} seconds before trying again")
          signal = interval_sleep
          retry
        else
          Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
        end
      end
    end
  end

  private

  def interval_sleep
    unless SELF_PIPE.empty?
      client_sleep Chef::Config[:interval]
    else
      # Windows
      sleep Chef::Config[:interval]
    end
  end

  def client_sleep(sec)
    IO.select([ SELF_PIPE[0] ], nil, nil, sec) or return
    SELF_PIPE[0].getc.chr
  end
end
