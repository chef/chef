# freeze_string_literal: true
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

require_relative "licensing_config"

class Chef
  class Context
    KITCHEN_CONTEXT_ENV_NAME = "IS_KITCHEN".freeze

    class << self
      # When chef-test-kitchen-enterprise invokes the chef-client during the converge phase,
      # it sets the env variable IS_KITCHEN to true. This method checks the existence of the ENV variable
      # and returns if the chef-client is running in the test-kitchen context.
      def test_kitchen_context?
        @context ||= (fetch_env_value == "true")
      end

      # This method will switch the license entitlement to Chef Workstation entitlement.
      def switch_to_workstation_entitlement
        puts "Running under Test-Kitchen: Switching License to Chef Workstation entitlement!"
        ChefLicensing.configure do |config|
          # Reset entitlement ID to the ID of Chef Workstation
          config.chef_entitlement_id = Chef::LicensingConfig::WORKSTATION_ENTITLEMENT_ID
        end
      end

      private

      # Get the value of the ENV variable
      def fetch_env_value
        ENV.fetch(KITCHEN_CONTEXT_ENV_NAME, "")
      end

      def reset_context
        @context = nil
      end
    end
  end
end
