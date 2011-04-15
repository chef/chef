#
# Author:: Daniel DeLeo (<dan@opscode.com)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'pp'
require 'optparse'
require 'chef/solr/version'
require 'chef/shell_out'
require 'chef/mixin/shell_out'

class Chef
  class SolrInstaller

    class Config
      class CompatConfig
        def initialize
          @config_settings = {}
        end

        def from_file(file)
          file = File.expand_path(file)
          if File.readable?(file)
            instance_eval(IO.read(file), file, 1)
          else
            STDERR.puts "Cannot open config file #{file} default settings will be used"
          end
          self
        end

        def method_missing(method_name, *args, &block)
          if args.size == 1
            @config_settings[method_name] = args.first
          elsif args.empty?
            @config_settings[method_name] or super
          else
            super
          end
        end

        def to_hash
          @config_settings
        end
      end


      def self.default_values
        @default_values ||= {}
      end

      def self.configurables
        @configurables ||= []
      end

      def self.configurable(value, default=nil)
        configurables << value
        attr_accessor value
        default_values[value] = default if default
      end

      def each_configurable
        self.class.configurables.each do |config_param|
          yield [config_param, send(config_param)]
        end
      end

      configurable :config_file, '/etc/chef/solr.rb'

      # Defaults to /var/chef
      configurable :solr_base_path, nil

      def solr_base_path
        @solr_base_path || '/var/chef'
      end

      # Sets the solr_base_path. Also resets solr_home_path, solr_jetty_path,
      # and solr_data_path.
      def solr_base_path=(base_path)
        @solr_home_path, @solr_jetty_path, @solr_data_path = nil,nil,nil
        @solr_base_path = base_path
      end


      # Computed from base path, defaults to /var/chef/solr
      configurable :solr_home_path, nil

      def solr_home_path
        @solr_home_path || File.join(solr_base_path, 'solr')
      end

      # Computed from base path, defaults to /var/chef/solr-jetty
      configurable :solr_jetty_path, nil

      def solr_jetty_path
        @solr_jetty_path || File.join(solr_base_path, 'solr-jetty')
      end

      # Computed from base path, defaults to /var/chef/solr/data
      configurable :solr_data_path, nil

      def solr_data_path
        @solr_data_path || File.join(solr_base_path, 'solr', 'data')
      end


      configurable :user, nil

      configurable :group, nil

      configurable :force, false

      alias :force? :force

      configurable :noop, false

      alias :noop? :noop

      def initialize
        apply_hash(self.class.default_values)
      end

      def configure_from(argv)
        cli_config = CLI.parse_options(argv)
        #pp :cli_config => cli_config.to_hash
        config_file_config = CompatConfig.new.from_file(cli_config.config_file).to_hash
        #pp :config_file_config => config_file_config
        apply_hash(config_file_config)
        apply_hash(cli_config.to_hash)
        #pp :combined_config => self.to_hash
        self
      end

      def to_hash
        self.class.configurables.inject({}) do |hash, config_option|
          value = instance_variable_get("@#{config_option}".to_sym)
          hash[config_option] = value if value
          hash
        end
      end

      def apply_hash(hash)
        hash.each do |key, value|
          method_for_key = "#{key}=".to_sym
          if respond_to?(method_for_key)
            send(method_for_key, value)
          else
            STDERR.puts("Configuration setting #{key} is unknown and will be ignored")
          end
        end
      end

      module CLI
        @config = Config.new

        @option_parser = OptionParser.new do |o|
          o.banner = "Usage: chef-solr-installer [options]"

          o.on('-c', '--config CONFIG_FILE', 'The configuration file to use') do |conf|
            @config.config_file = File.expand_path(conf)
          end

          o.on('-u', '--user USER', "User who will own Solr's data directory") do |u|
            @config.user = u
          end

          o.on('-g', '--group GROUP', "Group that will own Solr's data directory") do |g|
            @config.group = g
          end

          o.on('-p', '--base-path PATH', "The base path for the installation. Must be given before any -H -W or -D options") do |path|
            @config.solr_base_path = path
          end

          o.on('-H', '--solr-home-dir PATH', 'Where to create the Solr home directory. Defaults to BASE_PATH/solr') do |path|
            @config.solr_home_path = path
          end

          o.on('-W', '--solr-jetty-path PATH', 'Where to install Jetty for Solr. Defaults to BASE_PATH/solr-jetty ') do |path|
            @config.solr_jetty_path = path
          end

          o.on('-D', '--solr-data-path PATH', 'Where to create the Solr data directory. Defaults to BASE_PATH/solr/data') do |path|
            @config.solr_data_path = path
          end

          o.on('-n', '--noop', "Don't actually install, just show what would be done by the install") do
            @config.noop = true
          end

          o.on('-f', '--force', 'Overwrite any existing installation without asking for confirmation') do
            @config.force = true
          end

          o.on_tail('-h', '--help', 'show this message') do
            puts "chef-solr-installer #{Chef::Solr::VERSION}"
            puts ''
            puts o
            puts ''
            puts 'Default Settings:'
            @config.each_configurable do |param, value|
              value_for_display = value || "none/false"
              puts "  #{param}:".ljust(20) + " #{value_for_display}"
            end
            exit 1
          end

          o.on_tail('-v', '--version', 'show the version and exit') do
            puts "chef-solr-installer #{Chef::Solr::VERSION}"
            exit 0
          end

        end

        def self.parse_options(argv)
          @option_parser.parse!(argv.dup)
          @config
        end

        def self.config
          @config
        end

      end

    end

    include Chef::Mixin::ShellOut

    PACKAGED_SOLR_DIR = File.expand_path( "../../../../solr", __FILE__)

    attr_reader :config

    def initialize(argv)
      @indent = 0
      @config = Config.new.configure_from(argv.dup)
      @overwriting = false
    end

    def overwriting?
      @overwriting
    end

    def chef_solr_installed?
      File.exist?(config.solr_home_path)
    end

    def run
      say ''
      say "*** DRY RUN ***" if config.noop?

      if chef_solr_installed?
        @overwriting = true
        confirm_overwrite unless config.force? || config.noop?
        scorch_the_earth
      end

      create_solr_home
      create_solr_data_dir
      unpack_solr_jetty

      say ""
      say "Successfully installed Chef Solr."

      if overwriting?
        say "You can restore your search index using `knife index rebuild`"
      end
    end

    def confirm_overwrite
      if STDIN.tty? && STDOUT.tty?
        say "Chef Solr is already installed in #{config.solr_home_path}"
        print "Do you want to overwrite the current install? All existing Solr data will be lost. [y/n] "
        unless STDIN.gets =~ /^y/
          say "Quitting. Try running this with --noop to see what it will change."
          exit 1
        end
      else
        say(<<-FAIL)
