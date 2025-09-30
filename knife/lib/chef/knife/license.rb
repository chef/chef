#
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../knife"

class Chef
  class Knife
    class License < Chef::Knife
      category "license"
      banner <<~BANNER
        knife license [--chef-license-key <LICENSE_KEY>]
        knife license list
        knife license add [--chef-license-key <LICENSE_KEY>]
      BANNER

      deps do
        require "chef/utils/licensing_handler" unless defined?(ChefLicensing)
      end

      option :chef_license_key,
        long: "--chef-license-key <KEY>",
        description: "Free/Trial/Commercial License key to activate the Chef product"

      def run
        case ARGV[1]
        when "list"
          ChefLicensing.list_license_keys_info
        when "add"
          ChefLicensing.add_license
        else
          ChefLicensing.fetch_and_persist.each do |key|
            ui.msg("License_key: #{key}")
          end
        end
      end
    end
  end
end
