#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
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

class Chef
  module Formatters

    module APIErrorFormatting

      NETWORK_ERROR_CLASSES = [Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError]

      def describe_network_errors(error_description)
        error_description.section("Networking Error:",<<-E)
#{exception.message}

Your chef_server_url may be misconfigured, or the network could be down.
E
        error_description.section("Relevant Config Settings:",<<-E)
chef_server_url  "#{server_url}"
E
      end

      def describe_401_error(error_description)
        if clock_skew?
          error_description.section("Authentication Error:",<<-E)
Failed to authenticate to the chef server (http 401).
The request failed because your clock has drifted by more than 15 minutes.
Syncing your clock to an NTP Time source should resolve the issue.
E
        else
          error_description.section("Authentication Error:",<<-E)
Failed to authenticate to the chef server (http 401).
E

          error_description.section("Server Response:", format_rest_error)
          error_description.section("Relevant Config Settings:",<<-E)
chef_server_url   "#{server_url}"
node_name         "#{username}"
client_key        "#{api_key}"

If these settings are correct, your client_key may be invalid.
E
        end
      end

      def describe_400_error(error_description)
        error_description.section("Invalid Request Data:",<<-E)
The data in your request was invalid (HTTP 400).
E
        error_description.section("Server Response:",format_rest_error)
      end

      def describe_500_error(error_description)
        error_description.section("Unknown Server Error:",<<-E)
The server had a fatal error attempting to load the node data.
E
        error_description.section("Server Response:", format_rest_error)
      end

      def describe_503_error(error_description)
        error_description.section("Server Unavailable","The Chef Server is temporarily unavailable")
        error_description.section("Server Response:", format_rest_error)
      end


      # Fallback for unexpected/uncommon http errors
      def describe_http_error(error_description)
        error_description.section("Unexpected API Request Failure:", format_rest_error)
      end

      # Parses JSON from the error response sent by Chef Server and returns the
      # error message
      def format_rest_error
        Array(Chef::JSONCompat.from_json(exception.response.body)["error"]).join('; ')
      rescue Exception
        exception.response.body
      end

      def username
        config[:node_name]
      end

      def api_key
        config[:client_key]
      end

      def server_url
        config[:chef_server_url]
      end

      def clock_skew?
        exception.response.body =~ /synchronize the clock/i
      end

    end
  end
end