ERROR: Chef Solr is already installed in #{config.solr_home_path} and you did not use the
--force option. Use --force to overwrite an existing installation in a non-
interactive terminal.
FAIL
        exit 1
      end
    end

    def scorch_the_earth
      group("Removing the existing Chef Solr installation") do
        rm_rf(config.solr_home_path)
        rm_rf(config.solr_jetty_path)
        rm_rf(config.solr_data_path)
      end
    end

    def create_solr_home
      group("Creating Solr Home Directory") do
        mkdir_p(config.solr_home_path)
        chdir(config.solr_home_path) do
          sh("tar zxvf #{File.join(PACKAGED_SOLR_DIR, 'solr-home.tar.gz')}")
        end
      end
    end

    def create_solr_data_dir
      group("Creating Solr Data Directory") do
        mkdir_p(config.solr_data_path)
        chown(config.solr_data_path)
      end
    end

    def unpack_solr_jetty
      group("Unpacking Solr Jetty") do
        mkdir_p(config.solr_jetty_path)
        chdir(config.solr_jetty_path) do
          sh("tar zxvf #{File.join(PACKAGED_SOLR_DIR, 'solr-jetty.tar.gz')}")
        end
        chown(config.solr_jetty_path)
      end
    end

    def mkdir_p(directory)
      say "mkdir -p #{directory}"
      FileUtils.mkdir_p(directory, :mode => 0755) unless config.noop?
    end

    def chdir(dir, &block)
      say "entering #{dir}"
      if config.noop?
        yield if block_given? # still call the block so we get the noop output.
      else
        Dir.chdir(dir) { yield if block_given? }
      end
    end

    def sh(*args)
      opts = args[1, args.size - 1]
      opts_msg = opts.empty? ? '' : " #{opts.to_s}"
      say "#{args.first}#{opts_msg}"
      shell_out!(*(args << {:cwd => false})) unless config.noop?
    end

    def chown(file)
      if config.user
        msg = "chown -R #{config.user}"
        msg << ":#{config.group}" if config.group
        msg << " #{file}"
        say msg
        FileUtils.chown_R(config.user, config.group, file) unless config.noop?
      end
    end

    def rm_rf(path)
      say "rm -rf #{path}"
      FileUtils.rm_rf(path) unless config.noop?
    end

    def indent
      @indent += 1
      yield
      @indent -= 1
    end

    def group(message, &block)
      say(message)
      indent(&block)
    end

    def say(message)
      puts "#{' ' * (2 * @indent)}#{message}"
    end

  end
end

