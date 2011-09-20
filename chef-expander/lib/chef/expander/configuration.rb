#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require 'pp'
require 'optparse'
require 'singleton'

require 'chef/expander/flattener'
require 'chef/expander/loggable'
require 'chef/expander/version'

module Chef
  module Expander

    def self.config
      @config ||= Configuration::Base.new
    end

    def self.init_config(argv)
      config.apply_defaults
      remaining_opts_after_parse = Configuration::CLI.parse_options(argv)
      # Need to be able to override the default config file location on the command line
      config_file_to_use = Configuration::CLI.config.config_file || config.config_file
      config.merge_config(Configuration::Base.from_chef_compat_config(config_file_to_use))
      # But for all other config options, the CLI config should win over config file
      config.merge_config(Configuration::CLI.config)
      config.validate!
      remaining_opts_after_parse
    end

    class ChefCompatibleConfig

      attr_reader :config_hash

      def initialize
        @config_hash = {}
      end

      def load(file)
        file = File.expand_path(file)
        instance_eval(IO.read(file), file, 1) if File.readable?(file)
      end

      def method_missing(method_name, *args, &block)
        if args.size == 1
          @config_hash[method_name] = args.first
        elsif args.empty?
          @config_hash[method_name] or super
        else
          super
        end
      end

    end

    module Configuration

      class InvalidConfiguration < StandardError
      end

      class Base

        DEFAULT_PIDFILE = Object.new

        include Loggable

        def self.from_chef_compat_config(file)
          config = ChefCompatibleConfig.new
          config.load(file)
          from_hash(config.config_hash)
        end

        def self.from_hash(config_hash)
          config = new
          config_hash.each do |setting, value|
            setter = "#{setting}=".to_sym
            if config.respond_to?(setter)
              config.send(setter, value)
            end
          end
          config
        end

        def self.configurables
          @configurables ||= []
        end

        def self.validations
          @validations ||= []
        end

        def self.defaults
          @defaults ||= {}
        end

        def self.configurable(setting, default=nil, &validation)
          attr_accessor(setting)
          configurables << setting
          defaults[setting] = default
          validations << validation if block_given?

          setting
        end

        configurable :config_file, "/etc/chef/solr.rb" do
          unless (config_file && File.exist?(config_file) && File.readable?(config_file))
            log.warn {"* " * 40}
            log.warn {"Config file #{config_file} does not exist or cannot be read by user (#{Process.euid})"}
            log.warn {"Default configuration settings will be used"}
            log.warn {"* " * 40}
          end
        end

        configurable :index do
          unless index.nil? # in single-cluster mode, this setting is not required.
            invalid("You must specify this node's position in the ring as an integer") unless index.kind_of?(Integer)
            invalid("The index cannot be larger than the cluster size (node-count)") unless (index.to_i <= node_count.to_i)
          end
        end

        configurable :node_count, 1 do
          invalid("You must specify the node_count as an integer") unless node_count.kind_of?(Integer)
          invalid("The node_count must be 1 or greater") unless node_count >= 1
          invalid("The node_count cannot be smaller than the index") unless node_count >= index.to_i
        end

        configurable :ps_tag, ""

        configurable :solr_url, "http://localhost:8983"

        configurable :amqp_host, '0.0.0.0'

        configurable :amqp_port, 5672

        configurable :amqp_user, 'chef'

        configurable :amqp_pass, 'testing'

        configurable :amqp_vhost, '/chef'

        configurable :user, nil

        configurable :group, nil

        configurable :daemonize, false

        alias :daemonize? :daemonize

        configurable :pidfile, DEFAULT_PIDFILE

        def pidfile
          if @pidfile.equal?(DEFAULT_PIDFILE)
            Process.euid == 0 ? '/var/run/chef-expander.pid' : '/tmp/chef-expander.pid'
          else
            @pidfile
          end
        end

        configurable :log_level, :info

        # override the setter for log_level to also actually set the level
        def log_level=(level)
          if level #don't accept nil for an answer
            level = level.to_sym
            Loggable::LOGGER.level = level
            @log_level = log_level
          end
          level
        end

        configurable :log_location, STDOUT

        # override the setter for log_location to re-init the logger
        def log_location=(location)
          Loggable::LOGGER.init(location) unless location.nil?
        end

        def initialize
          reset!
        end

        def reset!(stdout=nil)
          self.class.configurables.each do |setting|
            send("#{setting}=".to_sym, nil)
          end
          @stdout = stdout || STDOUT
        end

        def apply_defaults
          self.class.defaults.each do |setting, value|
            self.send("#{setting}=".to_sym, value)
          end
        end

        def merge_config(other)
          self.class.configurables.each do |setting|
            value = other.send(setting)
            self.send("#{setting}=".to_sym, value) if value
          end
        end

        def fail_if_invalid
          validate!
        rescue InvalidConfiguration => e
          @stdout.puts("Invalid configuration: #{e.message}")
          exit(1)
        end

        def invalid(message)
          raise InvalidConfiguration, message
        end

        def validate!
          self.class.validations.each do |validation_proc|
            instance_eval(&validation_proc)
          end
        end

        def vnode_numbers
          vnodes_per_node = VNODES / node_count
          lower_bound = (index - 1) * vnodes_per_node
          upper_bound = lower_bound  + vnodes_per_node
          upper_bound += VNODES % vnodes_per_node if index == node_count
          (lower_bound...upper_bound).to_a
        end

        def amqp_config
          {:host => amqp_host, :port => amqp_port, :user => amqp_user, :pass => amqp_pass, :vhost => amqp_vhost}
        end

      end

      module CLI
        @config = Configuration::Base.new

        @option_parser = OptionParser.new do |o|
          o.banner = "Usage: chef-expander [options]"

          o.on('-c', '--config CONFIG_FILE', 'a configuration file to use') do |conf|
            @config.config_file = File.expand_path(conf)
          end

          o.on('-i', '--index INDEX', 'the slot this node will occupy in the ring') do |i|
            @config.index = i.to_i
          end

          o.on('-n', '--node-count NUMBER', 'the number of nodes in the ring') do |n|
            @config.node_count = n.to_i
          end

          o.on('-l', '--log-level LOG_LEVEL', 'set the log level') do |l|
            @config.log_level = l
          end

          o.on('-L', '--logfile LOG_LOCATION', 'Logfile to use') do |l|
            @config.log_location = l
          end

          o.on('-d', '--daemonize', 'fork into the background') do
            @config.daemonize = true
          end

          o.on('-P', '--pid PIDFILE') do |p|
            @config.pidfile = p
          end

          o.on_tail('-h', '--help', 'show this message') do
            puts "chef-expander #{Expander.version}"
            puts ''
            puts o
            exit 1
          end

          o.on_tail('-v', '--version', 'show the version and exit') do
            puts "chef-expander #{Expander.version}"
            exit 0
          end

        end

        def self.parse_options(argv)
          @option_parser.parse!(argv.dup)
        end

        def self.config
          @config
        end

      end

    end

  end
end
