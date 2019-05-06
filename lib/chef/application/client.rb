#
# Author:: AJ Christensen (<aj@chef.io)
# Author:: Christopher Brown (<cb@chef.io>)
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

require "chef/application"
require "chef/client"
require "chef/config"
require "chef/daemon"
require "chef/log"
require "chef/config_fetcher"
require "chef/handler/error_report"
require "chef/workstation_config_loader"
require "chef/mixin/shell_out"
require "chef-config/mixin/dot_d"
require "mixlib/archive"
require "uri"
require "chef/dist"
require "license_acceptance/cli_flags/mixlib_cli"

class Chef::Application::Client < Chef::Application
  include Chef::Mixin::ShellOut
  include ChefConfig::Mixin::DotD
  include LicenseAcceptance::CLIFlags::MixlibCLI

  # Mimic self_pipe sleep from Unicorn to capture signals safely
  SELF_PIPE = [] # rubocop:disable Style/MutableConstant

  option :config_file,
    short: "-c CONFIG",
    long: "--config CONFIG",
    description: "The configuration file to use."

  option :config_option,
    long: "--config-option OPTION=VALUE",
    description: "Override a single configuration option.",
    proc: lambda { |option, existing|
      (existing ||= []) << option
      existing
    }

  option :formatter,
    short: "-F FORMATTER",
    long: "--format FORMATTER",
    description: "The output format to use.",
    proc: lambda { |format| Chef::Config.add_formatter(format) }

  option :force_logger,
    long: "--force-logger",
    description: "Use logger output instead of formatter output.",
    boolean: true,
    default: false

  option :force_formatter,
    long: "--force-formatter",
    description: "Use formatter output instead of logger output.",
    boolean: true,
    default: false

  option :profile_ruby,
    long: "--[no-]profile-ruby",
    description: "Dump complete Ruby call graph stack of entire #{Chef::Dist::PRODUCT} run (expert only).",
    boolean: true,
    default: false

  option :color,
    long: "--[no-]color",
    boolean: true,
    default: true,
    description: "Use colored output, defaults to enabled."

  option :log_level,
    short: "-l LEVEL",
    long: "--log_level LEVEL",
    description: "Set the log level (auto, trace, debug, info, warn, error, fatal).",
    proc: lambda { |l| l.to_sym }

  option :log_location,
    short: "-L LOGLOCATION",
    long: "--logfile LOGLOCATION",
    description: "Set the log file location, defaults to STDOUT - recommended for daemonizing.",
    proc: nil

  option :help,
    short: "-h",
    long: "--help",
    description: "Show this help message.",
    on: :tail,
    boolean: true,
    show_options: true,
    exit: 0

  option :user,
    short: "-u USER",
    long: "--user USER",
    description: "User to set privilege to.",
    proc: nil

  option :group,
    short: "-g GROUP",
    long: "--group GROUP",
    description: "Group to set privilege to.",
    proc: nil

  unless Chef::Platform.windows?
    option :daemonize,
      short: "-d [WAIT]",
      long: "--daemonize [WAIT]",
      description: "Daemonize the process. Accepts an optional integer which is the " \
        "number of seconds to wait before the first daemonized run.",
      proc: lambda { |wait| wait =~ /^\d+$/ ? wait.to_i : true }
  end

  option :pid_file,
    short: "-P PID_FILE",
    long: "--pid PIDFILE",
    description: "Set the PID file location, for the #{Chef::Dist::CLIENT} daemon process. Defaults to /tmp/chef-client.pid.",
    proc: nil

  option :lockfile,
    long: "--lockfile LOCKFILE",
    description: "Set the lockfile location. Prevents multiple client processes from converging at the same time.",
    proc: nil

  option :interval,
    short: "-i SECONDS",
    long: "--interval SECONDS",
    description: "Run #{Chef::Dist::CLIENT} periodically, in seconds.",
    proc: lambda { |s| s.to_i }

  option :once,
    long: "--once",
    description: "Cancel any interval or splay options, run #{Chef::Dist::CLIENT} once and exit.",
    boolean: true

  option :json_attribs,
    short: "-j JSON_ATTRIBS",
    long: "--json-attributes JSON_ATTRIBS",
    description: "Load attributes from a JSON file or URL.",
    proc: nil

  option :node_name,
    short: "-N NODE_NAME",
    long: "--node-name NODE_NAME",
    description: "The node name for this client.",
    proc: nil

  option :splay,
    short: "-s SECONDS",
    long: "--splay SECONDS",
    description: "The splay time for running at intervals, in seconds.",
    proc: lambda { |s| s.to_i }

  option :chef_server_url,
    short: "-S CHEFSERVERURL",
    long: "--server CHEFSERVERURL",
    description: "The #{Chef::Dist::SERVER_PRODUCT} URL.",
    proc: nil

  option :validation_key,
    short: "-K KEY_FILE",
    long: "--validation_key KEY_FILE",
    description: "Set the validation key file location, used for registering new clients.",
    proc: nil

  option :client_key,
    short: "-k KEY_FILE",
    long: "--client_key KEY_FILE",
    description: "Set the client key file location.",
    proc: nil

  option :named_run_list,
    short: "-n NAMED_RUN_LIST",
    long: "--named-run-list NAMED_RUN_LIST",
    description: "Use a policyfile's named run list instead of the default run list."

  option :environment,
    short: "-E ENVIRONMENT",
    long: "--environment ENVIRONMENT",
    description: "Set the #{Chef::Dist::PRODUCT} environment on the node."

  option :version,
    short: "-v",
    long: "--version",
    description: "Show #{Chef::Dist::PRODUCT} version.",
    boolean: true,
    proc: lambda { |v| puts "#{Chef::Dist::PRODUCT}: #{::Chef::VERSION}" },
    exit: 0

  option :override_runlist,
    short: "-o RunlistItem,RunlistItem...",
    long: "--override-runlist RunlistItem,RunlistItem...",
    description: "Replace current run list with specified items for a single run.",
    proc: lambda { |items|
      items = items.split(",")
      items.compact.map do |item|
        Chef::RunList::RunListItem.new(item)
      end
    }

  option :runlist,
    short: "-r RunlistItem,RunlistItem...",
    long: "--runlist RunlistItem,RunlistItem...",
    description: "Permanently replace current run list with specified items.",
    proc: lambda { |items|
      items = items.split(",")
      items.compact.map do |item|
        Chef::RunList::RunListItem.new(item)
      end
    }

  option :why_run,
    short: "-W",
    long: "--why-run",
    description: "Enable whyrun mode.",
    boolean: true

  option :client_fork,
    short: "-f",
    long: "--[no-]fork",
    description: "Fork #{Chef::Dist::CLIENT} process."

  option :recipe_url,
    long: "--recipe-url=RECIPE_URL",
    description: "Pull down a remote archive of recipes and unpack it to the cookbook cache. Only used in local mode."

  option :enable_reporting,
    short: "-R",
    long: "--enable-reporting",
    description: "Enable reporting data collection for #{Chef::Dist::PRODUCT} runs.",
    boolean: true

  option :local_mode,
    short: "-z",
    long: "--local-mode",
    description: "Point #{Chef::Dist::CLIENT} at local repository.",
    boolean: true

  option :chef_zero_host,
    long: "--chef-zero-host HOST",
    description: "Host to start chef-zero on."

  option :chef_zero_port,
    long: "--chef-zero-port PORT",
    description: "Port (or port range) to start chef-zero on. Port ranges like 1000,1010 or 8889-9999 will try all given ports until one works."

  option :disable_config,
    long: "--disable-config",
    description: "Refuse to load a config file and use defaults. This is for development and not a stable API.",
    boolean: true

  option :run_lock_timeout,
    long: "--run-lock-timeout SECONDS",
    description: "Set maximum duration to wait for another client run to finish, default is indefinitely.",
    proc: lambda { |s| s.to_i }

  if Chef::Platform.windows?
    option :fatal_windows_admin_check,
      short: "-A",
      long: "--fatal-windows-admin-check",
      description: "Fail the run when #{Chef::Dist::CLIENT} doesn't have administrator privileges on Windows.",
      boolean: true
  end

  option :minimal_ohai,
    long: "--minimal-ohai",
    description: "Only run the bare minimum Ohai plugins #{Chef::Dist::PRODUCT} needs to function.",
    boolean: true

  option :listen,
    long: "--[no-]listen",
    description: "Whether a local mode (-z) server binds to a port.",
    boolean: false

  option :fips,
    long: "--[no-]fips",
    description: "Enable FIPS mode.",
    boolean: true

  option :delete_entire_chef_repo,
    long: "--delete-entire-chef-repo",
    description: "DANGEROUS: does what it says, only useful with --recipe-url.",
    boolean: true

  option :skip_cookbook_sync,
    long: "--[no-]skip-cookbook-sync",
    description: "Use cached cookbooks without overwriting local differences from the #{Chef::Dist::SERVER_PRODUCT}.",
    boolean: false

  IMMEDIATE_RUN_SIGNAL = "1".freeze
  RECONFIGURE_SIGNAL = "H".freeze

  attr_reader :chef_client_json

  # Reconfigure the chef client
  # Re-open the JSON attributes and load them into the node
  def reconfigure
    super

    raise Chef::Exceptions::PIDFileLockfileMatch if Chef::Util::PathHelper.paths_eql? (Chef::Config[:pid_file] || "" ), (Chef::Config[:lockfile] || "")

    set_specific_recipes

    Chef::Config[:fips] = config[:fips] if config.key? :fips

    Chef::Config[:chef_server_url] = config[:chef_server_url] if config.key? :chef_server_url

    Chef::Config.local_mode = config[:local_mode] if config.key?(:local_mode)

    if Chef::Config.key?(:chef_repo_path) && Chef::Config.chef_repo_path.nil?
      Chef::Config.delete(:chef_repo_path)
      Chef::Log.warn "chef_repo_path was set in a config file but was empty. Assuming #{Chef::Config.chef_repo_path}"
    end

    if Chef::Config.local_mode && !Chef::Config.key?(:cookbook_path) && !Chef::Config.key?(:chef_repo_path)
      Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Dir.pwd)
    end

    if Chef::Config[:recipe_url]
      if !Chef::Config.local_mode
        Chef::Application.fatal!("recipe-url can be used only in local-mode")
      else
        if Chef::Config[:delete_entire_chef_repo]
          Chef::Log.trace "Cleanup path #{Chef::Config.chef_repo_path} before extract recipes into it"
          FileUtils.rm_rf(Chef::Config.chef_repo_path, secure: true)
        end
        Chef::Log.trace "Creating path #{Chef::Config.chef_repo_path} to extract recipes into"
        FileUtils.mkdir_p(Chef::Config.chef_repo_path)
        tarball_path = File.join(Chef::Config.chef_repo_path, "recipes.tgz")
        fetch_recipe_tarball(Chef::Config[:recipe_url], tarball_path)
        Mixlib::Archive.new(tarball_path).extract(Chef::Config.chef_repo_path, perms: false, ignore: /^\.$/)
        config_path = File.join(Chef::Config.chef_repo_path, ".chef/config.rb")
        Chef::Config.from_string(IO.read(config_path), config_path) if File.file?(config_path)
      end
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

    # supervisor processes are enabled by default for interval-running processes but not for one-shot runs
    if Chef::Config[:client_fork].nil?
      Chef::Config[:client_fork] = !!Chef::Config[:interval]
    end

    if !Chef::Config[:client_fork] && Chef::Config[:interval] && !Chef::Platform.windows?
      Chef::Application.fatal!(unforked_interval_error_message)
    end

    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @chef_client_json = config_fetcher.fetch_json
    end
  end

  def load_config_file
    if !config.key?(:config_file) && !config[:disable_config]
      if config[:local_mode]
        config[:config_file] = Chef::WorkstationConfigLoader.new(nil, Chef::Log).config_location
      else
        config[:config_file] = Chef::Config.platform_specific_path("/etc/chef/client.rb")
      end
    end

    # Load the client.rb configuration
    super

    # Load all config files in client.d
    load_dot_d(Chef::Config[:client_d_dir]) if Chef::Config[:client_d_dir]
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
        Chef::Log.info("SIGUSR1 received, will run now or after the current run")
        SELF_PIPE[1].putc(IMMEDIATE_RUN_SIGNAL) # wakeup master process from select
      end

      # Override the trap setup in the parent so we can avoid running reconfigure during a run
      trap("HUP") do
        Chef::Log.info("SIGHUP received, will reconfigure now or after the current run")
        SELF_PIPE[1].putc(RECONFIGURE_SIGNAL) # wakeup master process from select
      end
    end
  end

  # Run the chef client, optionally daemonizing or looping at intervals.
  def run_application
    if Chef::Config[:version]
      puts "#{Chef::Dist::PRODUCT} version: #{::Chef::VERSION}"
    end

    if !Chef::Config[:client_fork] || Chef::Config[:once]
      begin
        # run immediately without interval sleep, or splay
        run_chef_client(Chef::Config[:specific_recipes])
      rescue SystemExit
        raise
      rescue Exception => e
        Chef::Application.fatal!("#{e.class}: #{e.message}", e)
      end
    else
      interval_run_chef_client
    end
  end

  private

  def interval_run_chef_client
    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize(Chef::Dist::CLIENT)

      # Start first daemonized run after configured number of seconds
      if Chef::Config[:daemonize].is_a?(Integer)
        sleep_then_run_chef_client(Chef::Config[:daemonize])
      end
    end

    loop do
      sleep_then_run_chef_client(time_to_sleep)
      Chef::Application.exit!("Exiting", 0) if !Chef::Config[:interval]
    end
  end

  def sleep_then_run_chef_client(sleep_sec)
    Chef::Log.trace("Sleeping for #{sleep_sec} seconds")

    # interval_sleep will return early if we received a signal (unless on windows)
    interval_sleep(sleep_sec)

    run_chef_client(Chef::Config[:specific_recipes])

    reconfigure
  rescue SystemExit => e
    raise
  rescue Exception => e
    if Chef::Config[:interval]
      Chef::Log.error("#{e.class}: #{e}")
      Chef::Log.trace("#{e.class}: #{e}\n#{e.backtrace.join("\n")}")
      retry
    end

    Chef::Application.fatal!("#{e.class}: #{e.message}", e)
  end

  def time_to_sleep
    duration = 0
    duration += rand(Chef::Config[:splay]) if Chef::Config[:splay]
    duration += Chef::Config[:interval] if Chef::Config[:interval]
    duration
  end

  # sleep and handle queued signals
  def interval_sleep(sec)
    unless SELF_PIPE.empty?
      # mimic sleep with a timeout on IO.select, listening for signals setup in #setup_signal_handlers
      return unless IO.select([ SELF_PIPE[0] ], nil, nil, sec)

      signal = SELF_PIPE[0].getc.chr

      return if signal == IMMEDIATE_RUN_SIGNAL # be explicit about this behavior

      # we need to sleep again after reconfigure to avoid stampeding when logrotate runs out of cron
      if signal == RECONFIGURE_SIGNAL
        reconfigure
        interval_sleep(sec)
      end
    else
      sleep(sec)
    end
  end

  def unforked_interval_error_message
    "Unforked #{Chef::Dist::CLIENT} interval runs are disabled by default." +
      "\nConfiguration settings:" +
      ("\n  interval  = #{Chef::Config[:interval]} seconds" if Chef::Config[:interval]).to_s +
      "\nEnable #{Chef::Dist::CLIENT} interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
  end

  def fetch_recipe_tarball(url, path)
    Chef::Log.trace("Download recipes tarball from #{url} to #{path}")
    if File.exist?(url)
      FileUtils.cp(url, path)
    elsif url =~ URI.regexp
      File.open(path, "wb") do |f|
        open(url) do |r|
          f.write(r.read)
        end
      end
    else
      Chef::Application.fatal! "You specified --recipe-url but the value is neither a valid URL nor a path to a file that exists on disk." +
        "Please confirm the location of the tarball and try again."
    end
  end
end
