#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
# ---
# Some portions of the code in this file are verbatim copies of code from the
# fakeweb project: https://github.com/chrisk/fakeweb
#
# fakeweb is distributed under the MIT license, which is copied below:
# ---
#
# Copyright 2006-2010 Blaine Cook, Chris Kampmeier, and other contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'chef_zero/server'

class Chef
  class HTTP

    # HTTP Client class that talks directly to Zero via the Rack interface.
    class SocketlessChefZeroClient

      # This module is extended into Net::HTTP Response objects created from
      # Socketless Chef Zero responses.
      module ResponseExts

        # Net::HTTP raises an error if #read_body is called with a block or
        # file argument after the body has already been read from the network.
        #
        # Since we always set the body to the string response from Chef Zero
        # and set the `@read` indicator variable, we have to patch this method
        # or else streaming-style responses won't work.
        def read_body(dest = nil, &block)
          if dest
            raise "responses from socketless chef zero can't be written to specific destination"
          end

          if block_given?
            block.call(@body)
          else
            super
          end
        end

      end

      attr_reader :url

      # copied verbatim from webrick (2-clause BSD License)
      #
      # HTTP status codes and descriptions
      STATUS_MESSAGE = {
        100 => 'Continue',
        101 => 'Switching Protocols',
        200 => 'OK',
        201 => 'Created',
        202 => 'Accepted',
        203 => 'Non-Authoritative Information',
        204 => 'No Content',
        205 => 'Reset Content',
        206 => 'Partial Content',
        207 => 'Multi-Status',
        300 => 'Multiple Choices',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        305 => 'Use Proxy',
        307 => 'Temporary Redirect',
        400 => 'Bad Request',
        401 => 'Unauthorized',
        402 => 'Payment Required',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        407 => 'Proxy Authentication Required',
        408 => 'Request Timeout',
        409 => 'Conflict',
        410 => 'Gone',
        411 => 'Length Required',
        412 => 'Precondition Failed',
        413 => 'Request Entity Too Large',
        414 => 'Request-URI Too Large',
        415 => 'Unsupported Media Type',
        416 => 'Request Range Not Satisfiable',
        417 => 'Expectation Failed',
        422 => 'Unprocessable Entity',
        423 => 'Locked',
        424 => 'Failed Dependency',
        426 => 'Upgrade Required',
        428 => 'Precondition Required',
        429 => 'Too Many Requests',
        431 => 'Request Header Fields Too Large',
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable',
        504 => 'Gateway Timeout',
        505 => 'HTTP Version Not Supported',
        507 => 'Insufficient Storage',
        511 => 'Network Authentication Required',
      }

      STATUS_MESSAGE.values.each {|v| v.freeze }
      STATUS_MESSAGE.freeze

      def initialize(base_url)
        @url = base_url
      end

      def host
        @url.hostname
      end

      def port
        @url.port
      end

      def request(method, url, body, headers, &handler_block)
        request = req_to_rack(method, url, body, headers)
        res = ChefZero::SocketlessServerMap.request(port, request)

        net_http_response = to_net_http(res[0], res[1], res[2])

        yield net_http_response if block_given?

        [self, net_http_response]
      end

      def req_to_rack(method, url, body, headers)
        body_str = body || ""
        {
          "SCRIPT_NAME"     => "",
          "SERVER_NAME"     => "localhost",
          "REQUEST_METHOD"  => method.to_s.upcase,
          "PATH_INFO"       => url.path,
          "QUERY_STRING"    => url.query,
          "SERVER_PORT"     => url.port,
          "HTTP_HOST"       => "localhost:#{url.port}",
          "rack.url_scheme" => "chefzero",
          "rack.input"      => StringIO.new(body_str),
        }
      end

      def to_net_http(code, headers, chunked_body)
        body = chunked_body.join('')
        msg = STATUS_MESSAGE[code] or raise "Cannot determine HTTP status message for code #{code}"
        response = Net::HTTPResponse.send(:response_class, code.to_s).new("1.0", code.to_s, msg)
        response.instance_variable_set(:@body, body)
        headers.each do |name, value|
          if value.respond_to?(:each)
            value.each { |v| response.add_field(name, v) }
          else
            response[name] = value
          end
        end

        response.instance_variable_set(:@read, true)
        response.extend(ResponseExts)
        response
      end

      private

      def headers_extracted_from_options
        options.reject {|name, _| KNOWN_OPTIONS.include?(name) }.map { |name, value|
          [name.to_s.split("_").map { |segment| segment.capitalize }.join("-"), value]
        }
      end


    end

  end
end
