#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/json_compat"

class Chef
  class HTTP

    # Middleware that takes json input and turns it into raw text
    class JSONInput

      attr_accessor :opts

      def initialize(opts = {})
        @opts = opts
      end

      def handle_request(method, url, headers = {}, data = false)
        if data && should_encode_as_json?(headers)
          headers.delete_if { |key, _value| key.casecmp("content-type") == 0 }
          headers["Content-Type"] = "application/json"
          json_opts = {}
          json_opts[:validate_utf8] = opts[:validate_utf8] if opts.has_key?(:validate_utf8)
          data = Chef::JSONCompat.to_json(data, json_opts)
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

      private

      def should_encode_as_json?(headers)
        # ruby/Net::HTTP don't enforce capitalized headers (it normalizes them
        # for you before sending the request), so we have to account for all
        # the variations we might find
        requested_content_type = headers.find { |k, v| k.casecmp("content-type") == 0 }
        requested_content_type.nil? || requested_content_type.last.include?("json")
      end

    end
  end
end
