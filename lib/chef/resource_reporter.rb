#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Prajakta Purohit (prajakta@opscode.com>)
# Auther:: Tyler Cloke (<tyler@opscode.com>)
#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'uri'
require 'chef/event_dispatch/base'

class Chef
  class ResourceReporter < EventDispatch::Base



    class ResourceReport < Struct.new(:new_resource,
                                      :current_resource,
                                      :action,
                                      :exception,
                                      :elapsed_time)

      def self.new_with_current_state(new_resource, action, current_resource)
        report = new
        report.new_resource = new_resource
        report.action = action
        report.current_resource = current_resource
        report
      end

      def self.new_for_exception(new_resource, action)
        report = new
        report.new_resource = new_resource
        report.action = action
        report
      end

      def for_json
        as_hash = {}
        as_hash["type"]   = new_resource.class.dsl_name
        as_hash["name"]   = new_resource.name
        as_hash["id"]     = new_resource.identity
        as_hash["after"]  = new_resource.state
        as_hash["before"] = current_resource ? current_resource.state : {}
        as_hash["duration"] = (elapsed_time * 1000).to_i.to_s
        as_hash["delta"]  = new_resource.diff if new_resource.respond_to?("diff")
        as_hash["delta"]  = "" if as_hash["delta"].nil?

        # TODO: rename as "action"
        as_hash["result"] = action.to_s
        if success?
        else
          #as_hash["result"] = "failed"
        end
        as_hash["cookbook_name"] = new_resource.cookbook_name
        as_hash["cookbook_version"] = new_resource.cookbook_version.version
        as_hash

      end

      def finish
        self.elapsed_time = new_resource.elapsed_time
      end

      def success?
        !self.exception
      end
    end

    attr_reader :updated_resources
    attr_reader :status
    attr_reader :exception
    attr_reader :run_id
    attr_reader :error_descriptions
    attr_reader :summary_only

    def initialize(rest_client)
      if Chef::Config[:enable_reporting] && !Chef::Config[:why_run]
        @reporting_enabled = true
      else
        @reporting_enabled = false
      end
      @updated_resources = []
      @total_res_count = 0
      @pending_update  = nil
      @status = "success"
      @exception = nil
      @run_id = nil
      @rest_client = rest_client
      @node = nil
      @error_descriptions = {}
      @summary_only = true
    end

    def node_load_completed(node, expanded_run_list_with_versions, config)
      @node = node
      if reporting_enabled?
        begin
          resource_history_url = "reports/nodes/#{node.name}/runs"
          server_response = @rest_client.post_rest(resource_history_url, {:action => :begin})
          run_uri = URI.parse(server_response["uri"])
          @run_id = ::File.basename(run_uri.path)
          Chef::Log.info("Chef server generated run history id: #{@run_id}")
          @summary_only = server_response["summary_only"]
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          if !e.response || e.response.code.to_s != "404"
            if Chef::Config[:enable_reporting_url_fatals]
              Chef::Log.error("Received exception #{"(" + e.response.code + ") " if e.response.code}attempting to generate run history id (URL Path: #{resource_history_url}), and enable_reporting_url_fatals is set, aborting run.")
              raise
            else
              Chef::Log.info("Received exception #{"(" + e.response.code + ") " if e.response.code}attempting to generate run history id (URL Path: #{resource_history_url}), disabling reporting for this run.")
            end
          else
            Chef::Log.debug("Received 404 attempting to generate run history id (URL Path: #{resource_history_url}), assuming feature is not supported on server.")
          end
          @reporting_enabled = false
        end
      end
    end

    def resource_current_state_loaded(new_resource, action, current_resource)
      unless nested_resource?(new_resource)
        @pending_update = ResourceReport.new_with_current_state(new_resource, action, current_resource)
      end
    end

    def resource_up_to_date(new_resource, action)
      @total_res_count += 1
      @pending_update = nil unless nested_resource?(new_resource)
    end

    def resource_skipped(resource, action, conditional)
      @total_res_count += 1
      @pending_update = nil unless nested_resource?(resource)
    end

    def resource_updated(new_resource, action)
      @total_res_count += 1
    end

    def resource_failed(new_resource, action, exception)
      @total_res_count += 1
      unless nested_resource?(new_resource)
        @pending_update ||= ResourceReport.new_for_exception(new_resource, action)
        @pending_update.exception = exception
      end
      description = Formatters::ErrorMapper.resource_failed(new_resource, action, exception)
      @error_descriptions = description.for_json
    end

    def resource_completed(new_resource)
      if @pending_update && !nested_resource?(new_resource)
        @pending_update.finish
        @updated_resources << @pending_update
        @pending_update = nil
      end
    end

    def run_completed(node)
      @status = "success"
      post_reporting_data
    end

    def run_failed(exception)
      @exception = exception
      @status = "failure"
      post_reporting_data
    end

    def post_reporting_data
      if reporting_enabled?
        run_data = prepare_run_data
        resource_history_url = "reports/nodes/#{@node.name}/runs/#{@run_id}"
        Chef::Log.info("Sending resource update report (run-id: #{@run_id})")
        Chef::Log.debug run_data.inspect
        compressed_data = encode_gzip(run_data.to_json)
        begin
          #if summary only is enabled send the uncompressed run_data excluding the run_data["resources"] and some additional metrics.
          if @summary_only
            run_data = report_summary(run_data, compressed_data)
            Chef::Log.info("run_data_summary: #{run_data}")
            @rest_client.post_rest(resource_history_url, run_data)
          else
            Chef::Log.debug("Sending compressed run data...")
            # Since we're posting compressed data we can not directly call
            # post_rest which expects JSON
            reporting_url = @rest_client.create_url(resource_history_url)
            @rest_client.raw_http_request(:POST, reporting_url, {'Content-Encoding' => 'gzip'}, compressed_data)
          end
        rescue Net::HTTPServerException => e
          if e.response.code.to_s == "400"
            Chef::FileCache.store("failed-reporting-data.json", Chef::JSONCompat.to_json_pretty(run_data), 0640)
            Chef::Log.error("Failed to post reporting data to server (HTTP 400), saving to #{Chef::FileCache.load("failed-reporting-data.json", false)}")
          else
            Chef::Log.error("Failed to post reporting data to server (HTTP #{e.response.code.to_s})")
          end
        end
      else
        Chef::Log.debug("Server doesn't support resource history, skipping resource report.")
      end
    end
    
    def prepare_run_data
      run_data = {}
      run_data["action"] = "end"
      run_data["resources"] = updated_resources.map do |resource_record|
        resource_record.for_json
      end
      run_data["status"] = @status
      run_data["run_list"] = @node.run_list.to_json
      run_data["total_res_count"] = @total_res_count.to_s
      run_data["data"] = {}

      if exception
        exception_data = {}
        exception_data["class"] = exception.inspect
        exception_data["message"] = exception.message
        exception_data["backtrace"] = exception.backtrace.to_json
        exception_data["description"] =  @error_descriptions
        run_data["data"]["exception"] = exception_data
      end
      run_data
    end

    def report_summary(run_data, compressed_data)
      run_data["updated_res_count"] = updated_resources.count.to_s
      run_data["post_size"] = compressed_data.bytesize.to_s
      run_data["resources"] = []
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

    def reporting_enabled?
      @reporting_enabled
    end

    private

    # If we are getting messages about a resource while we are in the middle of
    # another resource's update, we assume that the nested resource is just the
    # implementation of a provider, and we want to hide it from the reporting
    # output.
    def nested_resource?(new_resource)
      @pending_update && @pending_update.new_resource != new_resource
    end

    def encode_gzip(data)
      "".tap do |out|
        Zlib::GzipWriter.wrap(StringIO.new(out)){|gz| gz << data }
      end
    end

  end
end
