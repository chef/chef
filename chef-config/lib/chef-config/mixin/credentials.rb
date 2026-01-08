#
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

autoload :Tomlrb, "tomlrb"
require_relative "../path_helper"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

module ChefConfig
  module Mixin
    # Helper methods for working with credentials files.
    #
    # @since 13.7
    # @api internal
    module Credentials
      attr_reader :credentials_config

      # Compute the active credentials profile name.
      #
      # The lookup order is argument (from --profile), environment variable
      # ($CHEF_PROFILE), context file (~/.chef/context), and then "default" as
      # a fallback.
      #
      # @since 14.4
      # @param profile [String, nil] Optional override for the active profile,
      #   normally set via a command-line option.
      # @return [String]
      def credentials_profile(profile = nil)
        context_file = PathHelper.home(ChefUtils::Dist::Infra::USER_CONF_DIR, "context").freeze
        if !profile.nil?
          profile
        elsif ENV.include?("CHEF_PROFILE")
          ENV["CHEF_PROFILE"]
        elsif File.file?(context_file)
          File.read(context_file).strip
        else
          "default"
        end
      end

      # Compute the path to the credentials file.
      #
      # @since 14.4
      # @return [String]
      def credentials_file_path
        return Chef::Config[:credentials] if defined?(Chef::Config) && Chef::Config.key?(:credentials)

        env_file = ENV["CHEF_CREDENTIALS_FILE"]
        return env_file if env_file && File.file?(env_file)

        PathHelper.home(ChefUtils::Dist::Infra::USER_CONF_DIR, "credentials").freeze
      end

      # Load and parse the credentials file.
      #
      # Returns `nil` if the credentials file is unavailable.
      #
      # @since 14.4
      # @return [String, nil]
      def parse_credentials_file
        credentials_file = credentials_file_path
        return nil unless File.file?(credentials_file)

        begin
          @credentials_config = Tomlrb.load_file(credentials_file)
        rescue => e
          # TOML's error messages are mostly rubbish, so we'll just give a generic one
          message = "Unable to parse Credentials file: #{credentials_file}\n"
          message << e.message
          raise ChefConfig::ConfigurationError, message
        end
      end

      # Load and process the active credentials.
      #
      # @see WorkstationConfigLoader#apply_credentials
      # @param profile [String, nil] Optional override for the active profile,
      #   normally set via a command-line option.
      # @return [void]
      def load_credentials(profile = nil)
        profile = credentials_profile(profile)

        parse_credentials_file
        return if credentials_config.nil? # No credentials, nothing to do here.

        if credentials_config[profile].nil?
          # Unknown profile name. For "default" just silently ignore, otherwise
          # raise an error.
          return if profile == "default"

          raise ChefConfig::ConfigurationError, "Profile #{profile} doesn't exist. Please add it to #{credentials_file_path}."
        end

        resolve_secrets(profile)

        apply_credentials(credentials_config[profile], profile)
      end

      GLOBAL_CONFIG_HASHES = %w{ default_secrets_provider }.freeze

      # Extract global (non-profile) settings from credentials file.
      #
      # @since 19.1
      # @return [Hash]
      def global_options
        globals = credentials_config.filter { |_, v| v.is_a? String }
        globals.merge! credentials_config.filter { |k, _| GLOBAL_CONFIG_HASHES.include? k }
      end

      SUPPORTED_SECRETS_PROVIDERS = %w{ hashicorp-vault }.freeze

      # Resolve all secrets in a credentials file
      #
      # @since 19.1
      # @param profile [String] Profile to resolve secrets in.
      # @return [Hash]
      def resolve_secrets(profile)
        return unless credentials_config
        raise NoCredentialsFound.new("No credentials found for profile '#{profile}'") unless credentials_config[profile]

        secrets = credentials_config[profile].filter { |k, v| v.is_a?(Hash) && v.keys.include?("secret") }
        return if secrets.empty?

        secrets.each do |option, secrets_config|
          unless valid_secrets_provider?(secrets_config)
            raise UnsupportedSecretsProvider.new("Unsupported credentials secrets provider on '#{option}' for profile '#{profile}'")
          end

          secrets_config.merge!(default_secrets_provider)

          logger.debug("Resolving credentials secret '#{option}' for profile '#{profile}'")
          begin
            resolved_value = resolve_secret(secrets_config)
          ensure
            raise UnresolvedSecret.new("Could not resolve secret '#{option}' for profile '#{profile}'") if resolved_value.nil?
          end

          credentials_config[profile][option] = resolved_value
        end
      end

      # Check, if referenced secrets provider is supported.
      #
      # @since 19.1
      # @param secrets_config [Hash] Parsed contents of a secret in a profile.
      # @return [true, false]
      def valid_secrets_provider?(secrets_config)
        provider_config = secrets_config["secrets_provider"] || default_secrets_provider
        provider = provider_config["name"]

        provider && SUPPORTED_SECRETS_PROVIDERS.include?(provider)
      end

      def default_secrets_provider
        global_options["default_secrets_provider"]
      end

      # Resolve a specific secret.
      #
      # To be replaced later by a Train-like framework to support multiple backends.
      #
      # @since 19.1
      # @param secrets_config [Hash] Parsed contents of a secret in a profile.
      # @return [String]
      def resolve_secret(secrets_config)
        resolve_secret_hashicorp(secrets_config)
      end

      # Resolver logic for Hashicorp Vault.
      #
      # Local lazy loading of Gems which are not part of chef-config or chef-utils,
      # but chef itself to be switched by a unified secrets mechanism for credentials
      # and Chef DSL later. Showstopper mitigation for 19 GA.
      #
      # @since 19.1
      # @param secrets_config [Hash] Parsed contents of a secret in a profile.
      # @return [String]
      def resolve_secret_hashicorp(secrets_config)
        vault_config = secrets_config.transform_keys(&:to_sym)
        vault_config[:address] = vault_config[:endpoint]

        # Lazy require due to Gem being part of Chef and rarely used functionality
        require "vault" unless defined? Vault
        @vault ||= Vault::Client.new(vault_config)

        secret = secrets_config["secret"]
        engine = vault_config[:engine] || "secret"
        engine_type = vault_config[:engine_type] || "kv2"
        secret_value = case engine_type
                       when "kv", "kv1"
                         @vault.logical.read("#{engine_type}/#{secret}")
                       when "kv2"
                         @vault.kv(engine).read(secret)&.data
                       else
                         raise UnsupportedSecretsProvider.new("No support for secrets engine #{engine_type}")
                       end

        # Always JSON for Hashicorp Vault, but this is future compatible to other providers
        if secret_value.is_a?(Hash)
          require "jmespath" unless defined? ::JMESPath
          ::JMESPath.search(secrets_config["field"], secret_value)
        else
          secret_value
        end
      end
    end
  end
end
