#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'tempfile'
require 'uri'

class Chef
  class Provider
    class HttpRequest < Chef::Provider

      attr_accessor :rest

      def whyrun_supported?
        true
      end

      def load_current_resource
        @rest = Chef::REST.new(@new_resource.url, nil, nil)
      end

      # Send a HEAD request to @new_resource.url, with ?message=@new_resource.message
      def action_head
        message = check_message(@new_resource.message)
        # returns true from Chef::REST if returns 2XX (Net::HTTPSuccess)
        modified = @rest.head(
          url(:message => message),
          @new_resource.headers
        )
        Chef::Log.info("#{@new_resource} HEAD to #{url} successful")
        Chef::Log.debug("#{@new_resource} HEAD request response: #{modified}")
        # :head is usually used to trigger notifications, which converge_by now does
        if modified
          converge_by("#{@new_resource} HEAD to #{url} returned modified, trigger notifications") {}
        end
      end

      # Send a GET request to @new_resource.url, with ?message=@new_resource.message
      def action_get
        converge_by("#{@new_resource} GET to #{url}") do

          message = check_message(@new_resource.message)
          body = @rest.get(
            url(:message => message),
            false,
            @new_resource.headers
          )
          Chef::Log.info("#{@new_resource} GET to #{url} successful")
          Chef::Log.debug("#{@new_resource} GET request response: #{body}")
        end
      end

      # Send a PUT request to @new_resource.url, with the message as the payload
      def action_put
        converge_by("#{@new_resource} PUT to #{url}") do
          message = check_message(@new_resource.message)
          body = @rest.put(
            url,
            message,
            @new_resource.headers
          )
          Chef::Log.info("#{@new_resource} PUT to #{url} successful")
          Chef::Log.debug("#{@new_resource} PUT request response: #{body}")
        end
      end

      # Send a POST request to @new_resource.url, with the message as the payload
      def action_post
        converge_by("#{@new_resource} POST to #{url}") do
          message = check_message(@new_resource.message)
          body = @rest.post(
            url,
            message,
            @new_resource.headers
          )
          Chef::Log.info("#{@new_resource} POST to #{url} message: #{message.inspect} successful")
          Chef::Log.debug("#{@new_resource} POST request response: #{body}")
        end
      end

      # Send a DELETE request to @new_resource.url
      def action_delete
        converge_by("#{@new_resource} DELETE to #{url}") do
          body = @rest.delete(
            url,
            @new_resource.headers
          )
          @new_resource.updated_by_last_action(true)
          Chef::Log.info("#{@new_resource} DELETE to #{url} successful")
          Chef::Log.debug("#{@new_resource} DELETE request response: #{body}")
        end
      end

      private

        def url(query_params = {})
          uri = URI.parse @new_resource.url
          query_params.merge! parse_query_string(uri.query) if uri.query
          uri.query = query_params.map{|k,v| "#{k}=#{URI.escape(v)}"}.join("&")
          URI.unescape uri.to_s.tap {|q| q.chop! if q.end_with?("?") }
        end

        def parse_query_string(query_string)
          query_string.split("&").map{|kv| kv.split("=")}.inject({}) do |h, (k,v)|
            h[k] = v
            h
          end
        end

        def check_message(message)
          if message.kind_of?(Proc)
            message.call
          else
            message
          end
        end

    end
  end
end
