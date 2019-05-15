#
# Copyright:: Copyright 2017, Chef Software, Inc.
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

require "tomlrb"
require_relative "../path_helper"

module ChefConfig
  module Mixin
    # Helper methods for working with credentials files.
    #
    # @since 13.7
    # @api internal
    module Credentials
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
        context_file = PathHelper.home(".chef", "context").freeze
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
        PathHelper.home(".chef", "credentials").freeze
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
          Tomlrb.load_file(credentials_file)
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
        config = parse_credentials_file
        return if config.nil? # No credentials, nothing to do here.
        if config[profile].nil?
          # Unknown profile name. For "default" just silently ignore, otherwise
          # raise an error.
          return if profile == "default"
          raise ChefConfig::ConfigurationError, "Profile #{profile} doesn't exist. Please add it to #{credentials_file}."
        end
        apply_credentials(config[profile], profile)
      end
    end
  end
end
