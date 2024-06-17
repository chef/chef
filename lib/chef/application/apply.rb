#
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2012-2016, Bryan W. Berry
# Copyright:: Copyright 2012-2016, Daniel DeLeo
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

require_relative "../../chef"
require_relative "../application"
require_relative "../client"
require_relative "../config"
require_relative "../config_fetcher"
require_relative "../log"
require "fileutils" unless defined?(FileUtils)
require "tempfile" unless defined?(Tempfile)
require_relative "../providers"
require_relative "../resources"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "license_acceptance/cli_flags/mixlib_cli"
require "chef-licensing/cli_flags/mixlib_cli"
require_relative "../licensing"

class Chef::Application::Apply < Chef::Application
  include LicenseAcceptance::CLIFlags::MixlibCLI
  include ChefLicensing::CLIFlags::MixlibCLI

  banner "Usage: #{ChefUtils::Dist::Apply::EXEC} [RECIPE_FILE | -e RECIPE_TEXT | -s] [OPTIONS]"

  option :execute,
    short: "-e RECIPE_TEXT",
    long: "--execute RECIPE_TEXT",
    description: "Execute resources supplied in a string.",
    proc: nil

  option :stdin,
    short: "-s",
    long: "--stdin",
    description: "Execute resources read from STDIN.",
    boolean: true

  option :json_attribs,
    short: "-j JSON_ATTRIBS",
    long: "--json-attributes JSON_ATTRIBS",
    description: "Load attributes from a JSON file or URL.",
    proc: nil

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

  option :formatter,
    short: "-F FORMATTER",
    long: "--format FORMATTER",
    description: "The output format to use.",
    proc: lambda { |format| Chef::Config.add_formatter(format) }

  option :log_level,
    short: "-l LEVEL",
    long: "--log_level LEVEL",
    description: "Set the log level (trace, debug, info, warn, error, fatal).",
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
    proc: proc { print_help }

  option :version,
    short: "-v",
    long: "--version",
    description: "Show #{ChefUtils::Dist::Infra::PRODUCT} version.",
    boolean: true,
    proc: lambda { |v| puts "#{ChefUtils::Dist::Infra::PRODUCT}: #{::Chef::VERSION}" },
    exit: 0

  option :why_run,
    short: "-W",
    long: "--why-run",
    description: "Enable whyrun mode.",
    boolean: true

  option :yaml,
    long: "--yaml",
    description: "Parse recipe as YAML",
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

  option :minimal_ohai,
    long: "--minimal-ohai",
    description: "Only run the bare minimum Ohai plugins #{ChefUtils::Dist::Infra::PRODUCT} needs to function.",
    boolean: true

  if ChefUtils::Dist::Apply::EXEC == "chef-apply"
    option :license_add,
        long: "--license-add",
        description: "Add a license key to the license pool.",
        boolean: true,
        proc: lambda { |v| Chef::Licensing.license_add },
        exit: 0

    option :license_list,
        long: "--license-list",
        description: "List all license keys in the license pool.",
        boolean: true,
        proc: lambda { |v| Chef::Licensing.license_list },
        exit: 0
  end

  attr_reader :json_attribs

  def self.print_help
    instance = new
    instance.parse_options([])
    puts instance.opt_parser
    puts Chef::Licensing.licensing_help if ChefUtils::Dist::Apply::EXEC == "chef-apply"
    exit 0
  end

  def initialize
    super
  end

  def reconfigure
    parse_options
    Chef::Config.merge!(config)
    configure_logging
    Chef::Config.export_proxies
    Chef::Config.init_openssl
    parse_json
  end

  def parse_json
    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @json_attribs = config_fetcher.fetch_json
    end
  end

  def read_recipe_file(file_name)
    if file_name.nil?
      Chef::Application.fatal!("No recipe file was provided", Chef::Exceptions::RecipeNotFound.new)
    else
      recipe_path = File.expand_path(file_name)
      unless File.exist?(recipe_path)
        Chef::Application.fatal!("No file exists at #{recipe_path}", Chef::Exceptions::RecipeNotFound.new)
      end
      recipe_fh = open(recipe_path)
      recipe_text = recipe_fh.read
      [recipe_text, recipe_fh]
    end
  end

  def get_recipe_and_run_context
    Chef::Config[:solo_legacy_mode] = true
    @chef_client = Chef::Client.new(@json_attribs)
    @chef_client.run_ohai
    @chef_client.load_node
    @chef_client.build_node
    run_context = if @chef_client.events.nil?
                    Chef::RunContext.new(@chef_client.node, {})
                  else
                    Chef::RunContext.new(@chef_client.node, {}, @chef_client.events)
                  end
    recipe = Chef::Recipe.new("(#{ChefUtils::Dist::Apply::EXEC} cookbook)", "(#{ChefUtils::Dist::Apply::EXEC} recipe)", run_context)
    [recipe, run_context]
  end

  # write recipe to temp file, so in case of error,
  # user gets error w/ context
  def temp_recipe_file
    @recipe_fh = Tempfile.open("recipe-temporary-file")
    @recipe_fh.write(@recipe_text)
    @recipe_fh.rewind
    @recipe_filename = @recipe_fh.path
  end

  def run_chef_recipe
    if config[:execute]
      @recipe_text = config[:execute]
      temp_recipe_file
    elsif config[:stdin]
      @recipe_text = STDIN.read
      temp_recipe_file
    else
      unless ARGV[0]
        puts opt_parser
        Chef::Application.exit! "No recipe file provided", Chef::Exceptions::RecipeNotFound.new
      end
      @recipe_filename = ARGV[0]
      @recipe_text, @recipe_fh = read_recipe_file @recipe_filename
    end
    recipe, run_context = get_recipe_and_run_context
    if config[:yaml] || File.extname(@recipe_filename) == ".yml"
      logger.info "Parsing recipe as YAML"
      recipe.from_yaml(@recipe_text)
    else
      recipe.instance_eval(@recipe_text, @recipe_filename, 1)
    end
    runner = Chef::Runner.new(run_context)
    catch(:end_client_run_early) do

      runner.converge
    ensure
      @recipe_fh.close

    end
    Chef::Platform::Rebooter.reboot_if_needed!(runner)
  end

  def run_application
    Chef::Licensing.check_software_entitlement! if ChefUtils::Dist::Apply::EXEC == "chef-apply"
    parse_options
    run_chef_recipe
    Chef::Application.exit! "Exiting", 0
  rescue SystemExit
    raise
  rescue Exception => e
    Chef::Application.debug_stacktrace(e)
    Chef::Application.fatal!("#{e.class}: #{e.message}", e)
  end

  # Get this party started
  def run(enforce_license: false)
    reconfigure
    check_license_acceptance if enforce_license
    Chef::Licensing.fetch_and_persist if ChefUtils::Dist::Apply::EXEC == "chef-apply"
    run_application
  end
end
