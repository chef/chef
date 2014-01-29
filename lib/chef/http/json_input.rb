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

class Chef
  class HTTP

    # Middleware that takes json input and turns it into raw text
    class JSONInput

      def initialize(opts={})
      end

      def handle_request(method, url, headers={}, data=false)
        if data
          headers["Content-Type"] = 'application/json'
          data = Chef::JSONCompat.to_json(data)
          # Force encoding to binary to fix SSL related EOFErrors
          # cf. http://tickets.opscode.com/browse/CHEF-2363
          # http://redmine.ruby-lang.org/issues/5233
          data.force_encoding(Encoding::BINARY) if data.respond_to?(:force_encoding)
        end
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

      def stream_response_handler(response)
        nil
      end

      def handle_stream_complete(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

    end
  end
end
