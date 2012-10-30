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

      # == CookbookSyncErrorInspector
      # Generates human-friendly explanations for errors encountered during
      # cookbook sync.
      #--
      # TODO: Not sure what errors are commonly seen during cookbook sync, so
      # the messaging is kinda generic.
      class CookbookSyncErrorInspector

        include APIErrorFormatting

        attr_reader :exception
        attr_reader :cookbooks

        def initialize(cookbooks, exception)
          @cookbooks, @exception = cookbooks, exception
        end

        def add_explanation(error_description)
          case exception
          when *NETWORK_ERROR_CLASSES
            describe_network_errors(error_description)
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception(error_description)
          else
            error_description.section("Unexpected Error:","#{exception.class.name}: #{exception.message}")
          end
        end

        def config
          Chef::Config
        end

        def humanize_http_exception(error_description)
          response = exception.response
          case response
          when Net::HTTPUnauthorized
            # TODO: this is where you'd see conflicts b/c of username/clientname stuff
            describe_401_error(error_description)
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

      end
    end
  end
end


