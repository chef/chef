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
require "chef-config/path_helper"

module ChefConfig
  module Mixin
    module Credentials

      def load_credentials(profile = nil)
        credentials_file = PathHelper.home(".chef", "credentials").freeze
        context_file = PathHelper.home(".chef", "context").freeze

        return unless File.file?(credentials_file)

        context = File.read(context_file) if File.file?(context_file)

        environment = ENV.fetch("CHEF_PROFILE", nil)

        profile = if !profile.nil?
                    profile
                  elsif !environment.nil?
                    environment
                  elsif !context.nil?
                    context
                  else
                    "default"
                  end

        config = Tomlrb.load_file(credentials_file)
        apply_credentials(config[profile], profile)
      rescue ChefConfig::ConfigurationError
        raise
      rescue => e
        # TOML's error messages are mostly rubbish, so we'll just give a generic one
        message = "Unable to parse Credentials file: #{credentials_file}\n"
        message << e.message
        raise ChefConfig::ConfigurationError, message
      end
    end
  end
end
