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

require 'chef/formatters/error_inspectors/api_error_formatting'

class Chef
  module Formatters
    module ErrorInspectors


      # == APIErrorInspector
      # Wraps exceptions caused by API calls to the server.
      class NodeLoadErrorInspector

        include APIErrorFormatting

        attr_reader :exception
        attr_reader :node_name
        attr_reader :config

        def initialize(node_name, exception, config)
          @node_name = node_name
          @exception = exception
          @config = config
        end

        def add_explanation(error_description)
          case exception
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception(error_description)
          when Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError
            error_description.section("Networking Error:",<<-E)
#{exception.message}

Your chef_server_url may be misconfigured, or the network could be down.
E
            error_description.section("Relevant Config Settings:",<<-E)
chef_server_url  "#{server_url}"
E
          when Chef::Exceptions::PrivateKeyMissing
            error_description.section("Private Key Not Found:",<<-E)
Your private key could not be loaded. If the key file exists, ensure that it is
readable by chef-client.
E
            error_description.section("Relevant Config Settings:",<<-E)
client_key        "#{api_key}"
E
          else
            error_description.section("Unexpected Error:","#{exception.class.name}: #{exception.message}")
          end
        end

        def humanize_http_exception(error_description)
          response = exception.response
          case response
          when Net::HTTPUnauthorized
            # TODO: this is where you'd see conflicts b/c of username/clientname stuff
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
          when Net::HTTPForbidden
            # TODO: we're rescuing errors from Node.find_or_create
            # * could be no write on nodes container
            # * could be no read on the node
            error_description.section("Authorization Error",<<-E)
Your client is not authorized to load the node data (HTTP 403).
E
            error_description.section("Server Response:", format_rest_error)

            error_description.section("Possible Causes:",<<-E)
* Your client (#{username}) may have misconfigured authorization permissions.
E
          when Net::HTTPBadRequest
            error_description.section("Invalid Request Data:",<<-E)
The data in your request was invalid (HTTP 400).
E
            error_description.section("Server Response:",format_rest_error)
          when Net::HTTPNotFound
            error_description.section("Resource Not Found:",<<-E)
The server returned a HTTP 404. This usually indicates that your chef_server_url is incorrect.
E
            error_description.section("Relevant Config Settings:",<<-E)
chef_server_url "#{server_url}"
E
          when Net::HTTPInternalServerError
            error_description.section("Unknown Server Error:",<<-E)
The server had a fatal error attempting to load the node data.
E
            error_description.section("Server Response:", format_rest_error)
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            error_description.section("Server Unavailable","The Chef Server is temporarily unavailable")
            error_description.section("Server Response:", format_rest_error)
          else
            error_description.section("Unexpected API Request Failure:", format_rest_error)
          end
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
end
