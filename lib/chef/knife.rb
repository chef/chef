#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'forwardable'
require 'chef/version'
require 'mixlib/cli'
require 'chef/workstation_config_loader'
require 'chef/mixin/convert_to_class_name'
require 'chef/mixin/path_sanity'
require 'chef/knife/core/subcommand_loader'
require 'chef/knife/core/ui'
require 'chef/local_mode'
require 'chef/rest'
require 'pp'
require 'chef/util/path_helper'

class Chef
  class Knife

    Chef::REST::RESTRequest.user_agent = "Chef Knife#{Chef::REST::RESTRequest::UA_COMMON}"

    include Mixlib::CLI
    include Chef::Mixin::PathSanity
    extend Chef::Mixin::ConvertToClassName
    extend Forwardable

    # Backwards Compat:
    # Ideally, we should not vomit all of these methods into this base class;
    # instead, they should be accessed by hitting the ui object directly.
    def_delegator :@ui, :stdout
    def_delegator :@ui, :stderr
    def_delegator :@ui, :stdin
    def_delegator :@ui, :msg
    def_delegator :@ui, :ask_question
    def_delegator :@ui, :pretty_print
    def_delegator :@ui, :output
    def_delegator :@ui, :format_list_for_display
    def_delegator :@ui, :format_for_display
    def_delegator :@ui, :format_cookbook_list_for_display
    def_delegator :@ui, :edit_data
    def_delegator :@ui, :edit_object
    def_delegator :@ui, :confirm

    attr_accessor :name_args
    attr_accessor :ui

    # Configure mixlib-cli to always separate defaults from user-supplied CLI options
    def self.use_separate_defaults?
      true
    end

    def self.ui
      @ui ||= Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    end

    def self.msg(msg="")
      ui.msg(msg)
    end

    def self.reset_subcommands!
      @@subcommands = {}
      @subcommands_by_category = nil
    end

    def self.inherited(subclass)
      unless subclass.unnamed?
        subcommands[subclass.snake_case_name] = subclass
      end
    end

    # Explicitly set the category for the current command to +new_category+
    # The category is normally determined from the first word of the command
    # name, but some commands make more sense using two or more words
    # ===Arguments
    # new_category::: A String to set the category to (see examples)
    # ===Examples:
    # Data bag commands would be in the 'data' category by default. To put them
    # in the 'data bag' category:
    #   category('data bag')
    def self.category(new_category)
      @category = new_category
    end

    def self.subcommand_category
      @category || snake_case_name.split('_').first unless unnamed?
    end

    def self.snake_case_name
      convert_to_snake_case(name.split('::').last) unless unnamed?
    end

    def self.common_name
      snake_case_name.split('_').join(' ')
    end

    # Does this class have a name? (Classes created via Class.new don't)
    def self.unnamed?
      name.nil? || name.empty?
    end

    def self.subcommand_loader
      @subcommand_loader ||= Knife::SubcommandLoader.new(chef_config_dir)
    end

    def self.load_commands
      @commands_loaded ||= subcommand_loader.load_commands
    end

    def self.subcommands
      @@subcommands ||= {}
    end

    def self.subcommands_by_category
      unless @subcommands_by_category
        @subcommands_by_category = Hash.new { |hash, key| hash[key] = [] }
        subcommands.each do |snake_cased, klass|
          @subcommands_by_category[klass.subcommand_category] << snake_cased
        end
      end
      @subcommands_by_category
    end

    # Print the list of subcommands knife knows about. If +preferred_category+
    # is given, only subcommands in that category are shown
    def self.list_commands(preferred_category=nil)
      load_commands

      category_desc = preferred_category ? preferred_category + " " : ''
      msg "Available #{category_desc}subcommands: (for details, knife SUB-COMMAND --help)\n\n"

      if preferred_category && subcommands_by_category.key?(preferred_category)
        commands_to_show = {preferred_category => subcommands_by_category[preferred_category]}
      else
        commands_to_show = subcommands_by_category
      end

      commands_to_show.sort.each do |category, commands|
        next if category =~ /deprecated/i
        msg "** #{category.upcase} COMMANDS **"
        commands.sort.each do |command|
          msg subcommands[command].banner if subcommands[command]
        end
        msg
      end
    end

    # Shared with subclasses
    @@chef_config_dir = nil

    def self.load_config(explicit_config_file)
      config_loader = WorkstationConfigLoader.new(explicit_config_file, Chef::Log)
      Chef::Log.debug("Using configuration from #{config_loader.config_location}")
      config_loader.load

      ui.warn("No knife configuration file found") if config_loader.no_config_found?
      @@chef_config_dir = config_loader.chef_config_dir

      config_loader
    rescue Exceptions::ConfigurationError => e
      ui.error(ui.color("CONFIGURATION ERROR:", :red) + e.message)
      exit 1
    end

    def self.chef_config_dir
      @@chef_config_dir
    end

    # Run knife for the given +args+ (ARGV), adding +options+ to the list of
    # CLI options that the subcommand knows how to handle.
    # ===Arguments
    # args::: usually ARGV
    # options::: A Mixlib::CLI option parser hash. These +options+ are how
    # subcommands know about global knife CLI options
    def self.run(args, options={})
      # Fallback debug logging. Normally the logger isn't configured until we
      # read the config, but this means any logging that happens before the
      # config file is read may be lost. If the KNIFE_DEBUG variable is set, we
      # setup the logger for debug logging to stderr immediately to catch info
      # from early in the setup process.
      if ENV['KNIFE_DEBUG']
        Chef::Log.init($stderr)
        Chef::Log.level(:debug)
      end

      load_commands
      subcommand_class = subcommand_class_from(args)
      subcommand_class.options = options.merge!(subcommand_class.options)
      subcommand_class.load_deps
      instance = subcommand_class.new(args)
      instance.configure_chef
      instance.run_with_pretty_exceptions
    end

    def self.guess_category(args)
      category_words = args.select {|arg| arg =~ /^(([[:alnum:]])[[:alnum:]\_\-]+)$/ }
      category_words.map! {|w| w.split('-')}.flatten!
      matching_category = nil
      while (!matching_category) && (!category_words.empty?)
        candidate_category = category_words.join(' ')
        matching_category = candidate_category if subcommands_by_category.key?(candidate_category)
        matching_category || category_words.pop
      end
      matching_category
    end

    def self.subcommand_class_from(args)
      command_words = args.select {|arg| arg =~ /^(([[:alnum:]])[[:alnum:]\_\-]+)$/ }

      subcommand_class = nil

      while ( !subcommand_class ) && ( !command_words.empty? )
        snake_case_class_name = command_words.join("_")
        unless subcommand_class = subcommands[snake_case_class_name]
          command_words.pop
        end
      end
      # see if we got the command as e.g., knife node-list
      subcommand_class ||= subcommands[args.first.gsub('-', '_')]
      subcommand_class || subcommand_not_found!(args)
    end

    def self.dependency_loaders
      @dependency_loaders ||= []
    end

    def self.deps(&block)
      dependency_loaders << block
    end

    def self.load_deps
      dependency_loaders.each do |dep_loader|
        dep_loader.call
      end
    end

    private

    OFFICIAL_PLUGINS = %w[ec2 rackspace windows openstack terremark bluebox]

    # :nodoc:
    # Error out and print usage. probably becuase the arguments given by the
    # user could not be resolved to a subcommand.
    def self.subcommand_not_found!(args)
      ui.fatal("Cannot find sub command for: '#{args.join(' ')}'")

      if category_commands = guess_category(args)
        list_commands(category_commands)
      elsif missing_plugin = ( OFFICIAL_PLUGINS.find {|plugin| plugin == args[0]} )
        ui.info("The #{missing_plugin} commands were moved to plugins in Chef 0.10")
        ui.info("You can install the plugin with `(sudo) gem install knife-#{missing_plugin}")
      else
        list_commands
      end

      exit 10
    end

    def self.reset_config_path!
      @@chef_config_dir = nil
    end

    reset_config_path!

    public

    # Create a new instance of the current class configured for the given
    # arguments and options
    def initialize(argv=[])
      super() # having to call super in initialize is the most annoying anti-pattern :(
      @ui = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, config)

      command_name_words = self.class.snake_case_name.split('_')

      # Mixlib::CLI ignores the embedded name_args
      @name_args = parse_options(argv)
      @name_args.delete(command_name_words.join('-'))
      @name_args.reject! { |name_arg| command_name_words.delete(name_arg) }

      # knife node run_list add requires that we have extra logic to handle
      # the case that command name words could be joined by an underscore :/
      command_name_words = command_name_words.join('_')
      @name_args.reject! { |name_arg| command_name_words == name_arg }

      if config[:help]
        msg opt_parser
        exit 1
      end

      # copy Mixlib::CLI over so that it cab be configured in knife.rb
      # config file
      Chef::Config[:verbosity] = config[:verbosity]
    end

    def parse_options(args)
      super
    rescue OptionParser::InvalidOption => e
      puts "Error: " + e.to_s
      show_usage
      exit(1)
    end

    # Returns a subset of the Chef::Config[:knife] Hash that is relevant to the
    # currently executing knife command. This is used by #configure_chef to
    # apply settings from knife.rb to the +config+ hash.
    def config_file_settings
      config_file_settings = {}
      self.class.options.keys.each do |key|
        config_file_settings[key] = Chef::Config[:knife][key] if Chef::Config[:knife].has_key?(key)
      end
      config_file_settings
    end

    # Apply Config in this order:
    # defaults from mixlib-cli
    # settings from config file, via Chef::Config[:knife]
    # config from command line
    def merge_configs
      # Apply config file settings on top of mixlib-cli defaults
      combined_config = default_config.merge(config_file_settings)
      # Apply user-supplied options on top of the above combination
      combined_config = combined_config.merge(config)
      # replace the config hash from mixlib-cli with our own.
      # Need to use the mutate-in-place #replace method instead of assigning to
      # the instance variable because other code may have a reference to the
      # original config hash object.
      config.replace(combined_config)
    end

    # Catch-all method that does any massaging needed for various config
    # components, such as expanding file paths and converting verbosity level
    # into log level.
    def apply_computed_config
      Chef::Config[:color] = config[:color]

      case Chef::Config[:verbosity]
      when 0, nil
        Chef::Config[:log_level] = :error
      when 1
        Chef::Config[:log_level] = :info
      else
        Chef::Config[:log_level] = :debug
      end

      Chef::Config[:log_level] = :debug if ENV['KNIFE_DEBUG']

      Chef::Config[:node_name]         = config[:node_name]       if config[:node_name]
      Chef::Config[:client_key]        = config[:client_key]      if config[:client_key]
      Chef::Config[:chef_server_url]   = config[:chef_server_url] if config[:chef_server_url]
      Chef::Config[:environment]       = config[:environment]     if config[:environment]

      Chef::Config.local_mode = config[:local_mode] if config.has_key?(:local_mode)
      if Chef::Config.local_mode && !Chef::Config.has_key?(:cookbook_path) && !Chef::Config.has_key?(:chef_repo_path)
        Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Dir.pwd)
      end
      Chef::Config.chef_zero.host = config[:chef_zero_host] if config[:chef_zero_host]
      Chef::Config.chef_zero.port = config[:chef_zero_port] if config[:chef_zero_port]

      # Expand a relative path from the config directory. Config from command
      # line should already be expanded, and absolute paths will be unchanged.
      if Chef::Config[:client_key] && config[:config_file]
        Chef::Config[:client_key] = File.expand_path(Chef::Config[:client_key], File.dirname(config[:config_file]))
      end

      Mixlib::Log::Formatter.show_time = false
      Chef::Log.init(Chef::Config[:log_location])
      Chef::Log.level(Chef::Config[:log_level] || :error)

      if Chef::Config[:node_name] && Chef::Config[:node_name].bytesize > 90
        # node names > 90 bytes only work with authentication protocol >= 1.1
        # see discussion in config.rb.
        Chef::Config[:authentication_protocol_version] = "1.1"
      end
    end

    def configure_chef
      config_loader = self.class.load_config(config[:config_file])
      config[:config_file] = config_loader.config_location

      merge_configs
      apply_computed_config
    end

    def show_usage
      stdout.puts("USAGE: " + self.opt_parser.to_s)
    end

    def run_with_pretty_exceptions(raise_exception = false)
      unless self.respond_to?(:run)
        ui.error "You need to add a #run method to your knife command before you can use it"
      end
      enforce_path_sanity
      Chef::LocalMode.with_server_connectivity do
        run
      end
    rescue Exception => e
      raise if raise_exception || Chef::Config[:verbosity] == 2
      humanize_exception(e)
      exit 100
    end

    def humanize_exception(e)
      case e
      when SystemExit
        raise # make sure exit passes through.
      when Net::HTTPServerException, Net::HTTPFatalError
        humanize_http_exception(e)
      when Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError
        ui.error "Network Error: #{e.message}"
        ui.info "Check your knife configuration and network settings"
      when NameError, NoMethodError
        ui.error "knife encountered an unexpected error"
        ui.info  "This may be a bug in the '#{self.class.common_name}' knife command or plugin"
        ui.info  "Please collect the output of this command with the `-VV` option before filing a bug report."
        ui.info  "Exception: #{e.class.name}: #{e.message}"
      when Chef::Exceptions::PrivateKeyMissing
        ui.error "Your private key could not be loaded from #{api_key}"
        ui.info  "Check your configuration file and ensure that your private key is readable"
      when Chef::Exceptions::InvalidRedirect
        ui.error "Invalid Redirect: #{e.message}"
        ui.info  "Change your server location in knife.rb to the server's FQDN to avoid unwanted redirections."
      else
        ui.error "#{e.class.name}: #{e.message}"
      end
    end

    def humanize_http_exception(e)
      response = e.response
      case response
      when Net::HTTPUnauthorized
        ui.error "Failed to authenticate to #{server_url} as #{username} with key #{api_key}"
        ui.info "Response:  #{format_rest_error(response)}"
      when Net::HTTPForbidden
        ui.error "You authenticated successfully to #{server_url} as #{username} but you are not authorized for this action"
        ui.info "Response:  #{format_rest_error(response)}"
      when Net::HTTPBadRequest
        ui.error "The data in your request was invalid"
        ui.info "Response: #{format_rest_error(response)}"
      when Net::HTTPNotFound
        ui.error "The object you are looking for could not be found"
        ui.info "Response: #{format_rest_error(response)}"
      when Net::HTTPInternalServerError
        ui.error "internal server error"
        ui.info "Response: #{format_rest_error(response)}"
      when Net::HTTPBadGateway
        ui.error "bad gateway"
        ui.info "Response: #{format_rest_error(response)}"
      when Net::HTTPServiceUnavailable
        ui.error "Service temporarily unavailable"
        ui.info "Response: #{format_rest_error(response)}"
      else
        ui.error response.message
        ui.info "Response: #{format_rest_error(response)}"
      end
    end

    def username
      Chef::Config[:node_name]
    end

    def api_key
      Chef::Config[:client_key]
    end

    # Parses JSON from the error response sent by Chef Server and returns the
    # error message
    #--
    # TODO: this code belongs in Chef::REST
    def format_rest_error(response)
      Array(Chef::JSONCompat.from_json(response.body)["error"]).join('; ')
    rescue Exception
      response.body
    end

    def create_object(object, pretty_name=nil, &block)
      output = edit_data(object)

      if Kernel.block_given?
        output = block.call(output)
      else
        output.save
      end

      pretty_name ||= output

      self.msg("Created #{pretty_name}")

      output(output) if config[:print_after]
    end

    def delete_object(klass, name, delete_name=nil, &block)
      confirm("Do you really want to delete #{name}")

      if Kernel.block_given?
        object = block.call
      else
        object = klass.load(name)
        object.destroy
      end

      output(format_for_display(object)) if config[:print_after]

      obj_name = delete_name ? "#{delete_name}[#{name}]" : object
      self.msg("Deleted #{obj_name}")
    end

    def rest
      @rest ||= begin
        require 'chef/rest'
        Chef::REST.new(Chef::Config[:chef_server_url])
      end
    end

    def noauth_rest
      @rest ||= begin
        require 'chef/rest'
        Chef::REST.new(Chef::Config[:chef_server_url], false, false)
      end
    end

    def server_url
      Chef::Config[:chef_server_url]
    end

  end
end
