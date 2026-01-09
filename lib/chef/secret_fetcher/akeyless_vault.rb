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

require_relative "base"
require_relative "hashi_vault"

class Chef
  class SecretFetcher
    # == Chef::SecretFetcher::AKeylessVault
    # A fetcher that fetches a secret from AKeyless Vault.  Initial implementation is
    # based on HashiVault , because AKeyless provides a compatibility layer that makes this possible.
    # Future revisions will use native akeyless authentication.
    #
    # Required config:
    # :access_id - the access id of the API key
    # :access_key - the access key of the API key
    #
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:akeyless_vault, { access_id: "my-access-id", access_key: "my-access-key"  }, run_context )
    # fetcher.fetch("/secret/data/secretkey1")
    #
    AKEYLESS_VAULT_PROXY_ADDR = "https://hvp.akeyless.io".freeze
    class AKeylessVault < HashiVault
      def validate!
        if config[:access_key].nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the secret access key in the configuration as :secret_access_key")
        end
        if config[:access_id].nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide the access key id in the configuration as :access_key_id")
        end

        config[:vault_addr] ||= AKEYLESS_VAULT_PROXY_ADDR
        config[:auth_method] = :token
        config[:token] = "#{config[:access_id]}..#{config[:access_key]}"
        super
      end
    end
  end
end
