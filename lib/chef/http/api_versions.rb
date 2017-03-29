#--
# Copyright:: Copyright 2017, Chef Software Inc.
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

require "chef/server_api_versions"
require "chef/json_compat"

class Chef
  class HTTP
    # An HTTP middleware to retrieve and store the Chef Server's minimum
    # and maximum supported API versions.
    class APIVersions

      def initialize(options = {})
      end

      def handle_request(method, url, headers = {}, data = false)
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        if http_response.code == "406"
          ServerAPIVersions.instance.reset!
        end
        if http_response.key?("x-ops-server-api-version")
          ServerAPIVersions.instance.set_versions(JSONCompat.parse(http_response["x-ops-server-api-version"]))
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
