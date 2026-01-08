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

class Chef
  class DataCollector

    # This is for shared code between the run_start_message and run_end_message modules.
    #
    # No external code should call this module directly
    #
    # @api private
    #
    module MessageHelpers
      private

      # The organization name the node is associated with. For Chef Solo runs the default
      # is "chef_solo" which can be overridden by the user.
      #
      # @return [String] Chef organization associated with the node
      #
      def organization
        if solo_run?
          # configurable fake organization name for chef-solo users
          Chef::Config[:data_collector][:organization]
        else
          Chef::Config[:chef_server_url].match(%r{/+organizations/+([^\s/]+)}).nil? ? "unknown_organization" : $1
        end
      end

      # @return [Boolean] True if we're in a chef-solo/chef-zero or legacy chef-solo run
      def solo_run?
        Chef::Config[:solo_legacy_mode] || Chef::Config[:local_mode]
      end
    end
  end
end
