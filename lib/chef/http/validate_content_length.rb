#--
# Author:: Lamont Granquist (<lamont@getchef.com>)
# Copyright:: Copyright (c) 2013 Chef Software, Inc.
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

    # Middleware that validates the Content-Length header against the downloaded number of bytes.
    #
    # This must run before the decompressor middleware, since otherwise we will count the uncompressed
    # streamed bytes, rather than the on-the-wire compressed bytes.
    class ValidateContentLength

      class ContentLengthCounter
        attr_accessor :content_length

        def initialize
          @content_length = 0
        end

        def handle_chunk(chunk)
          @content_length += chunk.bytesize
          chunk
        end
      end

      def initialize(opts={})
      end

      def handle_request(method, url, headers={}, data=false)
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        unless http_response['content-length']
          Chef::Log.debug("HTTP server did not include a Content-Length header in response, cannot identify truncated downloads.")
          return [http_response, rest_request, return_value]
        end
        validate(response_content_length(http_response), http_response.body.bytesize)
        return [http_response, rest_request, return_value]
      end

      def handle_stream_complete(http_response, rest_request, return_value)
        if http_response['content-length'].nil?
          Chef::Log.debug("HTTP server did not include a Content-Length header in response, cannot idenfity streamed download.")
        elsif @content_length_counter.nil?
          Chef::Log.debug("No content-length information collected for the streamed download, cannot identify streamed download.")
        else
          validate(response_content_length(http_response), @content_length_counter.content_length)
        end
        return [http_response, rest_request, return_value]
      end

      def stream_response_handler(response)
        @content_length_counter = ContentLengthCounter.new
      end

      private
      def response_content_length(response)
        if response['content-length'].is_a?(Array)
          response['content-length'].first.to_i
        else
          response['content-length'].to_i
        end
      end

      def validate(content_length, response_length)
        Chef::Log.debug "Content-Length header = #{content_length}"
        Chef::Log.debug "Response body length = #{response_length}"
        if response_length != content_length
          raise Chef::Exceptions::ContentLengthMismatch.new(response_length, content_length)
        end
        true
      end
    end
  end
end
