#
# Author:: Adam Jacob (<adam@chef.io)
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

require "chef/application"
require_relative "../knife"
require "mixlib/log"
require "ohai/config"
module Net
  autoload :HTTP, "net/http"
end
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef::Application::Knife < Chef::Application

  NO_COMMAND_GIVEN = "You need to pass a sub-command (e.g., knife SUB-COMMAND)\n".freeze

  banner "Usage: knife sub-command (options)"

  option :config_file,
    short: "-c CONFIG",
    long: "--config CONFIG",
    description: "The configuration file to use.",
    proc: lambda { |path| File.expand_path(path, Dir.pwd) }

  option :config_option,
    long: "--config-option OPTION=VALUE",
    description: "Override a single configuration option.",
    proc: lambda { |option, existing|
      (existing ||= []) << option
      existing
    }

  verbosity_level = 0
  option :verbosity,
    short: "-V",
    long: "--verbose",
    description: "More verbose output. Use twice (-VV) for additional verbosity and three times (-VVV) for maximum verbosity.",
    proc: Proc.new { verbosity_level += 1 },
    default: 0

  option :color,
    long: "--[no-]color",
    boolean: true,
    default: true,
    description: "Use colored output, defaults to enabled."

  option :environment,
    short: "-E ENVIRONMENT",
    long: "--environment ENVIRONMENT",
    description: "Set the #{ChefUtils::Dist::Infra::PRODUCT} environment (except for in searches, where this will be flagrantly ignored)."

  option :editor,
    short: "-e EDITOR",
    long: "--editor EDITOR",
    description: "Set the editor to use for interactive commands.",
    default: ENV["EDITOR"]

  option :disable_editing,
    short: "-d",
    long: "--disable-editing",
    description: "Do not open EDITOR, just accept the data as is.",
    boolean: true,
    default: false

  option :help,
    short: "-h",
    long: "--help",
    description: "Show this help message.",
    on: :tail,
    boolean: true

  option :node_name,
    short: "-u USER",
    long: "--user USER",
    description: "#{ChefUtils::Dist::Server::PRODUCT} API client username."

  option :client_key,
    short: "-k KEY",
    long: "--key KEY",
    description: "#{ChefUtils::Dist::Server::PRODUCT} API client key.",
    proc: lambda { |path| File.expand_path(path, Dir.pwd) }

  option :chef_server_url,
    short: "-s URL",
    long: "--server-url URL",
    description: "#{ChefUtils::Dist::Server::PRODUCT} URL."

  option :yes,
    short: "-y",
    long: "--yes",
    description: "Say yes to all prompts for confirmation."

  option :defaults,
    long: "--defaults",
    description: "Accept default values for all questions."

  option :print_after,
    long: "--print-after",
    description: "Show the data after a destructive operation."

  option :format,
    short: "-F FORMAT",
    long: "--format FORMAT",
    description: "Which format to use for output.",
    in: %w{summary text json yaml pp},
    default: "summary"

  option :local_mode,
    short: "-z",
    long: "--local-mode",
    description: "Point knife commands at local repository instead of #{ChefUtils::Dist::Server::PRODUCT}.",
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

  option :version,
    short: "-v",
    long: "--version",
    description: "Show #{ChefUtils::Dist::Infra::PRODUCT} version.",
    boolean: true,
    proc: lambda { |v| puts "#{ChefUtils::Dist::Infra::PRODUCT}: #{::Chef::VERSION}" },
    exit: 0

  option :fips,
    long: "--[no-]fips",
    description: "Enable FIPS mode.",
    boolean: true,
    default: nil

  option :profile,
    long: "--profile PROFILE",
    description: "The credentials profile to select."

  # Run knife
  def run
    ChefConfig::PathHelper.per_tool_home_environment = "KNIFE_HOME"
    Mixlib::Log::Formatter.show_time = false
    validate_and_parse_options
    quiet_traps
    Chef::Knife.run(ARGV, options)
    exit 0
  end

  private

  def quiet_traps
    trap("TERM") do
      exit 1
    end

    trap("INT") do
      exit 2
    end
  end

  def validate_and_parse_options
    # Checking ARGV validity *before* parse_options because parse_options
    # mangles ARGV in some situations
    if no_command_given?
      print_help_and_exit(1, NO_COMMAND_GIVEN)
    elsif no_subcommand_given?
      if want_help? || want_version?
        print_help_and_exit(0)
      else
        print_help_and_exit(2, NO_COMMAND_GIVEN)
      end
    end
  end

  def no_subcommand_given?
    ARGV[0] =~ /^-/
  end

  def no_command_given?
    ARGV.empty?
  end

  def want_help?
    ARGV[0] =~ /^(--help|-h)$/
  end

  def want_version?
    ARGV[0] =~ /^(--version|-v)$/
  end

  def print_help_and_exit(exitcode = 1, fatal_message = nil)
    Chef::Log.error(fatal_message) if fatal_message

    begin
      parse_options
    rescue OptionParser::InvalidOption => e
      puts "#{e}\n"
    end

    if want_help?
      puts "#{ChefUtils::Dist::Infra::PRODUCT}: #{Chef::VERSION}"
      puts
      puts "Docs: #{ChefUtils::Dist::Org::KNIFE_DOCS}"
      puts "Patents: #{ChefUtils::Dist::Org::PATENTS}"
      puts
    end

    puts opt_parser
    puts
    Chef::Knife.list_commands
    exit exitcode
  end

end
