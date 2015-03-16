#
# Author:: Tyler Ball (<tball@chef.io>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
require 'time'

class Chef
  class Audit
    class AuditReporter < EventDispatch::Base

      attr_reader :rest_client, :audit_data, :ordered_control_groups, :run_status
      private :rest_client, :audit_data, :ordered_control_groups, :run_status

      PROTOCOL_VERSION = '0.1.1'

      def initialize(rest_client)
        @rest_client = rest_client
        # Ruby 1.9.3 and above "enumerate their values in the order that the corresponding keys were inserted."
        @ordered_control_groups = Hash.new
      end

      def run_context
        run_status.run_context
      end

      def audit_phase_start(run_status)
        Chef::Log.debug("Audit Reporter starting")
        @audit_data = AuditData.new(run_status.node.name, run_status.run_id)
        @run_status = run_status
      end

      def audit_phase_complete
        Chef::Log.debug("Audit Reporter completed successfully without errors.")
        ordered_control_groups.each do |name, control_group|
          audit_data.add_control_group(control_group)
        end
      end

      # If the audit phase failed, its because there was some kind of error in the framework
      # that runs tests - normal errors are interpreted as EXAMPLE failures and captured.
      # We still want to send available audit information to the server so we process the
      # known control groups.
      def audit_phase_failed(error)
        # The stacktrace information has already been logged elsewhere
        Chef::Log.debug("Audit Reporter failed.")
        ordered_control_groups.each do |name, control_group|
          audit_data.add_control_group(control_group)
        end
      end

      def run_completed(node)
        post_auditing_data
      end

      def run_failed(error)
        post_auditing_data(error)
      end

      def control_group_started(name)
        if ordered_control_groups.has_key?(name)
          raise Chef::Exceptions::AuditControlGroupDuplicate.new(name)
        end
        metadata = run_context.audits[name].metadata
        ordered_control_groups.store(name, ControlGroupData.new(name, metadata))
      end

      def control_example_success(control_group_name, example_data)
        control_group = ordered_control_groups[control_group_name]
        control_group.example_success(example_data)
      end

      def control_example_failure(control_group_name, example_data, error)
        control_group = ordered_control_groups[control_group_name]
        control_group.example_failure(example_data, error.message)
      end

      # If @audit_enabled is nil or true, we want to run audits
      def auditing_enabled?
        Chef::Config[:audit_mode] != :disabled
      end

      private

      def post_auditing_data(error = nil)
        unless auditing_enabled?
          Chef::Log.debug("Audit Reports are disabled. Skipping sending reports.")
          return
        end

        unless run_status
          Chef::Log.debug("Run failed before audit mode was initialized, not sending audit report to server")
          return
        end

        audit_data.start_time = iso8601ify(run_status.start_time)
        audit_data.end_time = iso8601ify(run_status.end_time)

        audit_history_url = "controls"
        Chef::Log.debug("Sending audit report (run-id: #{audit_data.run_id})")
        run_data = audit_data.to_hash

        if error
          run_data[:error] = "#{error.class.to_s}: #{error.message}\n#{error.backtrace.join("\n")}"
        end

        Chef::Log.debug "Audit Report:\n#{Chef::JSONCompat.to_json_pretty(run_data)}"
        # Since we're posting compressed data we can not directly call post_rest which expects JSON
        begin
          audit_url = rest_client.create_url(audit_history_url)
          rest_client.post(audit_url, run_data, headers)
        rescue StandardError => e
          if e.respond_to? :response
            # 404 error code is OK. This means the version of server we're running against doesn't support
            # audit reporting. Don't alarm failure in this case.
            if e.response.code == "404"
              Chef::Log.debug("Server doesn't support audit reporting. Skipping report.")
              return
            else
              # Save the audit report to local disk
              error_file = "failed-audit-data.json"
              Chef::FileCache.store(error_file, Chef::JSONCompat.to_json_pretty(run_data), 0640)
              Chef::Log.error("Failed to post audit report to server. Saving report to #{Chef::FileCache.load(error_file, false)}")
            end
          else
            Chef::Log.error("Failed to post audit report to server (#{e})")
          end

          if Chef::Config[:enable_reporting_url_fatals]
            Chef::Log.error("Reporting fatals enabled. Aborting run.")
            raise
          end
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

      def iso8601ify(time)
        time.utc.iso8601.to_s
      end

    end
  end
end
