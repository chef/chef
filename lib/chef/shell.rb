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

require "singleton"
require "pp"
require "etc"
require "mixlib/cli"

require "chef"
require "chef/version"
require "chef/client"
require "chef/config"
require "chef/config_fetcher"

require "chef/shell/shell_session"
require "chef/workstation_config_loader"
require "chef/shell/ext"
require "chef/json_compat"
require "chef/util/path_helper"

# = Shell
# Shell is Chef in an IRB session. Shell can interact with a Chef server via the
# REST API, and run and debug recipes interactively.
module Shell
  LEADERS = Hash.new("")
  LEADERS[Chef::Recipe] = ":recipe"
  LEADERS[Chef::Node]   = ":attributes"

  class << self
    attr_accessor :client_type
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
  # usful for testing.
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

      conf.prompt_c       = "chef#{leader(m)} > "
      conf.return_format  = " => %s \n"
      conf.prompt_i       = "chef#{leader(m)} (#{Chef::VERSION})> "
      conf.prompt_n       = "chef#{leader(m)} ?> "
      conf.prompt_s       = "chef#{leader(m)}%l> "
      conf.use_tracer     = false
    end
  end

  def self.leader(main_object)
    env_string = Shell.env ? " (#{Shell.env})" : ""
    LEADERS[main_object.class] + env_string
  end

  def self.session
    unless client_type.instance.node_built?
      puts "Session type: #{client_type.session_type}"
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
    puts "Ohai2u#{greeting}!"
  end

  def self.greeting
    " #{Etc.getlogin}@#{Shell.session.node["fqdn"]}"
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

    def self.footer(text = nil)
      @footer = text if text
      @footer
    end

    banner("chef-shell #{Chef::VERSION}\n\nUsage: chef-shell [NAMED_CONF] (OPTIONS)")

    footer(<<-FOOTER)
When no CONFIG is specified, chef-shell attempts to load a default configuration file:
* If a NAMED_CONF is given, chef-shell will load ~/.chef/NAMED_CONF/chef_shell.rb
* If no NAMED_CONF is given chef-shell will load ~/.chef/chef_shell.rb if it exists
* If no chef_shell.rb can be found, chef-shell falls back to load:
      /etc/chef/client.rb if -z option is given.
      /etc/chef/solo.rb   if --solo-legacy-mode option is given.
      .chef/knife.rb      if -s option is given.
FOOTER

    option :config_file,
      :short => "-c CONFIG",
      :long  => "--config CONFIG",
      :description => "The configuration file to use"

    option :help,
      :short        => "-h",
      :long         => "--help",
      :description  => "Show this message",
      :on           => :tail,
      :boolean      => true,
      :proc         => proc { print_help }

    option :log_level,
      :short  => "-l LOG_LEVEL",
      :long   => "--log-level LOG_LEVEL",
      :description => "Set the logging level",
      :proc         => proc { |level| Chef::Config.log_level = level.to_sym; Shell.setup_logger }

    option :standalone,
      :short        => "-a",
      :long         => "--standalone",
      :description  => "standalone session",
      :default      => true,
      :boolean      => true

    option :solo_shell,
      :short        => "-s",
      :long         => "--solo",
      :description  => "chef-solo session",
      :boolean      => true,
      :proc         => proc { Chef::Config[:solo] = true }

    option :client,
      :short        => "-z",
      :long         => "--client",
      :description  => "chef-client session",
      :boolean      => true

    option :solo_legacy_shell,
      :long         => "--solo-legacy-mode",
      :description  => "chef-solo legacy session",
      :boolean      => true,
      :proc         => proc { Chef::Config[:solo_legacy_mode] = true }

    option :json_attribs,
      :short => "-j JSON_ATTRIBS",
      :long => "--json-attributes JSON_ATTRIBS",
      :description => "Load attributes from a JSON file or URL",
      :proc => nil

    option :chef_server_url,
      :short => "-S CHEFSERVERURL",
      :long => "--server CHEFSERVERURL",
      :description => "The chef server URL",
      :proc => nil

    option :version,
      :short        => "-v",
      :long         => "--version",
      :description  => "Show chef version",
      :boolean      => true,
      :proc         => lambda { |v| puts "Chef: #{::Chef::VERSION}" },
      :exit         => 0

    option :override_runlist,
      :short        => "-o RunlistItem,RunlistItem...",
      :long         => "--override-runlist RunlistItem,RunlistItem...",
      :description  => "Replace current run list with specified items",
      :proc         => lambda { |items| items.split(",").map { |item| Chef::RunList::RunListItem.new(item) } }

    option :skip_cookbook_sync,
      :long           => "--[no-]skip-cookbook-sync",
      :description    => "Use cached cookbooks without overwriting local differences from the server",
      :boolean        => false

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
      config[:config_file] = config_file_for_shell_mode(environment)
      config_msg = config[:config_file] || "none (standalone session)"
      puts "loading configuration: #{config_msg}"
      Chef::Config.from_file(config[:config_file]) if !config[:config_file].nil? && File.exists?(config[:config_file]) && File.readable?(config[:config_file])
      Chef::Config.merge!(config)
    end

    private

    def config_file_for_shell_mode(environment)
      dot_chef_dir = Chef::Util::PathHelper.home(".chef")
      if config[:config_file]
        config[:config_file]
      elsif environment
        Shell.env = environment
        config_file_to_try = ::File.join(dot_chef_dir, environment, "chef_shell.rb")
        unless ::File.exist?(config_file_to_try)
          puts "could not find chef-shell config for environment #{environment} at #{config_file_to_try}"
          exit 1
        end
        config_file_to_try
      elsif dot_chef_dir && ::File.exist?(File.join(dot_chef_dir, "chef_shell.rb"))
        File.join(dot_chef_dir, "chef_shell.rb")
      elsif config[:solo_legacy_shell]
        Chef::Config.platform_specific_path("/etc/chef/solo.rb")
      elsif config[:client]
        Chef::Config.platform_specific_path("/etc/chef/client.rb")
      elsif config[:solo_shell]
        Chef::WorkstationConfigLoader.new(nil, Chef::Log).config_location
      else
        nil
      end
    end

  end

end
