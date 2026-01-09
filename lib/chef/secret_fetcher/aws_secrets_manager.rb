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
require "aws-sdk-core"
require "aws-sdk-secretsmanager"

class Chef
  # == Chef::SecretFetcher::AWSSecretsManager
  # A fetcher that fetches a secret from AWS Secrets Manager
  # In this initial iteration it defaults to authentication via instance profile.
  # It is possible to pass options that configure it to use alternative credentials.
  # This implementation supports fetching with version.
  #
  # @note ':region' is required configuration.  If it is not explicitly provided,
  # and it is not available via global AWS config, we will pull it from node ohai data by default.
  # If this isn't correct, you will need to explicitly override it.
  # If it is not available via ohai data either (such as if you have the AWS plugin disabled)
  # then the converge will fail with an error.
  #
  # @note: This does not yet support automatic retries, which the AWS client does by default.
  #
  # For configuration options see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SecretsManager/Client.html#initialize-instance_method
  #
  #
  # Usage Example:
  #
  # fetcher = SecretFetcher.for_service(:aws_secrets_manager)
  # fetcher.fetch("secretkey1", "v1")
  class SecretFetcher
    class AWSSecretsManager < Base
      def validate!
        config[:region] = config[:region] || Aws.config[:region] || run_context.node.dig("ec2", "region")
        if config[:region].nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("Missing required config for AWS secret fetcher: :region")
        end
      end

      # @param identifier [String] the secret_id
      # @param version [String] the secret version.
      # @return Aws::SecretsManager::Types::GetSecretValueResponse
      def do_fetch(identifier, version)
        client = Aws::SecretsManager::Client.new(config)
        result = client.get_secret_value(secret_id: identifier, version_stage: version)
        # These fields are mutually exclusive
        result.secret_string || result.secret_binary
      end
    end
  end
end
