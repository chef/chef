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
      class CookbookResolveErrorInspector

        attr_reader :exception
        attr_reader :expanded_run_list

        include APIErrorFormatting

        def initialize(expanded_run_list, exception)
          @expanded_run_list = expanded_run_list
          @exception = exception
        end

        def add_explanation(error_description)
          case exception
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception(error_description)
          when *NETWORK_ERROR_CLASSES
            describe_network_errors(error_description)
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
This client is not authorized to read some of the information required to
access its coobooks (HTTP 403).

To access its cookbooks, a client needs to be able to read its environment and
all of the cookbooks in its expanded run list.
E
            error_description.section("Expanded Run List:", expanded_run_list_ul)
            error_description.section("Server Response:", format_rest_error)
          when Net::HTTPPreconditionFailed
            describe_412_error(error_description)
          when Net::HTTPBadRequest
            describe_400_error(error_description)
          when Net::HTTPNotFound
          when Net::HTTPInternalServerError
            describe_500_error(error_description)
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            describe_503_error(error_description)
          else
            describe_http_error(error_description)
          end
        end

        def describe_412_error(error_description)
          explanation = ""
          error_reasons = extract_412_error_message
          if !error_reasons.respond_to?(:key?)
            explanation << error_reasons.to_s
          else
            if error_reasons.key?("non_existent_cookbooks") && !Array(error_reasons["non_existent_cookbooks"]).empty?
              explanation << "The following cookbooks are required by the client but don't exist on the server:\n"
              Array(error_reasons["non_existent_cookbooks"]).each do |cookbook|
                explanation << "* #{cookbook}\n"
              end
              explanation << "\n"
            end
            if error_reasons.key?("cookbooks_with_no_versions") && !Array(error_reasons["cookbooks_with_no_versions"]).empty?
              explanation << "The following cookbooks exist on the server, but there is no version that meets\nthe version constraints in this environment:\n"
              Array(error_reasons["cookbooks_with_no_versions"]).each do |cookbook|
                explanation << "* #{cookbook}\n"
              end
              explanation << "\n"
            end
          end

          error_description.section("Missing Cookbooks:", explanation)
          error_description.section("Expanded Run List:", expanded_run_list_ul)
        end

        def expanded_run_list_ul
          @expanded_run_list.map {|i| "* #{i}"}.join("\n")
        end

        # In my tests, the error from the server is double JSON encoded, but we
        # should not rely on this not getting fixed.
        #
        # Return *should* be a Hash like this:
        #   { "non_existent_cookbooks"     => ["nope"],
        #     "cookbooks_with_no_versions" => [],
        #     "message" => "Run list contains invalid items: no such cookbook nope."}
        def extract_412_error_message
          # Example:
          # "{\"error\":[\"{\\\"non_existent_cookbooks\\\":[\\\"nope\\\"],\\\"cookbooks_with_no_versions\\\":[],\\\"message\\\":\\\"Run list contains invalid items: no such cookbook nope.\\\"}\"]}"

          wrapped_error_message = attempt_json_parse(exception.response.body)
          unless wrapped_error_message.kind_of?(Hash) && wrapped_error_message.key?("error")
            return wrapped_error_message.to_s
          end

          error_description = Array(wrapped_error_message["error"]).first
          if error_description.kind_of?(Hash)
            return error_description
          end
          attempt_json_parse(error_description)
        end

        private

        def attempt_json_parse(maybe_json_string)
          Chef::JSONCompat.from_json(maybe_json_string)
        rescue Exception
          maybe_json_string
        end


      end
    end
  end
end

