#
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

require_relative "../application"
require_relative "../client"
require_relative "../log"
require_relative "../config"
require_relative "../mixin/shell_out"
require_relative "../config_fetcher"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require_relative "../daemon"
require "chef-config/mixin/dot_d"
require "license_acceptance/cli_flags/mixlib_cli"
module Mixlib
  autoload :Archive, "mixlib/archive"
end

# This is a temporary class being used as a part of an effort to reduce duplication
# between Chef::Application::Client and Chef::Application::Solo.
#
# If you are looking to make edits to the Client/Solo behavior please make changes here.
#
# If you are looking to reference or subclass this class, use Chef::Application::Client
# instead.  This base class will be removed once the work is complete and external code
# will break.
#
# @deprecated use Chef::Application::Client instead, this will be removed in Chef-16
#
class Chef::Application::Base < Chef::Application
  include Chef::Mixin::ShellOut
  include ChefConfig::Mixin::DotD
  include LicenseAcceptance::CLIFlags::MixlibCLI

  # Mimic self_pipe sleep from Unicorn to capture signals safely
  SELF_PIPE = [] # rubocop:disable Style/MutableConstant

  option :config_option,
    long: "--config-option OPTION=VALUE",
    description: "Override a single configuration option.",
    proc: lambda { |option, existing|
      (existing ||= []) << option
      existing
    }

  option :once,
    long: "--once",
    description: "Cancel any interval or splay options, run #{ChefUtils::Dist::Infra::PRODUCT} once and exit.",
    boolean: true

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
    description: "Dump complete Ruby call graph stack of entire #{ChefUtils::Dist::Infra::PRODUCT} run (expert only).",
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

  option :log_location_cli,
    short: "-L LOGLOCATION",
    long: "--logfile LOGLOCATION",
    description: "Set the log file location, defaults to STDOUT - recommended for daemonizing."

  option :always_dump_stacktrace,
    long: "--[no-]always-dump-stacktrace",
    boolean: true,
    default: false,
    description: "Always dump the stacktrace regardless of the log_level setting."

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

  option :lockfile,
    long: "--lockfile LOCKFILE",
    description: "Set the lockfile location. Prevents multiple client processes from converging at the same time.",
    proc: nil

  option :interval,
    short: "-i SECONDS",
    long: "--interval SECONDS",
    description: "Run #{ChefUtils::Dist::Infra::PRODUCT} periodically, in seconds.",
    proc: lambda { |s| s.to_i }

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

  option :environment,
    short: "-E ENVIRONMENT",
    long: "--environment ENVIRONMENT",
    description: "Set the #{ChefUtils::Dist::Infra::PRODUCT} environment on the node."

  option :client_fork,
    short: "-f",
    long: "--[no-]fork",
    description: "Fork #{ChefUtils::Dist::Infra::PRODUCT} process."

  option :why_run,
    short: "-W",
    long: "--why-run",
    description: "Enable whyrun mode.",
    boolean: true

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

  option :run_lock_timeout,
    long: "--run-lock-timeout SECONDS",
    description: "Set maximum duration to wait for another client run to finish, default is indefinitely.",
    proc: lambda { |s| s.to_i }

  option :version,
    short: "-v",
    long: "--version",
    description: "Show #{ChefUtils::Dist::Infra::PRODUCT} version.",
    boolean: true,
    proc: lambda { |v| puts "#{ChefUtils::Dist::Infra::PRODUCT}: #{::Chef::VERSION}" },
    exit: 0

  option :minimal_ohai,
    long: "--minimal-ohai",
    description: "Only run the bare minimum Ohai plugins #{ChefUtils::Dist::Infra::PRODUCT} needs to function.",
    boolean: true

  option :delete_entire_chef_repo,
    long: "--delete-entire-chef-repo",
    description: "DANGEROUS: does what it says, only useful with --recipe-url.",
    boolean: true

  option :ez,
    long: "--ez",
    description: "A memorial for Ezra Zygmuntowicz.",
    boolean: true

  option :target,
    short: "-t TARGET",
    long: "--target TARGET",
    description: "Target #{ChefUtils::Dist::Infra::PRODUCT} against a remote system or device",
    proc: lambda { |target|
      Chef::Log.warn "-- EXPERIMENTAL -- Target mode activated, resources and dsl may change without warning -- EXPERIMENTAL --"
      target
    }

  option :disable_config,
    long: "--disable-config",
    description: "Refuse to load a config file and use defaults. This is for development and not a stable API.",
    boolean: true

  if Chef::Platform.windows?
    option :fatal_windows_admin_check,
      short: "-A",
      long: "--fatal-windows-admin-check",
      description: "Fail the run when #{ChefUtils::Dist::Infra::CLIENT} doesn't have administrator privileges on Windows.",
      boolean: true
  end

  option :fips,
    long: "--[no-]fips",
    description: "Enable FIPS mode.",
    boolean: true

  option :solo_legacy_mode,
    long: "--legacy-mode",
    description: "Run in legacy mode.",
    boolean: true

  option :chef_server_url,
    short: "-S CHEFSERVERURL",
    long: "--server CHEFSERVERURL",
    description: "The #{ChefUtils::Dist::Server::PRODUCT} URL.",
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

  option :enable_reporting,
    short: "-R",
    long: "--enable-reporting",
    description: "(#{ChefUtils::Dist::Infra::CLIENT} only) reporting data collection for runs.",
    boolean: true

  option :local_mode,
    short: "-z",
    long: "--local-mode",
    description: "Point at local repository.",
    boolean: true

  option :chef_zero_host,
    long: "--chef-zero-host HOST",
    description: "Host to start #{ChefUtils::Dist::Zero::PRODUCT} on."

  option :chef_zero_port,
    long: "--chef-zero-port PORT",
    description: "Port (or port range) to start #{ChefUtils::Dist::Zero::PRODUCT} on. Port ranges like 1000,1010 or 8889-9999 will try all given ports until one works."

  option :listen,
    long: "--[no-]listen",
    description: "Whether a local mode (-z) server binds to a port.",
    boolean: false

  option :skip_cookbook_sync,
    long: "--[no-]skip-cookbook-sync",
    description: "(#{ChefUtils::Dist::Infra::CLIENT} only) Use cached cookbooks without overwriting local differences from the #{ChefUtils::Dist::Server::PRODUCT}.",
    boolean: false

  option :named_run_list,
    short: "-n NAMED_RUN_LIST",
    long: "--named-run-list NAMED_RUN_LIST",
    description: "Use a policyfile's named run list instead of the default run list."

  option :slow_report,
    long: "--[no-]slow-report [COUNT]",
    description: "List the slowest resources at the end of the run (default: 10).",
    boolean: true,
    default: false,
    proc: lambda { |argument|
      if argument.nil?
        true
      elsif argument == false
        false
      else
        Integer(argument)
      end
    }

  IMMEDIATE_RUN_SIGNAL = "1".freeze
  RECONFIGURE_SIGNAL = "H".freeze

  attr_reader :chef_client_json

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
      puts "#{ChefUtils::Dist::Infra::PRODUCT} version: #{::Chef::VERSION}"
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

  def windows_interval_error_message
    "Windows #{ChefUtils::Dist::Infra::PRODUCT} interval runs are not supported in #{ChefUtils::Dist::Infra::PRODUCT} 15 and later." +
      "\nConfiguration settings:" +
      ("\n  interval  = #{Chef::Config[:interval]} seconds" if Chef::Config[:interval]).to_s +
      "\nPlease manage #{ChefUtils::Dist::Infra::PRODUCT} as a scheduled task instead."
  end

  def unforked_interval_error_message
    "Unforked #{ChefUtils::Dist::Infra::PRODUCT} interval runs are disabled by default." +
      "\nConfiguration settings:" +
      ("\n  interval  = #{Chef::Config[:interval]} seconds" if Chef::Config[:interval]).to_s +
      "\nEnable #{ChefUtils::Dist::Infra::PRODUCT} interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
  end

  def fetch_recipe_tarball(url, path)
    require "open-uri" unless defined?(OpenURI)
    Chef::Log.trace("Download recipes tarball from #{url} to #{path}")
    if File.exist?(url)
      FileUtils.cp(url, path)
    elsif URI::DEFAULT_PARSER.make_regexp.match?(url)
      File.open(path, "wb") do |f|
        URI.open(url) do |r|
          f.write(r.read)
        end
      end
    else
      Chef::Application.fatal! "You specified --recipe-url but the value is neither a valid URL nor a path to a file that exists on disk." +
        "Please confirm the location of the tarball and try again."
    end
  end

  def interval_run_chef_client
    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize(ChefUtils::Dist::Infra::PRODUCT)

      # Start first daemonized run after configured number of seconds
      if Chef::Config[:daemonize].is_a?(Integer)
        sleep_then_run_chef_client(Chef::Config[:daemonize])
      end
    end

    loop do
      sleep_then_run_chef_client(time_to_sleep)
      Chef::Application.exit!("Exiting", 0) unless Chef::Config[:interval]
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

  def for_ezra
    puts <<~EOH
      For Ezra Zygmuntowicz:
        The man who brought you Chef Solo
        Early contributor to Chef
        Kind hearted open source advocate
        Rest in peace, Ezra.
    EOH
  end

end
