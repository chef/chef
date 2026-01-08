#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "chef-utils" unless defined?(ChefUtils::CANARY)
require "etc" unless defined?(Etc)
require_relative "config"
require_relative "exceptions"
require_relative "logger"
require_relative "path_helper"
require_relative "windows"
require_relative "mixin/dot_d"
require_relative "mixin/credentials"

module ChefConfig
  class WorkstationConfigLoader
    include ChefConfig::Mixin::DotD
    include ChefConfig::Mixin::Credentials

    # Path to a config file requested by user, (e.g., via command line option). Can be nil
    attr_accessor :explicit_config_file
    # The name of a credentials profile. Can be nil
    attr_accessor :profile
    attr_reader :credentials_found

    # TODO: initialize this with a logger for Chef and Knife
    def initialize(explicit_config_file, logger = nil, profile: nil)
      @explicit_config_file = explicit_config_file
      @chef_config_dir = nil
      @config_location = nil
      @profile = profile
      @logger = logger || NullLogger.new
      @credentials_found = false
    end

    def no_config_found?
      config_location.nil? && !credentials_found
    end

    def config_location
      @config_location ||= (explicit_config_file || locate_local_config)
    end

    def chef_config_dir
      if @chef_config_dir.nil?
        @chef_config_dir = false
        full_path = working_directory.split(File::SEPARATOR)
        (full_path.length - 1).downto(0) do |i|
          candidate_directory = File.join(full_path[0..i] + [ChefUtils::Dist::Infra::USER_CONF_DIR])
          if File.exist?(candidate_directory) && File.directory?(candidate_directory)
            @chef_config_dir = candidate_directory
            break
          end
        end
      end
      @chef_config_dir
    end

    def load
      load_credentials(profile)
      # Ignore it if there's no explicit_config_file and can't find one at a
      # default path.
      unless config_location.nil?
        if explicit_config_file && !path_exists?(config_location)
          raise ChefConfig::ConfigurationError, "Specified config file #{config_location} does not exist"
        end

        # Have to set Config.config_file b/c other config is derived from it.
        Config.config_file = config_location
        apply_config(IO.read(config_location), config_location)
      end

      load_dot_d(Config[:config_d_dir]) if Config[:config_d_dir]

      apply_defaults
    end

    # (Private API, public for test purposes)
    def env
      ENV
    end

    # (Private API, public for test purposes)
    def path_exists?(path)
      Pathname.new(path).expand_path.exist?
    end

    private

    def have_config?(path)
      if path_exists?(path)
        logger.info("Using config at #{path}")
        true
      else
        logger.debug("Config not found at #{path}, trying next option")
        false
      end
    end

    def locate_local_config
      candidate_configs = []

      # Look for $KNIFE_HOME/knife.rb (allow multiple knives config on same machine)
      if env["KNIFE_HOME"]
        candidate_configs << File.join(env["KNIFE_HOME"], "config.rb")
        candidate_configs << File.join(env["KNIFE_HOME"], "knife.rb")
      end
      # Look for $PWD/knife.rb
      if Dir.pwd
        candidate_configs << File.join(Dir.pwd, "config.rb")
        candidate_configs << File.join(Dir.pwd, "knife.rb")
      end
      # Look for $UPWARD/.chef/knife.rb
      if chef_config_dir
        candidate_configs << File.join(chef_config_dir, "config.rb")
        candidate_configs << File.join(chef_config_dir, "knife.rb")
      end
      # Look for $HOME/.chef/knife.rb
      PathHelper.home(ChefUtils::Dist::Infra::USER_CONF_DIR) do |dot_chef_dir|
        candidate_configs << File.join(dot_chef_dir, "config.rb")
        candidate_configs << File.join(dot_chef_dir, "knife.rb")
      end

      candidate_configs.find do |candidate_config|
        have_config?(candidate_config)
      end
    end

    def working_directory
      if ChefUtils.windows?
        env["CD"]
      else
        env["PWD"]
      end || Dir.pwd
    end

    def apply_credentials(creds, profile)
      # Store the profile used in case other things want it.
      Config.profile ||= profile
      # Validate the credentials data.
      if creds.key?("node_name") && creds.key?("client_name")
        raise ChefConfig::ConfigurationError, "Do not specify both node_name and client_name. You should prefer client_name."
      end

      # Load credentials data into the Chef configuration.
      creds.each do |key, value|
        case key.to_s
        when "client_name"
          # Special case because it's weird to set your username via `node_name`.
          Config.node_name = value
        when "validation_key", "validator_key"
          extract_key(value, :validation_key, :validation_key_contents)
        when "client_key"
          extract_key(value, :client_key, :client_key_contents)
        when "knife"
          Config.knife.merge!(value.transform_keys(&:to_sym))
        else
          Config[key.to_sym] = value
        end
      end
      @credentials_found = true
    end

    def extract_key(key_value, config_path, config_contents)
      if key_value.start_with?("-----BEGIN RSA PRIVATE KEY-----")
        Config.send(config_contents, key_value)
      else
        abs_path = Pathname.new(key_value).expand_path(home_chef_dir)
        Config.send(config_path, abs_path)
      end
    end

    def home_chef_dir
      @home_chef_dir ||= PathHelper.home(ChefUtils::Dist::Infra::USER_CONF_DIR)
    end

    def apply_config(config_content, config_file_path)
      Config.from_string(config_content, config_file_path)
    rescue SignalException
      raise
    rescue SyntaxError => e
      message = ""
      message << "You have invalid ruby syntax in your config file #{config_file_path}\n\n"
      message << "#{e.class.name}: #{e.message}\n"
      if file_line = e.message[/#{Regexp.escape(config_file_path)}:\d+/]
        line = file_line[/:(\d+)$/, 1].to_i
        message << highlight_config_error(config_file_path, line)
      end
      raise ChefConfig::ConfigurationError, message
    rescue Exception => e
      message = "You have an error in your config file #{config_file_path}\n\n"
      message << "#{e.class.name}: #{e.message}\n"
      filtered_trace = e.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
      filtered_trace.each { |bt_line| message << "  " << bt_line << "\n" }
      unless filtered_trace.empty?
        line_nr = filtered_trace.first[/#{Regexp.escape(config_file_path)}:(\d+)/, 1]
        message << highlight_config_error(config_file_path, line_nr.to_i)
      end
      raise ChefConfig::ConfigurationError, message
    end

    # Apply default configuration values for workstation-style tools.
    #
    # Global defaults should go in {ChefConfig::Config} instead, this is only
    # for things like `knife` and `chef`.
    #
    # @api private
    # @since 14.3
    # @return [void]
    def apply_defaults
      # If we don't have a better guess use the username.
      Config[:node_name] ||= Etc.getlogin
      # If we don't have a key (path or inline) check user.pem and $node_name.pem.
      unless Config.key?(:client_key) || Config.key?(:client_key_contents)
        key_path = find_default_key(["#{Config[:node_name]}.pem", "user.pem"])
        Config[:client_key] = key_path if key_path
      end
      # Similarly look for a validation key file, though this should be less
      # common these days.
      unless Config.key?(:validation_key) || Config.key?(:validation_key_contents)
        key_path = find_default_key(["#{Config[:validation_client_name]}.pem", "validator.pem", "validation.pem"])
        Config[:validation_key] = key_path if key_path
      end
    end

    # Look for a default key file.
    #
    # This searches for any of a list of possible default keys, checking both
    # the local `.chef/` folder and the home directory `~/.chef/`. Returns `nil`
    # if no matching file is found.
    #
    # @api private
    # @since 14.3
    # @param key_names [Array<String>] A list of possible filenames to check for.
    #   The first one found will be returned.
    # @return [String, nil]
    def find_default_key(key_names)
      key_names.each do |filename|
        path = Pathname.new(filename)
        # If we have a config location (like ./.chef/), look there first.
        if config_location
          local_path = path.expand_path(File.dirname(config_location))
          return local_path.to_s if local_path.exist?
        end
        # Then check ~/.chef.
        home_path = path.expand_path(home_chef_dir)
        return home_path.to_s if home_path.exist?
      end
      nil
    end

    def highlight_config_error(file, line)
      config_file_lines = []
      IO.readlines(file).each_with_index { |l, i| config_file_lines << "#{(i + 1).to_s.rjust(3)}: #{l.chomp}" }
      if line == 1
        lines = config_file_lines[0..3]
      else
        lines = config_file_lines[Range.new(line - 2, line)]
      end
      "Relevant file content:\n" + lines.join("\n") + "\n"
    end

    def logger
      @logger
    end

  end
end
