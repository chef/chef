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
          when *NETWORK_ERROR_CLASSES
            describe_network_errors(error_description)
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
            describe_401_error(error_description)
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
            describe_400_error(error_description)
          when Net::HTTPNotFound
            describe_404_error(error_description)
          when Net::HTTPInternalServerError
            describe_500_error(error_description)
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            describe_503_error(error_description)
          else
            describe_http_error(error_description)
          end
        end

        # Custom 404 error messaging. Users sometimes see 404s when they have
        # misconfigured server URLs, and the wrong one redirects to the new
        # one, e.g., PUT http://wrong.url/nodes/node-name becomes a GET after a
        # redirect.
        def describe_404_error(error_description)
          error_description.section("Resource Not Found:",<<-E)
The server returned a HTTP 404. This usually indicates that your chef_server_url is incorrect.
E
          error_description.section("Relevant Config Settings:",<<-E)
chef_server_url "#{server_url}"
E
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
