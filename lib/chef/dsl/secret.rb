#
# Author:: Marc Paradise (<marc@chef.io>)
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
require_relative "../secret_fetcher"

class Chef
  module DSL
    module Secret

      #
      # This allows you to set the default secret service that is used when
      # fetching secrets.
      #
      # @example
      #
      #   default_secret_service :hashi_vault
      #   val1 = secret(name: "test1", config: { region: "us-west-1" })
      #
      # @example
      #
      #   default_secret_service #=> nil
      #   default_secret_service :hashi_vault
      #   default_secret_service #=> :hashi_vault
      #
      # @param [Symbol] service default secret service to use when fetching secrets
      # @return [Symbol, nil] default secret service to use when fetching secrets
      #
      def default_secret_service(service = nil)
        return run_context.default_secret_service if service.nil?
        raise Chef::Exceptions::Secret::InvalidFetcherService.new("Unsupported secret service: #{service.inspect}", Chef::SecretFetcher::SECRET_FETCHERS) unless Chef::SecretFetcher::SECRET_FETCHERS.include?(service)

        run_context.default_secret_service = service
      end

      #
      # This allows you to set the secret service for the scope of the block
      # passed into this method.
      #
      # @example
      #
      #   with_secret_service :hashi_vault do
      #     val1 = secret(name: "test1", config: { region: "us-west-1" })
      #     val2 = secret(name: "test2", config: { region: "us-west-1" })
      #   end
      #
      # @example Combine with #with_secret_config
      #
      #   with_secret_service :hashi_vault do
      #     with_secret_config region: "us-west-1" do
      #       val1 = secret(name: "test1")
      #       val2 = secret(name: "test2")
      #     end
      #   end
      #
      # @param [Symbol] service The default secret service to use when fetching secrets
      #
      def with_secret_service(service)
        raise ArgumentError, "You must pass a block to #with_secret_service" unless block_given?

        begin
          old_service = default_secret_service
          # Use "public" API for input validation
          default_secret_service(service)
          yield
        ensure
          # Use "private" API so we can set back to nil
          run_context.default_secret_service = old_service
        end
      end

      #
      # This allows you to set the default secret config that is used when
      # fetching secrets.
      #
      # @example
      #
      #   default_secret_config region: "us-west-1"
      #   val1 = secret(name: "test1", service: :hashi_vault)
      #
      # @example
      #
      #   default_secret_config #=> {}
      #   default_secret_service region: "us-west-1"
      #   default_secret_service #=> { region: "us-west-1" }
      #
      # @param [Hash<Symbol,Object>] config The default configuration options to apply when fetching secrets
      # @return [Hash<Symbol,Object>]
      #
      def default_secret_config(**config)
        return run_context.default_secret_config if config.empty?

        run_context.default_secret_config = config
      end

      #
      # This allows you to set the secret config for the scope of the block
      # passed into this method.
      #
      # @example
      #
      #   with_secret_config region: "us-west-1" do
      #     val1 = secret(name: "test1", service: :hashi_vault)
      #     val2 = secret(name: "test2", service: :hashi_vault)
      #   end
      #
      # @param [Hash<Symbol,Object>] config The default configuration options to use when fetching secrets
      #
      def with_secret_config(**config)
        raise ArgumentError, "You must pass a block to #with_secret_config" unless block_given?

        begin
          old_config = default_secret_config
          # Use "public" API for input validation
          default_secret_config(**config)
          yield
        ensure
          # Use "private" API so we can set back to nil
          run_context.default_secret_config = old_config
        end
      end

      # Helper method which looks up a secret using the given service and configuration,
      # and returns the retrieved secret value.
      # This DSL providers a wrapper around [Chef::SecretFetcher]
      #
      # Use of the secret helper in the context of a resource block will automatically mark
      # that resource as 'sensitive', preventing resource data from being logged.  See [Chef::Resource#sensitive].
      #
      # @option name [Object] The identifier or name for this secret
      # @option version [Object] The secret version. If a service supports versions
      #                          and no version is provided, the latest version will be fetched.
      # @option service [Symbol] The service identifier for the service that will
      #                         perform the secret lookup. See
      #                         [Chef::SecretFetcher::SECRET_FETCHERS]
      # @option config [Hash] The configuration that the named service expects
      #
      # @return result [Object] The response object type is determined by the fetcher but will usually be a string or a hash.
      # See individual fetcher documentation to know what to expect for a given service.
      #
      # @example
      #
      # This example uses the built-in :example secret manager service, which
      # accepts a hash of secrets.
      #
      #   value = secret(name: "test1", service: :example, config: { "test1" => "value1" })
      #   log "My secret is #{value}"
      #
      #   value = secret(name: "test1", service: :aws_secrets_manager, version: "v1", config: { region: "us-west-1" })
      #   log "My secret is #{value}"
      def secret(name: nil, version: nil, service: default_secret_service, config: default_secret_config)
        sensitive(true) if is_a?(Chef::Resource)
        Chef::SecretFetcher.for_service(service, config, run_context).fetch(name, version)
      end
    end
  end
end
