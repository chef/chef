#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/json_compat'
require 'chef/log'

class Chef
  class HTTP

    # Middleware that takes an HTTP response, parses it as JSON if possible.
    class JSONOutput

      def initialize(opts={})
        @raw_output = opts[:raw_output]
        @inflate_json_class = opts[:inflate_json_class]
      end

      def handle_request(method, url, headers={}, data=false)
        # Ideally this should always set Accept to application/json, but
        # Chef::REST is sometimes used to make non-JSON requests, so it sets
        # Accept to the desired value before middlewares get called.
        headers['Accept'] ||= 'application/json'
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        # temporary hack, skip processing if return_value is false
        # needed to keep conditional get stuff working correctly.
        return [http_response, rest_request, return_value] if return_value == false
        if http_response['content-type'] =~ /json/
          if @raw_output
            return_value = http_response.body.to_s
          else
            if @inflate_json_class
              return_value = Chef::JSONCompat.from_json(http_response.body.chomp)
            else
              return_value = Chef::JSONCompat.from_json(http_response.body.chomp, :create_additions => false)
            end
          end
          [http_response, rest_request, return_value]
        else
          Chef::Log.warn("Expected JSON response, but got content-type '#{http_response['content-type']}'")
          return [http_response, rest_request, http_response.body.to_s]
        end
      end

      def stream_response_handler(response)
        nil
      end

    end
  end
end
