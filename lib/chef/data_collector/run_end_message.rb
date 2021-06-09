#
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
#

require_relative "message_helpers"

class Chef
  class DataCollector
    module RunEndMessage
      extend Chef::DataCollector::MessageHelpers

      # This module encapsulates rendering the run_end_message given the state gathered in the data_collector
      # and the action_collection.  It is deliberately a stateless module and is deliberately not mixed into
      # the data_collector and only uses the public api methods of the data_collector and action_collection.
      #
      # No external code should call this module directly.
      #
      # @api private
      class << self

        # Construct the message payload that is sent to the DataCollector server at the
        # end of a Chef run.
        #
        # @param data_collector [Chef::DataCollector::Reporter] the calling data_collector instance
        # @param status [String] the overall status of the run, either "success" or "failure"
        #
        # @return [Hash] A hash containing the run end message data.
        #
        def construct_message(data_collector, status)
          action_collection = data_collector.action_collection
          run_status = data_collector.run_status
          node = data_collector.node

          message = {
            "chef_server_fqdn" => URI(Chef::Config[:chef_server_url]).host,
            "entity_uuid" => Chef::Config[:chef_guid],
            "expanded_run_list" => data_collector.expanded_run_list,
            "id" => run_status&.run_id,
            "message_version" => "1.1.0",
            "message_type" => "run_converge",
            "node" => node&.data_for_save || {},
            "node_name" => node&.name || data_collector.node_name,
            "organization_name" => organization,
            "resources" => all_action_records(action_collection),
            "run_id" => run_status&.run_id,
            "run_list" => node&.run_list&.for_json || [],
            "cookbooks" => ( node && node["cookbooks"] ) || {},
            "policy_name" => node&.policy_name,
            "policy_group" => node&.policy_group,
            "start_time" => run_status&.start_time&.utc&.iso8601,
            "end_time" => run_status&.end_time&.utc&.iso8601,
            "source" => solo_run? ? "chef_solo" : "chef_client",
            "status" => status,
            "total_resource_count" => all_action_records(action_collection).count,
            "updated_resource_count" => updated_resource_count(action_collection),
            "deprecations" => data_collector.deprecations.to_a,
          }

          if run_status&.exception
            message["error"] = {
              "class" => run_status.exception.class,
              "message" => run_status.exception.message,
              "backtrace" => run_status.exception.backtrace,
              "description" => data_collector.error_description,
            }
          end

          message
        end

        private

        # @return [Integer] the number of resources successfully updated in the chef-client run
        def updated_resource_count(action_collection)
          return 0 if action_collection.nil?

          action_collection.filtered_collection(up_to_date: false, skipped: false, unprocessed: false, failed: false).count
        end

        # @return [Array<Chef::ActionCollection::ActionRecord>] list of all action_records for all resources
        def action_records(action_collection)
          return [] if action_collection.nil?

          action_collection.action_records
        end

        # @return [Array<Hash>] list of all action_records rendered as a Hash for sending to JSON
        def all_action_records(action_collection)
          action_records(action_collection).map { |rec| action_record_for_json(rec) }
        end

        # @return [Hash] the Hash representation of the action_record for sending as JSON
        def action_record_for_json(action_record)
          new_resource = action_record.new_resource
          current_resource = action_record.current_resource
          after_resource = action_record.after_resource

          hash = {
            "type" => new_resource.resource_name.to_sym,
            "name" => new_resource.name.to_s,
            "id" => safe_resource_identity(new_resource),
            "after" => safe_state_for_resource_reporter(after_resource || new_resource),
            "before" => safe_state_for_resource_reporter(current_resource),
            "duration" => action_record.elapsed_time.nil? ? "" : (action_record.elapsed_time * 1000).to_i.to_s,
            "delta" => new_resource.respond_to?(:diff) && updated_or_failed?(action_record) ? new_resource.diff : "",
            "ignore_failure" => new_resource.ignore_failure,
            "result" => action_record.action.to_s,
            "status" => action_record_status_for_json(action_record),
          }

          # don't use the new_resource for the after_resource if it is skipped or failed
          if action_record.status == :skipped || action_record.status == :failed || action_record.status == :unprocessed
            hash["after"] = {}
          end

          if new_resource.cookbook_name
            hash["cookbook_name"]    = new_resource.cookbook_name
            hash["cookbook_version"] = new_resource.cookbook_version.version
            hash["recipe_name"]      = new_resource.recipe_name
          end

          hash["conditional"] = action_record.conditional.to_text if action_record.status == :skipped

          unless action_record.exception.nil?
            hash["error_message"] = action_record.exception.message

            hash["error"] = {
              "class" => action_record.exception.class,
              "message" => action_record.exception.message,
              "backtrace" => action_record.exception.backtrace,
              "description" => action_record.error_description,
            }
          end

          hash
        end

        # If the identity property of a resource has been lazied (via a lazy name resource) evaluating it
        # for an unprocessed resource (where the preconditions have not been met) may cause the lazy
        # evaluator to throw -- and would otherwise crash the data collector.
        #
        # @return [String] the resource's identity property
        #
        def safe_resource_identity(new_resource)
          new_resource.identity.to_s
        rescue => e
          "unknown identity (due to #{e.class})"
        end

        # FIXME: This is likely necessary due to the same lazy issue with properties and failing resources?
        #
        # @return [Hash] the resource's reported state properties
        #
        def safe_state_for_resource_reporter(resource)
          resource ? resource.state_for_resource_reporter : {}
        rescue
          {}
        end

        # Helper to convert action record status (symbols) to strings for the Data Collector server.
        # Does a bit of necessary underscores-to-dashes conversion to comply with the Data Collector API.
        #
        # @return [String] resource status (
        #
        def action_record_status_for_json(action_record)
          action = action_record.status.to_s
          action = "up-to-date" if action == "up_to_date"
          action
        end

        # @return [Boolean] True if the resource was updated or failed
        def updated_or_failed?(action_record)
          action_record.status == :updated || action_record.status == :failed
        end
      end
    end
  end
end
