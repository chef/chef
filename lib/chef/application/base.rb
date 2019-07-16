#
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

require_relative "../application"
require_relative "../client"
require_relative "../log"
require_relative "../config"
require_relative "../mixin/shell_out"
require_relative "../config_fetcher"
require_relative "../dist"
require_relative "../daemon"
require "chef-config/mixin/dot_d"
require "license_acceptance/cli_flags/mixlib_cli"
require "mixlib/archive" unless defined?(Mixlib::Archive)

class Chef::Application::Base < Chef::Application
  include Chef::Mixin::ShellOut
  include ChefConfig::Mixin::DotD
  include LicenseAcceptance::CLIFlags::MixlibCLI

  option :config_option,
    long: "--config-option OPTION=VALUE",
    description: "Override a single configuration option.",
    proc: lambda { |option, existing|
      (existing ||= []) << option
      existing
    }

  option :once,
    long: "--once",
    description: "Cancel any interval or splay options, run #{Chef::Dist::PRODUCT} once and exit.",
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

  option :lockfile,
    long: "--lockfile LOCKFILE",
    description: "Set the lockfile location. Prevents multiple client processes from converging at the same time.",
    proc: nil

  option :interval,
    short: "-i SECONDS",
    long: "--interval SECONDS",
    description: "Run #{Chef::Dist::PRODUCT} periodically, in seconds.",
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
    description: "Set the #{Chef::Dist::PRODUCT} environment on the node."

  option :client_fork,
    short: "-f",
    long: "--[no-]fork",
    description: "Fork #{Chef::Dist::PRODUCT} process."

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
    description: "Show #{Chef::Dist::PRODUCT} version.",
    boolean: true,
    proc: lambda { |v| puts "#{Chef::Dist::PRODUCT}: #{::Chef::VERSION}" },
    exit: 0

  option :minimal_ohai,
    long: "--minimal-ohai",
    description: "Only run the bare minimum Ohai plugins #{Chef::Dist::PRODUCT} needs to function.",
    boolean: true

  option :ez,
    long: "--ez",
    description: "A memorial for Ezra Zygmuntowicz.",
    boolean: true

  option :target,
    short: "-t TARGET",
    long: "--target TARGET",
    description: "Target #{Chef::Dist::PRODUCT} against a remote system or device",
    proc: lambda { |target|
      Chef::Log.warn "-- EXPERIMENTAL -- Target mode activated, resources and dsl may change without warning -- EXPERIMENTAL --"
      target
    }

  attr_reader :chef_client_json

  def setup_application
    Chef::Daemon.change_privilege
  end

  private

  def unforked_interval_error_message
    "Unforked #{Chef::Dist::PRODUCT} interval runs are disabled by default." +
      "\nConfiguration settings:" +
      ("\n  interval  = #{Chef::Config[:interval]} seconds" if Chef::Config[:interval]).to_s +
      "\nEnable #{Chef::Dist::PRODUCT} interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
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
