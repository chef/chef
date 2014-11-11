#
# Auther:: Tyler Ball (<tball@getchef.com>)
#
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'chef/event_dispatch/base'
require 'chef/audit/control_group_data'

class Chef
  class Audit
    class AuditReporter < EventDispatch::Base

      attr_reader :rest_client, :audit_data, :ordered_control_groups
      private :rest_client, :audit_data, :ordered_control_groups

      PROTOCOL_VERSION = '0.1.0'

      def initialize(rest_client)
        if Chef::Config[:audit_mode] == false
          @audit_enabled = false
        else
          @audit_enabled = true
        end
        @rest_client = rest_client
        # Ruby 1.9.3 and above "enumerate their values in the order that the corresponding keys were inserted."
        @ordered_control_groups = Hash.new
      end

      def audit_phase_start(run_status)
        Chef::Log.debug("Audit Reporter starting")
        @audit_data = AuditData.new(run_status.node.name, run_status.run_id)
      end

      def audit_phase_complete
        Chef::Log.debug("Audit Reporter completed successfully without errors")
        ordered_control_groups.each do |name, control_group|
          audit_data.add_control_group(control_group)
        end
        post_auditing_data
      end

      # If the audit phase failed, its because there was some kind of error in the framework
      # that runs tests - normal errors are interpreted as EXAMPLE failures and captured.
      def audit_phase_failed(error)
        # The stacktrace information has already been logged elsewhere
        Chef::Log.error("Audit Reporter failed - not sending any auditing information to the server")
      end

      def control_group_started(name)
        if ordered_control_groups.has_key?(name)
          raise AuditControlGroupDuplicate.new(name)
        end
        ordered_control_groups.store(name, ControlGroupData.new(name))
      end

      def control_example_success(control_group_name, example_data)
        control_group = ordered_control_groups[control_group_name]
        control_group.example_success(example_data)
      end

      def control_example_failure(control_group_name, example_data, error)
        control_group = ordered_control_groups[control_group_name]
        control_group.example_failure(example_data, error.message)
      end

      def auditing_enabled?
        @audit_enabled
      end

      private

      def post_auditing_data
        if auditing_enabled?
          audit_history_url = "controls"
          Chef::Log.info("Sending audit report (run-id: #{audit_data.run_id})")
          run_data = audit_data.to_hash
          Chef::Log.debug run_data.inspect
          compressed_data = encode_gzip(Chef::JSONCompat.to_json(run_data))
          Chef::Log.debug("Sending compressed audit data...")
          # Since we're posting compressed data we can not directly call post_rest which expects JSON
          audit_url = rest_client.create_url(audit_history_url)
          begin
            puts Chef::JSONCompat.to_json_pretty(run_data)
            rest_client.raw_http_request(:POST, audit_url, headers({'Content-Encoding' => 'gzip'}), compressed_data)
          rescue StandardError => e
            if e.respond_to? :response
              error_file = "failed-audit-data.json"
              Chef::FileCache.store(error_file, Chef::JSONCompat.to_json_pretty(run_data), 0640)
              Chef::Log.error("Failed to post audit report to server (HTTP #{e.response.code}), saving to #{Chef::FileCache.load(error_file, false)}")
            else
              Chef::Log.error("Failed to post audit report to server (#{e})")
            end
          end
        else
          Chef::Log.debug("Server doesn't support audit report, skipping.")
        end
      end

      def headers(additional_headers = {})
        options = {'X-Ops-Audit-Report-Protocol-Version' => PROTOCOL_VERSION}
        options.merge(additional_headers)
      end

      def encode_gzip(data)
        "".tap do |out|
          Zlib::GzipWriter.wrap(StringIO.new(out)){|gz| gz << data }
        end
      end

    end
  end
end
