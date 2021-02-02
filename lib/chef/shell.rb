# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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
#

module Mixlib
  module Authentication
    autoload :Log, "mixlib/authentication"
  end
end
require "singleton" unless defined?(Singleton)
require "pp" unless defined?(PP)
require "etc" unless defined?(Etc)
require "mixlib/cli" unless defined?(Mixlib::CLI)
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "chef-config/mixin/dot_d"

require_relative "../chef"
require_relative "version"
require_relative "client"
require_relative "config"
require_relative "config_fetcher"

require_relative "shell/shell_session"
require_relative "workstation_config_loader"
require_relative "shell/ext"
require_relative "json_compat"
require_relative "util/path_helper"

# = Shell
# Shell is Chef in an IRB session. Shell can interact with a Chef server via the
# REST API, and run and debug recipes interactively.
module Shell
  LEADERS = Hash.new("")
  LEADERS[Chef::Recipe] = ":recipe"
  LEADERS[Chef::Node]   = ":attributes"

  class << self
    attr_accessor :options
    attr_accessor :env
    attr_writer   :editor
  end

  # Start the irb REPL with chef-shell's customizations
  def self.start
    setup_logger
    # FUGLY HACK: irb gives us no other choice.
    irb_help = [:help, :irb_help, IRB::ExtendCommandBundle::NO_OVERRIDE]
    IRB::ExtendCommandBundle.instance_variable_get(:@ALIASES).delete(irb_help)

    parse_opts
    Chef::Config[:shell_config] = options.config

    # HACK: this duplicates the functions of IRB.start, but we have to do it
    # to get access to the main object before irb starts.
    ::IRB.setup(nil)

    irb_conf[:USE_COLORIZE] = options.config[:use_colorize]
    irb_conf[:USE_SINGLELINE] = options.config[:use_singleline]
    irb_conf[:USE_MULTILINE] = options.config[:use_multiline]
    pp irb_conf[:USE_MULTILINE]

    irb = IRB::Irb.new

    if solo_mode?
      # Setup the mocked ChefServer
      Chef::Config.local_mode = true
      Chef::LocalMode.setup_server_connectivity
    end

    init(irb.context.main)

    irb_conf[:IRB_RC].call(irb.context) if irb_conf[:IRB_RC]
    irb_conf[:MAIN_CONTEXT] = irb.context

    trap("SIGINT") do
      irb.signal_handle
    end

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  ensure
    # We destroy the mocked ChefServer
    Chef::LocalMode.destroy_server_connectivity if solo_mode?
  end

  def self.solo_mode?
    Chef::Config[:solo]
  end

  def self.setup_logger
    Chef::Config[:log_level] ||= :warn
    # If log_level is auto, change it to warn
    Chef::Config[:log_level] = :warn if Chef::Config[:log_level] == :auto
    Chef::Log.init(STDERR)
    Mixlib::Authentication::Log.logger = Ohai::Log.logger = Chef::Log.logger
    Chef::Log.level = Chef::Config[:log_level] || :warn
  end

  # Shell assumes it's running whenever it is defined
  def self.running?
    true
  end

  # Set the irb_conf object to something other than IRB.conf
  # useful for testing.
  def self.irb_conf=(conf_hash)
    @irb_conf = conf_hash
  end

  def self.irb_conf
    @irb_conf || IRB.conf
  end

  def self.configure_irb
    irb_conf[:HISTORY_FILE] = Chef::Util::PathHelper.home(".chef", "chef_shell_history")
    irb_conf[:SAVE_HISTORY] = 1000

    irb_conf[:IRB_RC] = lambda do |conf|
      m = conf.main

      conf.prompt_c       = "#{ChefUtils::Dist::Infra::EXEC}#{leader(m)} > "
      conf.return_format  = " => %s \n"
      conf.prompt_i       = "#{ChefUtils::Dist::Infra::EXEC}#{leader(m)} (#{Chef::VERSION})> "
      conf.prompt_n       = "#{ChefUtils::Dist::Infra::EXEC}#{leader(m)} ?> "
      conf.prompt_s       = "#{ChefUtils::Dist::Infra::EXEC}#{leader(m)}%l> "
      conf.use_tracer     = false
      conf.instance_variable_set(:@use_multiline, false)
      conf.instance_variable_set(:@use_singleline, false)
    end
  end

  def self.leader(main_object)
    env_string = Shell.env ? " (#{Shell.env})" : ""
    LEADERS[main_object.class] + env_string
  end

  def self.session
    unless client_type.instance.node_built?
      puts "Session type: #{client_type.session_type}"
      client_type.instance.json_configuration = @json_attribs
      client_type.instance.reset!
    end
    client_type.instance
  end

  def self.init(main)
    parse_json
    configure_irb

    session # trigger ohai run + session load

    session.node.consume_attributes(@json_attribs)

    Extensions.extend_context_object(main)

    main.version
    puts

    puts "run `help' for help, `exit' or ^D to quit."
    puts
  end

  def self.greeting
    "#{Etc.getlogin}@#{Shell.session.node["fqdn"]}"
  rescue NameError, ArgumentError
    ""
  end

  def self.parse_json
    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @json_attribs = config_fetcher.fetch_json
    end
  end

  def self.fatal!(message, exit_status)
    Chef::Log.fatal(message)
    exit exit_status
  end

  def self.client_type
    type = Shell::StandAloneSession
    type = Shell::SoloSession         if solo_mode?
    type = Shell::SoloLegacySession   if Chef::Config[:solo_legacy_shell]
    type = Shell::ClientSession       if Chef::Config[:client]
    type = Shell::DoppelGangerSession if Chef::Config[:doppelganger]
    type
  end

  def self.parse_opts
    @options = Options.new
    @options.parse_opts
  end

  def self.editor
    @editor || Chef::Config[:editor] || ENV["EDITOR"]
  end

  class Options
    include Mixlib::CLI
    include ChefConfig::Mixin::DotD

    def self.footer(text = nil)
      @footer = text if text
      @footer
    end

    banner("#{ChefUtils::Dist::Infra::SHELL} #{Chef::VERSION}\n\nUsage: #{ChefUtils::Dist::Infra::SHELL} [NAMED_CONF] (OPTIONS)")

    footer(<<~FOOTER)
      When no CONFIG is specified, #{ChefUtils::Dist::Infra::SHELL} attempts to load a default configuration file:
      * If a NAMED_CONF is given, #{ChefUtils::Dist::Infra::SHELL} will load ~/#{ChefUtils::Dist::Infra::USER_CONF_DIR}/NAMED_CONF/#{ChefUtils::Dist::Infra::SHELL_CONF}
      * If no NAMED_CONF is given #{ChefUtils::Dist::Infra::SHELL} will load ~/#{ChefUtils::Dist::Infra::USER_CONF_DIR}/#{ChefUtils::Dist::Infra::SHELL_CONF} if it exists
      * If no #{ChefUtils::Dist::Infra::SHELL_CONF} can be found, #{ChefUtils::Dist::Infra::SHELL} falls back to load:
            #{ChefConfig::Config.etc_chef_dir}/client.rb if -z option is given.
            #{ChefConfig::Config.etc_chef_dir}/solo.rb   if --solo-legacy-mode option is given.
            #{ChefUtils::Dist::Infra::USER_CONF_DIR}/config.rb     if -s option is given.
            #{ChefUtils::Dist::Infra::USER_CONF_DIR}/knife.rb      if -s option is given.
    FOOTER

    option :use_multiline,
      long: "--[no-]multiline",
      default: true,
      description: "[Do not] use multiline editor module"

    option :use_singleline,
      long: "--[no-]singleline",
      default: true,
      description: "[Do not] use singleline editor module"

    option :use_colorize,
      long: "--[no-]colorize",
      default: true,
      description: "[Do not] use colorization"

    option :config_file,
      short: "-c CONFIG",
      long: "--config CONFIG",
      description: "The configuration file to use"

    option :help,
      short: "-h",
      long: "--help",
      description: "Show this message",
      on: :tail,
      boolean: true,
      proc: proc { print_help }

    option :log_level,
      short: "-l LOG_LEVEL",
      long: "--log-level LOG_LEVEL",
      description: "Set the logging level",
      proc: proc { |level| Chef::Config.log_level = level.to_sym; Shell.setup_logger }

    option :standalone,
      short: "-a",
      long: "--standalone",
      description: "Standalone session",
      default: true,
      boolean: true

    option :solo_shell,
      short: "-s",
      long: "--solo",
      description: "#{ChefUtils::Dist::Solo::PRODUCT} session",
      boolean: true,
      proc: proc { Chef::Config[:solo] = true }

    option :client,
      short: "-z",
      long: "--client",
      description: "#{ChefUtils::Dist::Infra::PRODUCT} session",
      boolean: true

    option :solo_legacy_shell,
      long: "--solo-legacy-mode",
      description: "#{ChefUtils::Dist::Solo::PRODUCT} legacy session",
      boolean: true,
      proc: proc { Chef::Config[:solo_legacy_mode] = true }

    option :json_attribs,
      short: "-j JSON_ATTRIBS",
      long: "--json-attributes JSON_ATTRIBS",
      description: "Load attributes from a JSON file or URL",
      proc: nil

    option :chef_server_url,
      short: "-S CHEFSERVERURL",
      long: "--server CHEFSERVERURL",
      description: "The #{ChefUtils::Dist::Server::PRODUCT} URL",
      proc: nil

    option :version,
      short: "-v",
      long: "--version",
      description: "Show #{ChefUtils::Dist::Infra::PRODUCT} version",
      boolean: true,
      proc: lambda { |v| puts "#{ChefUtils::Dist::Infra::PRODUCT}: #{::Chef::VERSION}" },
      exit: 0

    option :override_runlist,
      short: "-o RunlistItem,RunlistItem...",
      long: "--override-runlist RunlistItem,RunlistItem...",
      description: "Replace current run list with specified items",
      proc: lambda { |items| items.split(",").map { |item| Chef::RunList::RunListItem.new(item) } }

    option :skip_cookbook_sync,
      long: "--[no-]skip-cookbook-sync",
      description: "Use cached cookbooks without overwriting local differences from the server",
      boolean: false

    def self.print_help
      instance = new
      instance.parse_options([])
      puts instance.opt_parser
      puts
      puts footer
      puts
      exit 1
    end

    def self.setup!
      new.parse_opts
    end

    def parse_opts
      remainder = parse_options
      environment = remainder.first
      # We have to nuke ARGV to make sure irb's option parser never sees it.
      # otherwise, IRB complains about command line switches it doesn't recognize.
      ARGV.clear

      # This code should not exist.
      # We should be using Application::Client and then calling load_config_file
      # which does all this properly. However this will do for now.
      config[:config_file] = config_file_for_shell_mode(environment)
      config_msg = config[:config_file] || "none (standalone session)"
      puts "loading configuration: #{config_msg}"

      # load the config (if we have one)
      unless config[:config_file].nil?
        if File.exist?(config[:config_file]) && File.readable?(config[:config_file])
          Chef::Config.from_file(config[:config_file])
        end

        # even if we couldn't load that, we need to tell Chef::Config what
        # the file was so it sets conf dir and d_dir and such properly
        Chef::Config[:config_file] = config[:config_file]

        # now attempt to load any relevant dot-dirs
        load_dot_d(Chef::Config[:client_d_dir]) if Chef::Config[:client_d_dir]
      end

      # finally merge command-line options in
      Chef::Config.merge!(config)
    end

    private

    # shamelessly lifted from application.rb
    def apply_config(config_content, config_file_path)
      Chef::Config.from_string(config_content, config_file_path)
    rescue Exception => error
      logger.fatal("Configuration error #{error.class}: #{error.message}")
      filtered_trace = error.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
      filtered_trace.each { |line| logger.fatal("  " + line ) }
      raise Chef::Exceptions::ConfigurationError.new("Aborting due to error in '#{config_file_path}': #{error}")
    end

    def config_file_for_shell_mode(environment)
      dot_chef_dir = Chef::Util::PathHelper.home(".chef")
      if config[:config_file]
        config[:config_file]
      elsif environment
        Shell.env = environment
        config_file_to_try = ::File.join(dot_chef_dir, environment, ChefUtils::Dist::Infra::SHELL_CONF)
        unless ::File.exist?(config_file_to_try)
          puts "could not find #{ChefUtils::Dist::Infra::SHELL} config for environment #{environment} at #{config_file_to_try}"
          exit 1
        end
        config_file_to_try
      elsif dot_chef_dir && ::File.exist?(File.join(dot_chef_dir, ChefUtils::Dist::Infra::SHELL_CONF))
        File.join(dot_chef_dir, ChefUtils::Dist::Infra::SHELL_CONF)
      elsif config[:solo_legacy_shell]
        Chef::Config.platform_specific_path("#{ChefConfig::Config.etc_chef_dir}/solo.rb")
      elsif config[:client]
        Chef::Config.platform_specific_path("#{ChefConfig::Config.etc_chef_dir}/client.rb")
      elsif config[:solo_shell]
        Chef::WorkstationConfigLoader.new(nil, Chef::Log).config_location
      else
        nil
      end
    end

  end

end
