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

require "uri" unless defined?(URI)
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class DataCollector

    # @api private
    module ConfigValidation
      class << self
        def validate_server_url!
          # if we have a server_url set we ALWAYS validate it, and we MUST have an output_location set to skip server_url validation
          # (having output_locations set and no server_url is valid, but both of them unset blows up in here)
          return if !Chef::Config[:data_collector][:server_url] && Chef::Config[:data_collector][:output_locations]

          begin
            uri = URI(Chef::Config[:data_collector][:server_url])
          rescue
            raise Chef::Exceptions::ConfigurationError, "Chef::Config[:data_collector][:server_url] (#{Chef::Config[:data_collector][:server_url]}) is not a valid URI."
          end

          if uri.host.nil?
            raise Chef::Exceptions::ConfigurationError,
              "Chef::Config[:data_collector][:server_url] (#{Chef::Config[:data_collector][:server_url]}) is a URI with no host. Please supply a valid URL."
          end
        end

        def validate_output_locations!
          # not having an output_location set at all is fine, we just skip it then
          output_locations = Chef::Config[:data_collector][:output_locations]
          return unless output_locations

          # but deliberately setting an empty output_location we consider to be an error (XXX: but should we?)
          unless valid_hash_with_keys?(output_locations, :urls, :files)
            raise Chef::Exceptions::ConfigurationError,
              "Chef::Config[:data_collector][:output_locations] is empty. Please supply an hash of valid URLs and / or local file paths."
          end

          # loop through all the types and locations and validate each one-by-one
          output_locations.each do |type, locations|
            Array(locations).each do |location|
              validate_url!(location) if type == :urls
              validate_file!(location) if type == :files
            end
          end
        end

        # Main logic controlling the data collector being enabled or disabled:
        #
        # * disabled in why-run mode
        # * disabled when `Chef::Config[:data_collector][:mode]` excludes the solo-vs-client mode
        # * disabled if there is no server_url or no output_locations to log to
        # * enabled if there is a configured output_location even without a token
        # * disabled in solo mode if the user did not configure the auth token
        #
        # @return [Boolean] true if the data collector should be enabled
        #
        def should_be_enabled?
          running_mode = ( Chef::Config[:solo_legacy_mode] || Chef::Config[:local_mode] ) ? :solo : :client
          want_mode = Chef::Config[:data_collector][:mode]

          case
          when Chef::Config[:why_run]
            Chef::Log.trace("data collector is disabled for why run mode")
            false
          when (want_mode != :both) && running_mode != want_mode
            Chef::Log.trace("data collector is configured to only run in #{Chef::Config[:data_collector][:mode]} modes, disabling it")
            false
          when !(Chef::Config[:data_collector][:server_url] || Chef::Config[:data_collector][:output_locations])
            Chef::Log.trace("Neither data collector URL or output locations have been configured, disabling data collector")
            false
          when running_mode == :client && Chef::Config[:data_collector][:token]
            Chef::Log.warn("Data collector token authentication is not recommended for client-server mode. " \
                           "Please upgrade #{ChefUtils::Dist::Server::PRODUCT} to 12.11 or later and remove the token from your config file " \
                           "to use key based authentication instead")
            true
          when Chef::Config[:data_collector][:output_locations] && !valid_hash_with_keys?(Chef::Config[:data_collector][:output_locations], :urls)
            # we can run fine to a file without a token, even in solo mode.
            unless valid_hash_with_keys?(Chef::Config[:data_collector][:output_locations], :files)
              raise Chef::Exceptions::ConfigurationError,
                "Chef::Config[:data_collector][:output_locations] is empty. Please supply an hash of valid URLs and / or local file paths."
            end

            true
          when running_mode == :solo && !Chef::Config[:data_collector][:token]
            # we are in solo mode and are not logging to a file, so must have a token
            Chef::Log.trace("Data collector token must be configured to use #{ChefUtils::Dist::Automate::PRODUCT} data collector with #{ChefUtils::Dist::Solo::PRODUCT}")
            false
          else
            true
          end
        end

        private

        # validate an output_location file
        def validate_file!(file)
          return true if Chef::Config.path_accessible?(File.expand_path(file))

          raise Chef::Exceptions::ConfigurationError,
            "Chef::Config[:data_collector][:output_locations][:files] contains the location #{file}, which is a non existent file path."
        end

        # validate an output_location url
        def validate_url!(url)
          URI(url)
        rescue
          raise Chef::Exceptions::ConfigurationError,
            "Chef::Config[:data_collector][:output_locations][:urls] contains the url #{url} which is not valid."
        end

        # Validate the hash contains at least one of the given keys.
        #
        # @param hash [Hash] the hash to be validated.
        # @param keys [Array] an array of keys to check existence of in the hash.
        # @return [Boolean] true if the hash contains any of the given keys.
        #
        def valid_hash_with_keys?(hash, *keys)
          hash.is_a?(Hash) && keys.any? { |k| hash.key?(k) }
        end
      end
    end
  end
end
