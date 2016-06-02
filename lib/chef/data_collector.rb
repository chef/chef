#
# Author:: Adam Leff (<adamleff@chef.io>)
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

require "uri"
require "chef/event_dispatch/base"
require "chef/data_collector/messages"
require "chef/data_collector/resource_report"

class Chef

  # == Chef::DataCollector
  # Provides methods for determinine whether a reporter should be registered.
  class DataCollector
    def self.register_reporter?
      Chef::Config[:data_collector][:server_url] &&
        !Chef::Config[:why_run] &&
        self.reporter_enabled_for_current_mode?
    end

    def self.reporter_enabled_for_current_mode?
      if Chef::Config[:solo] || Chef::Config[:local_mode]
        acceptable_modes = [:solo, :both]
      else
        acceptable_modes = [:client, :both]
      end

      acceptable_modes.include?(Chef::Config[:data_collector][:mode])
    end

    # == Chef::DataCollector::Reporter
    # Provides an event handler that can be registered to report on Chef
    # run data. Unlike the existing Chef::ResourceReporter event handler,
    # the DataCollector handler is not tied to a Chef Server / Chef Reporting
    # and exports its data through a webhook-like mechanism to a configured
    # endpoint.
    class Reporter < EventDispatch::Base
      attr_reader :updated_resources, :status, :exception, :error_descriptions,
                  :expanded_run_list, :run_status, :http, :resource_count,
                  :current_resource_report, :enabled

      def initialize
        @updated_resources       = []
        @resource_count          = 0
        @current_resource_loaded = nil
        @error_descriptions      = {}
        @expanded_run_list       = {}
        @http                    = Chef::HTTP.new(data_collector_server_url)
        @enabled                 = true
      end

      # see EventDispatch::Base#run_started
      # Upon receipt, we will send our run start message to the
      # configured DataCollector endpoint. Depending on whether
      # the user has configured raise_on_failure, if we cannot
      # send the message, we will either disable the DataCollector
      # Reporter for the duration of this run, or we'll raise an
      # exception.
      def run_started(current_run_status)
        update_run_status(current_run_status)

        disable_reporter_on_error do
          send_to_data_collector(
            Chef::DataCollector::Messages.run_start_message(current_run_status).to_json
          )
        end
      end

      # see EventDispatch::Base#run_completed
      # Upon receipt, we will send our run completion message to the
      # configured DataCollector endpoint.
      def run_completed(node)
        send_run_completion(status: "success")
      end

      # see EventDispatch::Base#run_failed
      def run_failed(exception)
        send_run_completion(status: "failure")
      end

      # see EventDispatch::Base#resource_current_state_loaded
      # Create a new ResourceReport instance that we'll use to track
      # the state of this resource during the run. Nested resources are
      # ignored as they are assumed to be an inline resource of a custom
      # resource, and we only care about tracking top-level resources.
      def resource_current_state_loaded(new_resource, action, current_resource)
        return if nested_resource?(new_resource)
        update_current_resource_report(
          Chef::DataCollector::ResourceReport.new(
            new_resource,
            action,
            current_resource
          )
        )
      end

      # see EventDispatch::Base#resource_up_to_date
      # Mark our ResourceReport status accordingly, and increment the total
      # resource count.
      def resource_up_to_date(new_resource, action)
        current_resource_report.up_to_date unless nested_resource?(new_resource)
        increment_resource_count
      end

      # see EventDispatch::Base#resource_skipped
      # Increment the total resource count. If this is a top-level resource,
      # we also create a ResourceReport instance (because a skipped resource
      # does not trigger the resource_current_state_loaded event), and flag
      # it as skipped.
      def resource_skipped(new_resource, action, conditional)
        increment_resource_count
        return if nested_resource?(new_resource)

        update_current_resource_report(
          Chef::DataCollector::ResourceReport.new(
            new_resource,
            action
          )
        )
        current_resource_report.skipped(conditional)
      end

      # see EventDispatch::Base#resource_updated
      # Flag the current ResourceReport instance as updated (as long as it's
      # a top-level resource) and increment the total resource count.
      def resource_updated(new_resource, action)
        current_resource_report.updated unless nested_resource?(new_resource)
        increment_resource_count
      end

      # see EventDispatch::Base#resource_failed
      # Flag the current ResourceReport as failed and supply the exception as
      # long as it's a top-level resource, increment the total resource count,
      # and update the run error text with the proper Formatter.
      def resource_failed(new_resource, action, exception)
        current_resource_report.failed(exception) unless nested_resource?(new_resource)
        increment_resource_count
        update_error_description(
          Formatters::ErrorMapper.resource_failed(
            new_resource,
            action,
            exception
          ).for_json
        )
      end

      # see EventDispatch::Base#resource_completed
      # Mark the ResourceReport instance as finished (for timing details)
      # and add it to the list of resources encountered during this run.
      # This marks the end of this resource during this run.
      def resource_completed(new_resource)
        if current_resource_report && !nested_resource?(new_resource)
          current_resource_report.finish
          add_updated_resource(current_resource_report)
          update_current_resource_report(nil)
        end
      end

      # see EventDispatch::Base#run_list_expanded
      # The expanded run list is stored for later use by the run_completed
      # event and message.
      def run_list_expanded(run_list_expansion)
        @expanded_run_list = run_list_expansion
      end

      # see EventDispatch::Base#run_list_expand_failed
      # The run error text is updated with the output of the appropriate
      # formatter.
      def run_list_expand_failed(node, exception)
        update_error_description(
          Formatters::ErrorMapper.run_list_expand_failed(
            node,
            exception
          ).for_json
        )
      end

      # see EventDispatch::Base#cookbook_resolution_failed
      # The run error text is updated with the output of the appropriate
      # formatter.
      def cookbook_resolution_failed(expanded_run_list, exception)
        update_error_description(
          Formatters::ErrorMapper.cookbook_resolution_failed(
            expanded_run_list,
            exception
          ).for_json
        )
      end

      # see EventDispatch::Base#cookbook_sync_failed
      # The run error text is updated with the output of the appropriate
      # formatter.
      def cookbook_sync_failed(cookbooks, exception)
        update_error_description(
          Formatters::ErrorMapper.cookbook_sync_failed(
            cookbooks,
            exception
          ).for_json
        )
      end

      private

      #
      # Yields to the passed-in block (which is expected to be some interaction
      # with the DataCollector endpoint). If some communication failure occurs,
      # either disable any future communications to the DataCollector endpoint, or
      # raise an exception (if the user has set
      # Chef::Config.data_collector.raise_on_failure to true.)
      #
      # @param block [Proc] A ruby block to run. Ignored if a command is given.
      #
      def disable_reporter_on_error
        yield
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
             Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
        disable_data_collector_reporter
        code = if e.respond_to?(:response) && e.response.code
                 e.response.code.to_s
               else
                 "Exception Code Empty"
               end

        msg = "Error while reporting run start to Data Collector. " \
              "URL: #{data_collector_server_url} " \
              "Exception: #{code} -- #{e.message} "

        if Chef::Config[:data_collector][:raise_on_failure]
          Chef::Log.error(msg)
          raise
        else
          Chef::Log.warn(msg)
        end
      end

      def send_to_data_collector(message)
        return unless data_collector_accessible?

        Chef::Log.debug("data_collector_reporter: POSTing the following message to #{data_collector_server_url}: #{message}")
        http.post(nil, message, headers)
      end

      #
      # Send any messages to the DataCollector endpoint that are necessary to
      # indicate the run has completed. Currently, two messages are sent:
      #
      # - An "action" message with the node object indicating it's been updated
      # - An "run_converge" (i.e. RunEnd) message with details about the run,
      #   what resources were modified/up-to-date/skipped, etc.
      #
      # @param opts [Hash] Additional details about the run, such as its success/failure.
      #
      def send_run_completion(opts)
        # If run_status is nil we probably failed before the client triggered
        # the run_started callback. In this case we'll skip updating because
        # we have nothing to report.
        return unless run_status

        send_to_data_collector(Chef::DataCollector::Messages.node_update_message(run_status).to_json)
        send_to_data_collector(
          Chef::DataCollector::Messages.run_end_message(
            run_status: run_status,
            expanded_run_list: expanded_run_list,
            total_resource_count: resource_count,
            updated_resources: updated_resources,
            status: opts[:status],
            error_descriptions: error_descriptions
          ).to_json
        )
      end

      def headers
        headers = { "Content-Type" => "application/json" }

        unless data_collector_token.nil?
          headers["x-data-collector-token"] = data_collector_token
          headers["x-data-collector-auth"]  = "version=1.0"
        end

        headers
      end

      def data_collector_server_url
        Chef::Config[:data_collector][:server_url]
      end

      def data_collector_token
        Chef::Config[:data_collector][:token]
      end

      def increment_resource_count
        @resource_count += 1
      end

      def add_updated_resource(resource_report)
        @updated_resources << resource_report
      end

      def disable_data_collector_reporter
        @enabled = false
      end

      def data_collector_accessible?
        @enabled
      end

      def update_run_status(run_status)
        @run_status = run_status
      end

      def update_current_resource_report(resource_report)
        @current_resource_report = resource_report
      end

      def update_error_description(discription_hash)
        @error_descriptions = discription_hash
      end

      # If we are getting messages about a resource while we are in the middle of
      # another resource's update, we assume that the nested resource is just the
      # implementation of a provider, and we want to hide it from the reporting
      # output.
      def nested_resource?(new_resource)
        @current_resource_report && @current_resource_report.new_resource != new_resource
      end
    end
  end
end
