#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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
      class RunListExpansionErrorInspector

        include APIErrorFormatting

        attr_reader :exception
        attr_reader :node

        def initialize(node, exception)
          @node, @exception = node, exception
        end

        def add_explanation(error_description)
          case exception
          when Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError
            error_description.section("Networking Error:",<<-E)
#{exception.message}

Your chef_server_url may be misconfigured, or the network could be down.
E
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception(error_description)
          when Chef::Exceptions::MissingRole
            describe_missing_role(error_description)
          else
            error_description.section("Unexpected Error:","#{exception.class.name}: #{exception.message}")
          end
        end

        def describe_missing_role(error_description)
          error_description.section("Missing Role(s) in Run List:", missing_roles_explained)
          original_run_list = node.run_list.map {|item| "* #{item}"}.join("\n")
          error_description.section("Original Run List", original_run_list)
        end

        def missing_roles_explained
          run_list_expansion.missing_roles_with_including_role.map do |role, includer|
            "* #{role} included by '#{includer}'"
          end.join("\n")
        end

        def run_list_expansion
          exception.expansion
        end

        def config
          Chef::Config
        end

        def humanize_http_exception(error_description)
          response = exception.response
          case response
          when Net::HTTPUnauthorized
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
          when Net::HTTPForbidden
            # TODO: we're rescuing errors from Node.find_or_create
            # * could be no write on nodes container
            # * could be no read on the node
            error_description.section("Authorization Error",<<-E)
Your client is not authorized to load one or more of your roles (HTTP 403).
E
            error_description.section("Server Response:", format_rest_error)

            error_description.section("Possible Causes:",<<-E)
* Your client (#{username}) may have misconfigured authorization permissions.
E
          when Net::HTTPInternalServerError
            error_description.section("Unknown Server Error:",<<-E)
The server had a fatal error attempting to load a role.
E
            error_description.section("Server Response:", format_rest_error)
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            error_description.section("Server Unavailable","The Chef Server is temporarily unavailable")
            error_description.section("Server Response:", format_rest_error)
          else
            error_description.section("Unexpected API Request Failure:", format_rest_error)
          end
        end

      end
    end
  end
end

