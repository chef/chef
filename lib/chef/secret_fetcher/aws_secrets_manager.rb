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
require "aws-sdk-secretsmanager"

class Chef
  # == Chef::SecretFetcher::AWSSecretsManager
  # A fetcher that fetches a secret from AWS Secrets Manager
  # In this initial iteration it defaults to authentication via instance profile.
  # It is possible to pass options that configure it to use alternative credentials.
  # This implementation supports fetching with version.
  #
  # NOTE: This does not yet support automatic retries, which the AWS client does by default.
  #
  # For configuration options see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SecretsManager/Client.html#initialize-instance_method
  #
  # Note that ~/.aws default and environment-based configurations are supported by default in the
  # ruby SDK.
  #
  # Usage Example:
  #
  # fetcher = SecretFetcher.for_service(:aws_secrets_manager, { region: "us-east-1" })
  # fetcher.fetch("secretkey1", "v1")
  class SecretFetcher
    class AWSSecretsManager < Base
      # @param identifier [String] the secret_id
      # @param version [String] the secret version. Not usd at this time
      # @return Aws::SecretsManager::Types::GetSecretValueResponse
      def do_fetch(identifier, version)
        client = Aws::SecretsManager::Client.new
        result = client.get_secret_value(secret_id: identifier, version_stage: version)
        # These fields are mutually exclusive
        result.secret_string || result.secret_binary
      end
    end
  end
end
