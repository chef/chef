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

require "json"
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
          "message_version"        => "1.0.0",
          "message_type"           => "run_converge",
          "node_name"              => run_status.node.name,
          "organization_name"      => organization,
          "resources"              => reporter_data[:updated_resources].map(&:for_json),
          "run_id"                 => run_status.run_id,
          "run_list"               => run_status.node.run_list.for_json,
          "start_time"             => run_status.start_time.utc.iso8601,
          "end_time"               => run_status.end_time.utc.iso8601,
          "source"                 => collector_source,
          "status"                 => reporter_data[:status],
          "total_resource_count"   => reporter_data[:total_resource_count],
          "updated_resource_count" => reporter_data[:updated_resources].count,
        }

        message["error"] = {
          "class"       => run_status.exception.class,
          "message"     => run_status.exception.message,
          "backtrace"   => run_status.exception.backtrace,
          "description" => reporter_data[:error_descriptions],
        } if run_status.exception

        message
      end

      #
      # Message payload that is sent to the DataCollector server at the
      # end of a Chef run.
      #
      # @param run_status [Chef::RunStatus] The RunStatus instance for this node/run.
      #
      # @return [Hash] A hash containing the node object and related metadata.
      #
      def self.node_update_message(run_status)
        {
          "entity_name"       => run_status.node.name,
          "entity_type"       => "node",
          "entity_uuid"       => node_uuid,
          "id"                => SecureRandom.uuid,
          "message_version"   => "1.1.0",
          "message_type"      => "action",
          "organization_name" => organization,
          "recorded_at"       => Time.now.utc.iso8601,
          "remote_hostname"   => run_status.node["fqdn"],
          "requestor_name"    => run_status.node.name,
          "requestor_type"    => "client",
          "run_id"            => run_status.run_id,
          "service_hostname"  => chef_server_fqdn(run_status),
          "source"            => collector_source,
          "task"              => "update",
          "user_agent"        => Chef::HTTP::HTTPRequest::DEFAULT_UA,
          "data"              => run_status.node,
        }
      end
    end
  end
end
