#
# Author:: Marc Paradise (<marc@chef.io>)
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
#

require_relative "base"
require "aws-sdk-core" # Support for aws instance profile auth
require "vault"

class Chef
  class SecretFetcher
    # == Chef::SecretFetcher::HashiVault
    # A fetcher that fetches a secret from Hashi Vault.
    #
    # Does not yet support fetching with version when a versioned key store is in use.
    # In this initial iteration the only supported authentication is IAM role-based
    #
    # Required config:
    # :vault_addr - the address of a running Vault instance, eg https://vault.example.com:8200
    # If not explicitly provided, the environment variable VAULT_ADDR will be used.
    # :role_name - the name of the role in Vault that was created to support authentication
    # via IAM.  See the Vault documentation for details[1]. A Terraform example is also available[2]
    #
    # [1] https://www.vaultproject.io/docs/auth/aws#recommended-vault-iam-policy
    # [2] https://registry.terraform.io/modules/hashicorp/vault/aws/latest/examples/vault-iam-auth
    #             an IAM principal ARN bound to it.
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:hashi_vault, { role_name: "testing-role", vault_addr: https://localhost:8200}, run_context )
    # fetcher.fetch("secretkey1")
    class HashiVault < Base
      def validate!
        if config[:role_name].nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the authenticating Vault role name in the configuration as :role_name ")
        end
        if config[:vault_addr].nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the Vault address in the configuration as :vault_addr")
        end

        # Note that the token here is cached internal to the Vault implementation.
        Vault.auth.aws_iam(config[:role_name],
                           Aws::InstanceProfileCredentials.new,
                           config[:vault_addr] || ENV["VAULT_ADDR"])
      end

      # @param identifier [String] Identifier of the secret to be fetched, which should
      # be the full path of that secret, eg 'secret/example'
      # @param _version [String] not used in this implementation
      # @return [Hash] containing key/value pairs stored at the location given in 'identifier'
      def do_fetch(identifier, _version)
        Vault.logical.read(identifier).data
      end
    end
  end
end

