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

require "chef/http/cookie_jar"

class Chef
  class HTTP

    # An HTTP middleware to manage storing/sending cookies in HTTP requests.
    # Most HTTP communication in Chef does not need cookies, it was originally
    # implemented to support OpenID, but it's not known who might be relying on
    # it, so it's included with Chef::REST
    class CookieManager

      def initialize(options = {})
        @cookies = CookieJar.instance
      end

      def handle_request(method, url, headers = {}, data = false)
        @host, @port = url.host, url.port
        if @cookies.has_key?("#{@host}:#{@port}")
          headers["Cookie"] = @cookies["#{@host}:#{@port}"]
        end
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        if http_response["set-cookie"]
          @cookies["#{@host}:#{@port}"] = http_response["set-cookie"]
        end
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
