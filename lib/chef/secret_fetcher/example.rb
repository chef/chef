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

class Chef
  # == Chef::SecretFetcher::Example
  # A simple implementation of a secrets fetcher.
  # It expects to be initialized with a hash of
  # keys and secret values.
  #
  # Usage Example:
  #
  # fetcher = SecretFetcher.for_service(:example, "secretkey1" => { "secret" => "lives here" })
  # fetcher.fetch("secretkey1")
  class SecretFetcher
    class Example < Base
      def validate!
        if config.class != Hash
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("The Example fetcher requires a hash of secrets")
        end
      end

      def do_fetch(identifier)
        raise Chef::Exceptions::Secret::FetchFailed.new("Secret #{identifier}) not found.") unless config.key?(identifier)

        config[identifier]
      end
    end
  end
end
