# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2018, Chef Software, Inc.
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

require "chef-config/mixin/credentials"
require "train"
require_relative "dist"

class Chef
  class TrainTransport
    extend ChefConfig::Mixin::Credentials

    #
    # Returns a RFC099 credentials profile as a hash
    #
    def self.load_credentials(profile)
      # Tomlrb.load_file returns a hash with keys as strings
      credentials = parse_credentials_file
      if contains_split_fqdn?(credentials, profile)
        Chef::Log.warn("Credentials file #{credentials_file_path} contains target '#{profile}' as a Hash, expected a string.")
        Chef::Log.warn("Hostnames must be surrounded by single quotes, e.g. ['host.example.org']")
      end

      # host names must be specified in credentials file as ['foo.example.org'] with quotes
      if !credentials.nil? && !credentials[profile].nil?
        credentials[profile].map { |k, v| [k.to_sym, v] }.to_h # return symbolized keys to match Train.options()
      else
        nil
      end
    end

    # Toml creates hashes when a key is separated by periods, e.g.
    # [host.example.org] => { host: { example: { org: {} } } }
    #
    # Returns true if the above example is true
    #
    # A hostname has to be specified as ['host.example.org']
    # This will be a common mistake so we should catch it
    #
    def self.contains_split_fqdn?(hash, fqdn)
      fqdn.split(".").reduce(hash) do |h, k|
        v = h[k]
        if Hash === v
          v
        else
          break false
        end
      end
    end

    # ChefConfig::Mixin::Credentials.credentials_file_path is designed around knife,
    # overriding it here.
    #
    # Credentials file preference:
    #
    # 1) target_mode.credentials_file
    # 2) /etc/chef/TARGET_MODE_HOST/credentials
    # 3) #credentials_file_path from parent ($HOME/.chef/credentials)
    #
    def self.credentials_file_path
      tm_config = Chef::Config.target_mode
      profile = tm_config.host

      credentials_file =
        if tm_config.credentials_file && File.exist?(tm_config.credentials_file)
          tm_config.credentials_file
        elsif File.exist?(Chef::Config.platform_specific_path("#{Chef::Dist::CONF_DIR}/#{profile}/credentials"))
          Chef::Config.platform_specific_path("#{Chef::Dist::CONF_DIR}/#{profile}/credentials")
        else
          super
        end

      raise ArgumentError, "No credentials file found for target '#{profile}'" unless credentials_file
      raise ArgumentError, "Credentials file specified for target mode does not exist: '#{credentials_file}'" unless File.exist?(credentials_file)

      Chef::Log.debug("Loading credentials file '#{credentials_file}' for target '#{profile}'")

      credentials_file
    end

    def self.build_transport(logger = Chef::Log.with_child(subsystem: "transport"))
      # TODO: Consider supporting parsing the protocol from a URI passed to `--target`
      #
      train_config = Hash.new

      # Load the target_mode config context from Chef::Config, and place any valid settings into the train configuration
      tm_config = Chef::Config.target_mode
      protocol = tm_config.protocol
      train_config = tm_config.to_hash.select { |k| Train.options(protocol).key?(k) }
      Chef::Log.trace("Using target mode options from Chef config file: #{train_config.keys.join(', ')}") if train_config

      # Load the credentials file, and place any valid settings into the train configuration
      credentials = load_credentials(tm_config.host)
      if credentials
        valid_settings = credentials.select { |k| Train.options(protocol).key?(k) }
        valid_settings[:enable_password] = credentials[:enable_password] if credentials.key?(:enable_password)
        train_config.merge!(valid_settings)
        Chef::Log.trace("Using target mode options from credentials file: #{valid_settings.keys.join(', ')}") if valid_settings
      end

      train_config[:logger] = logger

      # Train handles connection retries for us
      Train.create(protocol, train_config)
    rescue SocketError => e # likely a dns failure, not caught by train
      e.message.replace "Error connecting to #{train_config[:target]} - #{e.message}"
      raise e
    rescue Train::PluginLoadError
      logger.error("Invalid target mode protocol: #{protocol}")
      exit(false)
    end
  end
end
