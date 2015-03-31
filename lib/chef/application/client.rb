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
require 'chef/workstation_config_loader'

class Chef::Application::Client < Chef::Application
  include Chef::Mixin::ShellOut

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
    :description  => "Set the log level (auto, debug, info, warn, error, fatal)",
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
    :description  => "Set the PID file location, for the chef-client daemon process. Defaults to /tmp/chef-client.pid",
    :proc         => nil

  option :lockfile,
    :long         => "--lockfile LOCKFILE",
    :description  => "Set the lockfile location. Prevents multiple client processes from converging at the same time",
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

  option :recipe_url,
    :long         => "--recipe-url=RECIPE_URL",
    :description  => "Pull down a remote archive of recipes and unpack it to the cookbook cache. Only used in local mode."

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
    :description  => "Port (or port range) to start chef-zero on.  Port ranges like 1000,1010 or 8889-9999 will try all given ports until one works."

  option :disable_config,
    :long         => "--disable-config",
    :description  => "Refuse to load a config file and use defaults. This is for development and not a stable API",
    :boolean      => true

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

  option :audit_mode,
    :long           => "--audit-mode MODE",
    :description    => "Enable audit-mode with `enabled`. Disable audit-mode with `disabled`. Skip converge and only perform audits with `audit-only`",
    :proc           => lambda { |mo| mo.gsub("-", "_").to_sym }

  option :minimal_ohai,
    :long           => "--minimal-ohai",
    :description    => "Only run the bare minimum ohai plugins chef needs to function",
    :boolean        => true

  option :listen,
    :long           => "--[no-]listen",
    :description    => "Whether a local mode (-z) server binds to a port",
    :boolean        => true

  IMMEDIATE_RUN_SIGNAL = "1".freeze

  attr_reader :chef_client_json

  # Reconfigure the chef client
  # Re-open the JSON attributes and load them into the node
  def reconfigure
    super

    raise Chef::Exceptions::PIDFileLockfileMatch if Chef::Util::PathHelper.paths_eql? (Chef::Config[:pid_file] || '' ), (Chef::Config[:lockfile] || '')

    set_specific_recipes

    Chef::Config[:chef_server_url] = config[:chef_server_url] if config.has_key? :chef_server_url

    Chef::Config.local_mode = config[:local_mode] if config.has_key?(:local_mode)
    if Chef::Config.local_mode && !Chef::Config.has_key?(:cookbook_path) && !Chef::Config.has_key?(:chef_repo_path)
      Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Dir.pwd)
    end

    if !Chef::Config.local_mode && Chef::Config.has_key?(:recipe_url)
      Chef::Application.fatal!("chef-client recipe-url can be used only in local-mode", 1)
    elsif Chef::Config.local_mode && Chef::Config.has_key?(:recipe_url)
      Chef::Log.debug "Creating path #{Chef::Config.chef_repo_path} to extract recipes into"
      FileUtils.mkdir_p(Chef::Config.chef_repo_path)
      tarball_path = File.join(Chef::Config.chef_repo_path, 'recipes.tgz')
      fetch_recipe_tarball(Chef::Config[:recipe_url], tarball_path)
      result = shell_out!("tar zxvf #{tarball_path} -C #{Chef::Config.chef_repo_path}")
      Chef::Log.debug "#{result.stdout}"
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

    if !Chef::Config[:client_fork] && Chef::Config[:interval] && !Chef::Platform.windows?
      Chef::Application.fatal!(unforked_interval_error_message)
    end

    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @chef_client_json = config_fetcher.fetch_json
    end

    if mode = config[:audit_mode] || Chef::Config[:audit_mode]
      expected_modes = [:enabled, :disabled, :audit_only]
      unless expected_modes.include?(mode)
        Chef::Application.fatal!(unrecognized_audit_mode(mode))
      end

      unless mode == :disabled
        # This should be removed when audit-mode is enabled by default/no longer
        # an experimental feature.
        Chef::Log.warn(audit_mode_experimental_message)
      end
    end
  end

  def load_config_file
    if !config.has_key?(:config_file) && !config[:disable_config]
      if config[:local_mode]
        config[:config_file] = Chef::WorkstationConfigLoader.new(nil, Chef::Log).config_location
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

  def setup_signal_handlers
    super

    unless Chef::Platform.windows?
      SELF_PIPE.replace IO.pipe

      trap("USR1") do
        Chef::Log.info("SIGUSR1 received, waking up")
        SELF_PIPE[1].putc(IMMEDIATE_RUN_SIGNAL) # wakeup master process from select
      end
    end
  end

  # Run the chef client, optionally daemonizing or looping at intervals.
  def run_application
    if Chef::Config[:version]
      puts "Chef version: #{::Chef::VERSION}"
    end

    if !Chef::Config[:client_fork] || Chef::Config[:once]
      begin
        # run immediately without interval sleep, or splay
        run_chef_client(Chef::Config[:specific_recipes])
      rescue SystemExit
        raise
      rescue Exception => e
        Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
      end
    else
      interval_run_chef_client
    end
  end

  private
  def interval_run_chef_client
    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize("chef-client")
    end

    loop do
      begin
        @signal = test_signal
        if @signal != IMMEDIATE_RUN_SIGNAL
          sleep_sec = time_to_sleep
          Chef::Log.debug("Sleeping for #{sleep_sec} seconds")
          interval_sleep(sleep_sec)
        end

        @signal = nil
        run_chef_client(Chef::Config[:specific_recipes])

        Chef::Application.exit!("Exiting", 0) if !Chef::Config[:interval]
      rescue SystemExit => e
        raise
      rescue Exception => e
        if Chef::Config[:interval]
          Chef::Log.error("#{e.class}: #{e}")
          Chef::Log.debug("#{e.class}: #{e}\n#{e.backtrace.join("\n")}")
          retry
        else
          Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
        end
      end
    end
  end

  def test_signal
    @signal = interval_sleep(0)
  end

  def time_to_sleep
    duration = 0
    duration += rand(Chef::Config[:splay]) if Chef::Config[:splay]
    duration += Chef::Config[:interval] if Chef::Config[:interval]
    duration
  end

  def interval_sleep(sec)
    unless SELF_PIPE.empty?
      client_sleep(sec)
    else
      # Windows
      sleep(sec)
    end
  end

  def client_sleep(sec)
    IO.select([ SELF_PIPE[0] ], nil, nil, sec) or return
    @signal = SELF_PIPE[0].getc.chr
  end

  def unforked_interval_error_message
    "Unforked chef-client interval runs are disabled in Chef 12." +
    "\nConfiguration settings:" +
    "#{"\n  interval  = #{Chef::Config[:interval]} seconds" if Chef::Config[:interval]}" +
    "\nEnable chef-client interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
  end

  def audit_mode_settings_explaination
    "\n* To enable audit mode after converge, use command line option `--audit-mode enabled` or set `:audit_mode = :enabled` in your config file." +
    "\n* To disable audit mode, use command line option `--audit-mode disabled` or set `:audit_mode = :disabled` in your config file." +
    "\n* To only run audit mode, use command line option `--audit-mode audit-only` or set `:audit_mode = :audit_only` in your config file." +
    "\nAudit mode is disabled by default."
  end

  def unrecognized_audit_mode(mode)
    "Unrecognized setting #{mode} for audit mode." + audit_mode_settings_explaination
  end

  def audit_mode_experimental_message
    msg = if Chef::Config[:audit_mode] == :audit_only
      "Chef-client has been configured to skip converge and only audit."
    else
      "Chef-client has been configured to audit after it converges."
    end
    msg += " Audit mode is an experimental feature currently under development. API changes may occur. Use at your own risk."
    msg += audit_mode_settings_explaination
    return msg
  end

  def fetch_recipe_tarball(url, path)
    Chef::Log.debug("Download recipes tarball from #{url} to #{path}")
    File.open(path, 'wb') do |f|
      open(url) do |r|
        f.write(r.read)
      end
    end
  end
end
