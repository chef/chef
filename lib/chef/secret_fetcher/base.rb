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

require_relative "../exceptions"

class Chef
  # == Chef::SecretFetcher
  # An abstract base class that defines the methods required to implement
  # a Secret Fetcher.
  class SecretFetcher
    class Base
      attr_reader :config
      # Note that this is only available in the context of a recipe.
      # Since that's the only place it's intended to be used, that's probably OK.
      attr_reader :run_context

      # Initialize a new SecretFetcher::Base
      #
      # @param config [Hash] Configuration hash.  Expected configuration keys and values
      # will vary based on implementation, and are validated in `validate!`.
      def initialize(config, run_context)
        @config = config
        @run_context = run_context
      end

      # Fetch the named secret by invoking implementation-specific [Chef::SecretFetcher::Base#do_fetch]
      #
      # @param name [Object] the name or identifier of the secret.
      # @param version [Object] Optional version of the secret to fetch.
      # @note - the name parameter will probably see a narrowing of type as we learn more about different integrations.
      # @return [Object] the fetched secret
      # @raise [Chef::Exceptions::Secret::MissingSecretName] when secret name is not provided
      # @raise [Chef::Exceptions::Secret::FetchFailed] when the underlying attempt to fetch the secret fails.
      def fetch(name, version = nil)
        raise Chef::Exceptions::Secret::MissingSecretName.new if name.to_s == ""

        do_fetch(name, version)
      end

      # Validate that the instance is correctly configured.
      # @raise [Chef::Exceptions::Secret::ConfigurationInvalid] if it is not.
      def validate!; end

      # Called to fetch the secret identified by 'identifier'.  Implementations
      # should expect that `validate!` has been invoked before `do_fetch`.
      #
      # @param identifier [Object] Unique identifier of the secret to be retrieved.
      # When invoked via DSL, this is pre-verified to be not nil/not empty string.
      # The expected data type and form can vary by implementation.
      # @param version [Object] Optional version of the secret to be retrieved.  If not
      # provided, implementations are expected to fetch the most recent version of the
      # secret by default.
      #
      # @return [Object] The secret as returned from the implementation.  The data type
      # will vary implementation.
      #
      # @raise [Chef::Exceptions::Secret::FetchFailed] if the secret could not be fetched
      def do_fetch(identifier, version); raise NotImplementedError.new; end
    end
  end
end
