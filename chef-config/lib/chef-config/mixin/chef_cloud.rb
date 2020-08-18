#
# Author:: Jon Morrow (jmorrow@chef.io)
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

require_relative "../path_helper"

module ChefConfig
  module Mixin
    module ChefCloud
      CHEF_CLOUD_CLIENT_CONFIG = "/Library/Managed Preferences/io.chef.chef_client.plist"

      def cloud_config?
        File.file?(CHEF_CLOUD_CLIENT_CONFIG)
      end
      module_function :cloud_config?

      def parse_cloud_config
        return nil unless cloud_config?

        begin
          plist_cmd = Mixlib::ShellOut.new("plutil -convert json '" + CHEF_CLOUD_CLIENT_CONFIG + "' -o -")
          plist_cmd.run_command
          plist_cmd.error!
          JSON.parse(plist_cmd.stdout)
        rescue => e
          # TOML's error messages are mostly rubbish, so we'll just give a generic one
          message = "Unable to parse chef client cloud config.\n"
          message << e.message
          raise ChefConfig::ConfigurationError, message
        end
      end

      # Load chef client cloud config configuration.
      #
      # @api internal
      # @return [void]
      def load_cloud_config
        Config.merge!(Hash[parse_cloud_config.map { |k, v| [k.to_sym, v] }])
      end
    end
  end
end
