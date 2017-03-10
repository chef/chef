#--
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software, Inc.
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

require "pp"
require "chef/log"

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

      def initialize(opts = {})
      end

      def handle_request(method, url, headers = {}, data = false)
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        validate(http_response, http_response.body.bytesize) if http_response && http_response.body
        [http_response, rest_request, return_value]
      end

      def handle_stream_complete(http_response, rest_request, return_value)
        if @content_length_counter.nil?
          Chef::Log.debug("No content-length information collected for the streamed download, cannot identify streamed download.")
        else
          validate(http_response, @content_length_counter.content_length)
        end

        # Make sure the counter is reset since this object might get used
        # again. See CHEF-5100
        @content_length_counter = nil
        [http_response, rest_request, return_value]
      end

      def stream_response_handler(response)
        @content_length_counter = ContentLengthCounter.new
      end

      private

      def response_content_length(response)
        return nil if response["content-length"].nil?
        if response["content-length"].is_a?(Array)
          response["content-length"].first.to_i
        else
          response["content-length"].to_i
        end
      end

      def validate(http_response, response_length)
        content_length    = response_content_length(http_response)
        transfer_encoding = http_response["transfer-encoding"]

        if content_length.nil?
          Chef::Log.debug "HTTP server did not include a Content-Length header in response, cannot identify truncated downloads."
          return true
        end

        if content_length < 0
          Chef::Log.debug "HTTP server responded with a negative Content-Length header (#{content_length}), cannot identify truncated downloads."
          return true
        end

        # if Transfer-Encoding is set the RFC states that we must ignore the Content-Length field
        # CHEF-5041: some proxies uncompress gzip content, leave the incorrect content-length, but set the transfer-encoding field
        unless transfer_encoding.nil?
          Chef::Log.debug "Transfer-Encoding header is set, skipping Content-Length check."
          return true
        end

        if response_length != content_length
          raise Chef::Exceptions::ContentLengthMismatch.new(response_length, content_length)
        end

        Chef::Log.debug "Content-Length validated correctly."
        true
      end
    end
  end
end
