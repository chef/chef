#
# Author:: Adam Jacob (<adam@chef.io>)
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

require "tempfile" unless defined?(Tempfile)
require_relative "../http/simple"

class Chef
  class Provider
    class HttpRequest < Chef::Provider

      provides :http_request, target_mode: true

      attr_writer :http

      def http
        @http ||= TargetIO::HTTP.new(new_resource.url)
      end

      def load_current_resource; end

      # Send a HEAD request to new_resource.url
      action :head do
        message = check_message(new_resource.message)
        # CHEF-4762: we expect a nil return value from Chef::HTTP for a "200 Success" response
        # and false for a "304 Not Modified" response
        modified = http.head(
          (new_resource.url).to_s,
          new_resource.headers
        )
        logger.info("#{new_resource} HEAD to #{new_resource.url} successful")
        logger.trace("#{new_resource} HEAD request response: #{modified}")
        # :head is usually used to trigger notifications, which converge_by now does
        if modified != false
          converge_by("#{new_resource} HEAD to #{new_resource.url} returned modified, trigger notifications") {}
        end
      end

      # Send a GET request to new_resource.url
      action :get do
        converge_by("#{new_resource} GET to #{new_resource.url}") do

          message = check_message(new_resource.message)
          body = http.get(
            (new_resource.url).to_s,
            new_resource.headers
          )
          logger.info("#{new_resource} GET to #{new_resource.url} successful")
        end
      end

      # Send a PATCH request to new_resource.url, with the message as the payload
      action :patch do
        converge_by("#{new_resource} PATCH to #{new_resource.url}") do
          message = check_message(new_resource.message)
          body = http.patch(
            (new_resource.url).to_s,
            message,
            new_resource.headers
          )
          logger.info("#{new_resource} PATCH to #{new_resource.url} successful")
          logger.trace("#{new_resource} PATCH request response: #{body}")
        end
      end

      # Send a PUT request to new_resource.url, with the message as the payload
      action :put do
        converge_by("#{new_resource} PUT to #{new_resource.url}") do
          message = check_message(new_resource.message)
          body = http.put(
            (new_resource.url).to_s,
            message,
            new_resource.headers
          )
          logger.info("#{new_resource} PUT to #{new_resource.url} successful")
          logger.trace("#{new_resource} PUT request response: #{body}")
        end
      end

      # Send a POST request to new_resource.url, with the message as the payload
      action :post do
        converge_by("#{new_resource} POST to #{new_resource.url}") do
          message = check_message(new_resource.message)
          body = http.post(
            (new_resource.url).to_s,
            message,
            new_resource.headers
          )
          logger.info("#{new_resource} POST to #{new_resource.url} message: #{message.inspect} successful")
          logger.trace("#{new_resource} POST request response: #{body}")
        end
      end

      # Send a DELETE request to new_resource.url
      action :delete do
        converge_by("#{new_resource} DELETE to #{new_resource.url}") do
          body = http.delete(
            (new_resource.url).to_s,
            new_resource.headers
          )
          new_resource.updated_by_last_action(true)
          logger.info("#{new_resource} DELETE to #{new_resource.url} successful")
          logger.trace("#{new_resource} DELETE request response: #{body}")
        end
      end

      private

      def check_message(message)
        if message.is_a?(Proc)
          message.call
        else
          message
        end
      end

    end
  end
end
