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

require_relative "message_helpers"

class Chef
  class DataCollector
    module RunStartMessage
      extend Chef::DataCollector::MessageHelpers

      # This module encapsulates rendering the run_start_message given the state gathered in the data_collector.
      # It is deliberately a stateless module and is deliberately not mixed into the data_collector and only
      # uses the public api methods of the data_collector.
      #
      # No external code should call this module directly.
      #
      # @api private
      class << self

        # Construct the message payload that is sent to the DataCollector server at the
        # start of a Chef run.
        #
        # @param data_collector [Chef::DataCollector::Reporter] the calling data_collector instance
        #
        # @return [Hash] A hash containing the run start message data.
        #
        def construct_message(data_collector)
          run_status = data_collector.run_status
          node = data_collector.node
          {
            "chef_server_fqdn" => URI(Chef::Config[:chef_server_url]).host,
            "entity_uuid" => (node && node["uuid"]) || Chef::Config[:chef_guid],
            "id" => run_status&.run_id,
            "message_version" => "1.0.0",
            "message_type" => "run_start",
            "node_name" => node&.name || data_collector.node_name,
            "organization_name" => organization,
            "run_id" => run_status&.run_id,
            "source" => solo_run? ? "chef_solo" : "chef_client",
            "start_time" => run_status&.start_time&.utc&.iso8601,
          }
        end
      end
    end
  end
end
