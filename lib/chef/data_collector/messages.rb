#
# Author:: Adam Leff (<adamleff@chef.io)
# Author:: Ryan Cragun (<ryan@chef.io>)
#
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "securerandom"
require_relative "messages/helpers"

class Chef
  class DataCollector
    module Messages
      extend Helpers

      #
      # Message payload that is sent to the DataCollector server at the
      # start of a Chef run.
      #
      # @param run_status [Chef::RunStatus] The RunStatus instance for this node/run.
      #
      # @return [Hash] A hash containing the run start message data.
      #
      def self.run_start_message(run_status)
        {
          "chef_server_fqdn"  => chef_server_fqdn(run_status),
          "entity_uuid"       => node_uuid,
          "id"                => run_status.run_id,
          "message_version"   => "1.0.0",
          "message_type"      => "run_start",
          "node_name"         => run_status.node.name,
          "organization_name" => organization,
          "run_id"            => run_status.run_id,
          "source"            => collector_source,
          "start_time"        => run_status.start_time.utc.iso8601,
        }
      end

      #
      # Message payload that is sent to the DataCollector server at the
      # end of a Chef run.
      #
      # @param reporter_data [Hash] Data supplied by the Reporter, such as run_status, resource counts, etc.
      #
      # @return [Hash] A hash containing the run end message data.
      #
      def self.run_end_message(reporter_data)
        run_status = reporter_data[:run_status]

        message = {
          "chef_server_fqdn"       => chef_server_fqdn(run_status),
          "entity_uuid"            => node_uuid,
          "expanded_run_list"      => reporter_data[:expanded_run_list],
          "id"                     => run_status.run_id,
          "message_version"        => "1.1.0",
          "message_type"           => "run_converge",
          "node"                   => run_status.node,
          "node_name"              => run_status.node.name,
          "organization_name"      => organization,
          "resources"              => reporter_data[:resources].map(&:report_data),
          "run_id"                 => run_status.run_id,
          "run_list"               => run_status.node.run_list.for_json,
          "policy_name"            => run_status.node.policy_name,
          "policy_group"           => run_status.node.policy_group,
          "start_time"             => run_status.start_time.utc.iso8601,
          "end_time"               => run_status.end_time.utc.iso8601,
          "source"                 => collector_source,
          "status"                 => reporter_data[:status],
          "total_resource_count"   => reporter_data[:resources].count,
          "updated_resource_count" => reporter_data[:resources].select { |r| r.report_data["status"] == "updated" }.count,
          "deprecations"           => reporter_data[:deprecations],
        }

        if run_status.exception
          message["error"] = {
            "class"       => run_status.exception.class,
            "message"     => run_status.exception.message,
            "backtrace"   => run_status.exception.backtrace,
            "description" => reporter_data[:error_descriptions],
          }
        end

        message
      end
    end
  end
end
