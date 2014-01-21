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

require 'pp'
require 'chef/log'

class Chef
  class HTTP

    # Middleware that takes an HTTP response, parses it as JSON if possible.
    class ValidateResponse

      class ContentLengthCounter
        attr_accessor :content_length

        def initialize
          @content_length = 0
        end

        def handle_chunk(chunk)
          @content_length += chunk.bytesize
        end
      end

      def initialize(opts={})
      end

      def handle_request(method, url, headers={}, data=false)
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        unless http_response['content-length']
          Chef::Log.warn "HTTP server did not include a Content-Length header in response, cannot identify truncated downloads."
          return [http_response, rest_request, return_value]
        end
        content_length = http_response['content-length'].is_a?(Array) ? http_response['content-length'].first.to_i : http_response['content-length'].to_i
        Chef::Log.debug "Content-Length header = #{content_length}"
        response_length = http_response.body.bytesize
        Chef::Log.debug "Response body length = #{response_length}"
        if response_length != content_length
          raise "Response body length #{response_length} does not match HTTP Content-Length header #{content_length}"  #FIXME: real exception
        end
        return [http_response, rest_request, return_value]
      end

      def stream_response_handler(response)
        @content_length_counter = ContentLengthCounter.new
      end

    end
  end
end
