#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Prajakta Purohit (prajakta@chef.io>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

require_relative "event_dispatch/base"

class Chef
  class ResourceReporter < EventDispatch::Base
    def for_json(action_record)
      new_resource = action_record.new_resource
      current_resource = action_record.current_resource

      as_hash = {}
      as_hash["type"]     = new_resource.resource_name.to_sym
      as_hash["name"]     = new_resource.name.to_s
      as_hash["id"]       = new_resource.identity.to_s
      as_hash["after"]    = new_resource.state_for_resource_reporter
      as_hash["before"]   = current_resource ? current_resource.state_for_resource_reporter : {}
      as_hash["duration"] = ( action_record.elapsed_time * 1000 ).to_i.to_s
      as_hash["delta"]    = new_resource.diff if new_resource.respond_to?("diff")
      as_hash["delta"]    = "" if as_hash["delta"].nil?

      # TODO: rename as "action"
      as_hash["result"] = action_record.action.to_s
      if new_resource.cookbook_name
        as_hash["cookbook_name"] = new_resource.cookbook_name
        as_hash["cookbook_version"] = new_resource.cookbook_version.version
      end

      as_hash
    end

    attr_reader :status
    attr_reader :exception
    attr_reader :error_descriptions
    attr_reader :action_collection
    attr_reader :rest_client

    PROTOCOL_VERSION = "0.1.0".freeze

    def initialize(rest_client)
      @pending_update = nil
      @status = "success"
      @exception = nil
      @rest_client = rest_client
      @error_descriptions = {}
      @expanded_run_list = {}
    end

    def run_started(run_status)
      @run_status = run_status

      if reporting_enabled?
        begin
          resource_history_url = "reports/nodes/#{node_name}/runs"
          server_response = rest_client.post(resource_history_url, { action: :start, run_id: run_id,
                                                                     start_time: start_time.to_s }, headers)
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          handle_error_starting_run(e, resource_history_url)
        end
      end
    end

    def handle_error_starting_run(e, url)
      message = "Reporting error starting run. URL: #{url} "
      code = if e.response.code
               e.response.code.to_s
             else
               "Exception Code Empty"
             end

      if !e.response || (code != "404" && code != "406")
        exception = "Exception: #{code} "
        if Chef::Config[:enable_reporting_url_fatals]
          reporting_status = "Reporting fatals enabled. Aborting run. "
          Chef::Log.error(message + exception + reporting_status)
          raise
        else
          reporting_status = "Disabling reporting for run."
          Chef::Log.info(message + exception + reporting_status)
        end
      else
        reason = "Received #{code}. "
        if code == "406"
          reporting_status = "Client version not supported. Please update the client. Disabling reporting for run."
          Chef::Log.info(message + reason + reporting_status)
        else
          reporting_status = "Disabling reporting for run."
          Chef::Log.trace(message + reason + reporting_status)
        end
      end

      @runs_endpoint_failed = true
    end

    def run_id
      @run_status.run_id
    end

    def run_completed(node)
      @status = "success"
      post_reporting_data
    end

    def run_failed(exception)
      @exception = exception
      @status = "failure"
      # If we failed before we received the run_started callback, there's not much we can do
      # in terms of reporting
      if @run_status
        post_reporting_data
      end
    end

    def run_list_expanded(run_list_expansion)
      @expanded_run_list = run_list_expansion
    end

    def action_collection_registration(action_collection)
      @action_collection = action_collection
    end

    def post_reporting_data
      if reporting_enabled?
        run_data = prepare_run_data
        resource_history_url = "reports/nodes/#{node_name}/runs/#{run_id}"
        Chef::Log.info("Sending resource update report (run-id: #{run_id})")
        Chef::Log.trace run_data.inspect
        compressed_data = encode_gzip(Chef::JSONCompat.to_json(run_data))
        Chef::Log.trace("Sending compressed run data...")
        # Since we're posting compressed data we can not directly call post which expects JSON
        begin
          rest_client.raw_request(:POST, resource_history_url, headers({ "Content-Encoding" => "gzip" }), compressed_data)
        rescue StandardError => e
          if e.respond_to? :response
            Chef::FileCache.store("failed-reporting-data.json", Chef::JSONCompat.to_json_pretty(run_data), 0640)
            Chef::Log.error("Failed to post reporting data to server (HTTP #{e.response.code}), saving to #{Chef::FileCache.load("failed-reporting-data.json", false)}")
          else
            Chef::Log.error("Failed to post reporting data to server (#{e})")
          end
        end
      else
        Chef::Log.trace("Server doesn't support resource history, skipping resource report.")
      end
    end

    def headers(additional_headers = {})
      options = { "X-Ops-Reporting-Protocol-Version" => PROTOCOL_VERSION }
      options.merge(additional_headers)
    end

    def node_name
      @run_status.node.name
    end

    def start_time
      @run_status.start_time
    end

    def end_time
      @run_status.end_time
    end

    # get only the top level resources and strip out the subcollections
    def updated_resources
      @updated_resources ||= action_collection&.filtered_collection(max_nesting: 0, up_to_date: false, skipped: false, unprocessed: false) || {}
    end

    def total_res_count
      updated_resources.count
    end

    def prepare_run_data
      run_data = {}
      run_data["action"] = "end"
      run_data["resources"] = updated_resources.map do |action_record|
        for_json(action_record)
      end
      run_data["status"] = @status
      run_data["run_list"] = Chef::JSONCompat.to_json(@run_status.node.run_list)
      run_data["total_res_count"] = total_res_count.to_s
      run_data["data"] = {}
      run_data["start_time"] = start_time.to_s
      run_data["end_time"] = end_time.to_s
      run_data["expanded_run_list"] = Chef::JSONCompat.to_json(@expanded_run_list)

      if exception
        exception_data = {}
        exception_data["class"] = exception.inspect
        exception_data["message"] = exception.message
        exception_data["backtrace"] = Chef::JSONCompat.to_json(exception.backtrace)
        exception_data["description"] = @error_descriptions
        run_data["data"]["exception"] = exception_data
      end
      run_data
    end

    def run_list_expand_failed(node, exception)
      description = Formatters::ErrorMapper.run_list_expand_failed(node, exception)
      @error_descriptions = description.for_json
    end

    def cookbook_resolution_failed(expanded_run_list, exception)
      description = Formatters::ErrorMapper.cookbook_resolution_failed(expanded_run_list, exception)
      @error_descriptions = description.for_json
    end

    def cookbook_sync_failed(cookbooks, exception)
      description = Formatters::ErrorMapper.cookbook_sync_failed(cookbooks, exception)
      @error_descriptions = description.for_json
    end

    private

    def reporting_enabled?
      Chef::Config[:enable_reporting] && !Chef::Config[:why_run] && !@runs_endpoint_failed
    end

    def encode_gzip(data)
      "".tap do |out|
        Zlib::GzipWriter.wrap(StringIO.new(out)) { |gz| gz << data }
      end
    end

  end
end
