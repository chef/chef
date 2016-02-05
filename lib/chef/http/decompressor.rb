#--
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require "zlib"
require "chef/http/http_request"

class Chef
  class HTTP

    # Middleware-esque class for handling compression in HTTP responses.
    class Decompressor
      class NoopInflater
        def inflate(chunk)
          chunk
        end
        alias :handle_chunk :inflate
      end

      class GzipInflater < Zlib::Inflate
        def initialize
          super(Zlib::MAX_WBITS + 16)
        end
        alias :handle_chunk :inflate
      end

      class DeflateInflater < Zlib::Inflate
        def initialize
          super
        end
        alias :handle_chunk :inflate
      end

      CONTENT_ENCODING  = "content-encoding".freeze
      GZIP              = "gzip".freeze
      DEFLATE           = "deflate".freeze
      IDENTITY          = "identity".freeze

      def initialize(opts = {})
        @disable_gzip = false
        handle_options(opts)
      end

      def handle_request(method, url, headers = {}, data = false)
        headers[HTTPRequest::ACCEPT_ENCODING] = HTTPRequest::ENCODING_GZIP_DEFLATE unless gzip_disabled?
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        # temporary hack, skip processing if return_value is false
        # needed to keep conditional get stuff working correctly.
        return [http_response, rest_request, return_value] if return_value == false
        response_body = decompress_body(http_response)
        http_response.body.replace(response_body) if http_response.body.respond_to?(:replace)
        [http_response, rest_request, return_value]
      end

      def handle_stream_complete(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

      def decompress_body(response)
        if gzip_disabled? || response.body.nil?
          response.body
        else
          case response[CONTENT_ENCODING]
          when GZIP
            Chef::Log.debug "Decompressing gzip response"
            Zlib::Inflate.new(Zlib::MAX_WBITS + 16).inflate(response.body)
          when DEFLATE
            Chef::Log.debug "Decompressing deflate response"
            Zlib::Inflate.inflate(response.body)
          else
            response.body
          end
        end
      end

      # This isn't used when this class is used as middleware; it returns an
      # object you can use to unzip/inflate a streaming response.
      def stream_response_handler(response)
        if gzip_disabled?
          Chef::Log.debug "disable_gzip is set. \
            Not using #{response[CONTENT_ENCODING]} \
            and initializing noop stream deflator."
          NoopInflater.new
        else
          case response[CONTENT_ENCODING]
          when GZIP
            Chef::Log.debug "Initializing gzip stream deflator"
            GzipInflater.new
          when DEFLATE
            Chef::Log.debug "Initializing deflate stream deflator"
            DeflateInflater.new
          else
            Chef::Log.debug "content_encoding = '#{response[CONTENT_ENCODING]}' \
              initializing noop stream deflator."
            NoopInflater.new
          end
        end
      end

      # gzip is disabled using the disable_gzip => true option in the
      # constructor. When gzip is disabled, no 'Accept-Encoding' header will be
      # set, and the response will not be decompressed, no matter what the
      # Content-Encoding header of the response is. The intended use case for
      # this is to work around situations where you request +file.tar.gz+, but
      # the server responds with a content type of tar and a content encoding of
      # gzip, tricking the client into decompressing the response so you end up
      # with a tar archive (no gzip) named file.tar.gz
      def gzip_disabled?
        @disable_gzip
      end

      private

      def handle_options(opts)
        opts.each do |name, value|
          case name.to_s
          when "disable_gzip"
            @disable_gzip = value
          end
        end
      end

    end
  end
end
