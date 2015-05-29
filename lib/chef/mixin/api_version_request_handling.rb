#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright 2015 Chef Software, Inc.
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

class Chef
  module ApiVersionRequestHandling
    # takes in an http exception, and a min and max supported API version and
    # handles all the versioning cases
    #
    # it will return false if there was a non-versioning related error
    # or the server and the client are not compatible
    #
    # if the server does not support versioning, then it will return true, and you
    # can assume API v0 is safe to send
    def handle_version_http_exception(exception, min_client_supported_version, max_client_supported_version)
      # only rescue 406 Unacceptable with proper header
      return false if exception.response.code != "406" || exception.response["x-ops-server-api-version"].nil?

      # if the version header doesn't exist, just assume API v0
      if exception.response["x-ops-server-api-version"]
        header = Chef::JSONCompat.from_json(exception.response["x-ops-server-api-version"])
        min_server_version = Integer(header["min_version"])
        max_server_version = Integer(header["max_version"])

        # if the min API version the server supports is greater than the min version the client supports
        # and the max API version the server supports is less than the max version the client supports
        if min_server_version > min_client_supported_version || max_server_version < max_client_supported_version
          # if it had x-ops-server-api-version header, return false
          return false
        end
      end
      true
    end

  end
end
