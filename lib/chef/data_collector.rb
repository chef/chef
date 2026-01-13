#
# Author:: Adam Leff (<adamleff@chef.io>)
# Author:: Ryan Cragun (<ryan@chef.io>)
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

require_relative "server_api"
require_relative "http/simple_json"
require_relative "event_dispatch/base"
autoload :Set, "set"
require_relative "data_collector/run_end_message"
require_relative "data_collector/run_start_message"
require_relative "data_collector/config_validation"
require_relative "data_collector/error_handlers"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class DataCollector
    # The DataCollector is mode-agnostic reporting tool which can be used with
    # server-based and solo-based clients.  It can report to a file, to an
    # authenticated Chef Automate reporting endpoint, or to a user-supplied
    # webhook.  It sends two messages:  one at the start of the run and one
    # at the end of the run.  Most early failures in the actual Chef::Client itself
    # are reported, but parsing of the client.rb must have succeeded and some code
    # in Chef::Application could throw so early as to prevent reporting.  If
    # exceptions are thrown both run-start and run-end messages are still sent in
    # pairs.
    #
    class Reporter < EventDispatch::Base
      include Chef::DataCollector::ErrorHandlers

      # @return [Chef::RunList::RunListExpansion] the expanded run list
      attr_reader :expanded_run_list

      # @return [Chef::RunStatus] the run status
      attr_reader :run_status

      # @return [Chef::Node] the chef node
      attr_reader :node

      # @return [Set<Hash>] the accumulated list of deprecation warnings
      attr_reader :deprecations

      # @return [Chef::ActionCollection] the action collection object
      attr_reader :action_collection

      # @return [Chef::EventDispatch::Dispatcher] the event dispatcher
      attr_reader :events

      # @param events [Chef::EventDispatch::Dispatcher] the event dispatcher
      def initialize(events)
        @events = events
        @expanded_run_list = {}
        @deprecations = Set.new
      end

      # Hook to grab the run_status.  We also make the decision to run or not run here (our
      # config has been parsed so we should know if we need to run, we unregister if we do
      # not want to run).
      #
      # (see EventDispatch::Base#run_start)
      #
      def run_start(chef_version, run_status)
        events.unregister(self) unless Chef::DataCollector::ConfigValidation.should_be_enabled?
        @run_status = run_status
      end

      # Hook to grab the node object after it has been successfully loaded
      #
      # (see EventDispatch::Base#node_load_success)
      #
      def node_load_success(node)
        @node = node
      end

      # The expanded run list is stored for later use by the run_completed
      # event and message.
      #
      # (see EventDispatch::Base#run_list_expanded)
      #
      def run_list_expanded(run_list_expansion)
        @expanded_run_list = run_list_expansion
      end

      # Hook event to register with the action_collection if we are still enabled.
      #
      # This is also how we wire up to the action_collection since it passes itself as the argument.
      #
      # (see EventDispatch::Base#action_collection_registration)
      #
      def action_collection_registration(action_collection)
        @action_collection = action_collection
      end

      # - Creates and writes our NodeUUID back to the node object
      # - Sanity checks the data collector
      # - Sends the run start message
      # - If the run_start message fails, this may disable the rest of data collection or fail hard
      #
      # (see EventDispatch::Base#run_started)
      #
      def run_started(run_status)
        Chef::DataCollector::ConfigValidation.validate_server_url!
        Chef::DataCollector::ConfigValidation.validate_output_locations!

        send_run_start
      end

      # Hook event to accumulating deprecation messages
      #
      # (see EventDispatch::Base#deprecation)
      #
      def deprecation(message, location = caller(2..2)[0])
        @deprecations << { message: message.message, url: message.url, location: message.location }
      end

      # Hook to send the run completion message with a status of success
      #
      # (see EventDispatch::Base#run_completed)
      #
      def run_completed(node)
        send_run_completion("success")
      end

      # Hook to send the run completion message with a status of failed
      #
      # (see EventDispatch::Base#run_failed)
      #
      def run_failed(exception)
        send_run_completion("failure")
      end

      private

      # Construct a http client for either the main data collector or for the http output_locations.
      #
      # Note that based on the token setting either the main data collector and all the http output_locations
      # are going to all require chef-server authentication or not.  There is no facility to mix-and-match on
      # a per-url basis.
      #
      # @param url [String] the string url to connect to
      # @returns [Chef::HTTP] the appropriate Chef::HTTP subclass instance to use
      #
      def setup_http_client(url)
        if Chef::Config[:data_collector][:token].nil?
          Chef::ServerAPI.new(url, validate_utf8: false)
        else
          Chef::HTTP::SimpleJSON.new(url, validate_utf8: false)
        end
      end

      # Handle POST'ing data to the data collector.  Note that this is a totally separate concern
      # from the array of URI's in the extra configured output_locations.
      #
      # On failure this will unregister the data collector (if there are no other configured output_locations)
      # and optionally will either silently continue or fail hard depending on configuration.
      #
      # @param message [Hash] message to send
      #
      def send_to_data_collector(message)
        return unless Chef::Config[:data_collector][:server_url]

        @http ||= setup_http_client(Chef::Config[:data_collector][:server_url])
        @http.post(nil, message, headers)
      rescue => e
        # Do not disable data collector reporter if additional output_locations have been specified
        events.unregister(self) unless Chef::Config[:data_collector][:output_locations]

        begin
          code = e&.response&.code.to_s
        rescue
          # i really don't care
        end

        code ||= "No HTTP Code"

        msg = "Error while reporting run start to Data Collector. URL: #{Chef::Config[:data_collector][:server_url]} Exception: #{code} -- #{e.message} "

        if Chef::Config[:data_collector][:raise_on_failure]
          Chef::Log.error(msg)
          raise
        else
          if code == "404"
            # Make the message non-scary for folks who don't have automate:
            msg << " (This is normal if you do not have #{ChefUtils::Dist::Automate::PRODUCT})"
            Chef::Log.debug(msg)
          else
            Chef::Log.warn(msg)
          end
        end
      end

      # Process sending the configured message to all the extra output locations.
      #
      # @param message [Hash] message to send
      #
      def send_to_output_locations(message)
        return unless Chef::Config[:data_collector][:output_locations]

        Chef::DataCollector::ConfigValidation.validate_output_locations!
        Chef::Config[:data_collector][:output_locations].each do |type, locations|
          Array(locations).each do |location|
            send_to_file_location(location, message) if type == :files
            send_to_http_location(location, message) if type == :urls
          end
        end
      end

      # Sends a single message to a file, rendered as JSON.
      #
      # @param file_name [String] the file to write to
      # @param message [Hash] the message to render as JSON
      #
      def send_to_file_location(file_name, message)
        File.open(File.expand_path(file_name), "a") do |fh|
          fh.puts Chef::JSONCompat.to_json(message, validate_utf8: false)
        end
      end

      # Sends a single message to a http uri, rendered as JSON.  Maintains a cache of Chef::HTTP
      # objects to use on subsequent requests.
      #
      # @param http_url [String] the configured http uri string endpoint to send to
      # @param message [Hash] the message to render as JSON
      #
      def send_to_http_location(http_url, message)
        @http_output_locations_clients[http_url] ||= setup_http_client(http_url)
        @http_output_locations_clients[http_url].post(nil, message, headers)
      rescue
        # FIXME: we do all kinds of complexity to deal with errors in send_to_data_collector and we just don't care here, which feels like
        # like poor behavior on several different levels, at least its a warn now... (I don't quite understand why it was written this way)
        Chef::Log.warn("Data collector failed to send to URL location #{http_url}. Please check your configured data_collector.output_locations")
      end

      # @return [Boolean] if we've sent a run_start message yet
      def sent_run_start?
        !!@sent_run_start
      end

      # Send the run start message to the configured server or output locations
      #
      def send_run_start
        message = Chef::DataCollector::RunStartMessage.construct_message(self)
        send_to_data_collector(message)
        send_to_output_locations(message)
        @sent_run_start = true
      end

      # Send the run completion message to the configured server or output locations
      #
      # @param status [String] Either "success" or "failed"
      #
      def send_run_completion(status)
        # this is necessary to send a run_start message when we fail before the run_started chef event.
        # we adhere to a contract that run_start + run_completion events happen in pairs.
        send_run_start unless sent_run_start?

        message = Chef::DataCollector::RunEndMessage.construct_message(self, status)
        send_to_data_collector(message)
        send_to_output_locations(message)
      end

      # @return [Hash] HTTP headers for the data collector endpoint
      def headers
        headers = { "Content-Type" => "application/json" }

        unless Chef::Config[:data_collector][:token].nil?
          headers["x-data-collector-token"] = Chef::Config[:data_collector][:token]
          headers["x-data-collector-auth"]  = "version=1.0"
        end

        headers
      end
    end
  end
end
