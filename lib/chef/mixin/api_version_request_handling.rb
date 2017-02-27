#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
  module Mixin
    module ApiVersionRequestHandling
      # Input:
      # exeception:
      #   Net::HTTPServerException that may or may not contain the x-ops-server-api-version header
      # supported_client_versions:
      #  An array of Integers that represent the API versions the client supports.
      #
      # Output:
      # nil:
      #  If the execption was not a 406 or the server does not support versioning
      # Array of length zero:
      #  If there was no intersection between supported client versions and supported server versions
      # Arrary of Integers:
      #  If there was an intersection of supported versions, the array returns will contain that intersection
      def server_client_api_version_intersection(exception, supported_client_versions)
        # return empty array unless 406 Unacceptable with proper header
        return nil if exception.response.code != "406" || exception.response["x-ops-server-api-version"].nil?

        # intersection of versions the server and client support, will be of length zero if no intersection
        server_supported_client_versions = Array.new

        header = Chef::JSONCompat.from_json(exception.response["x-ops-server-api-version"])
        min_server_version = Integer(header["min_version"])
        max_server_version = Integer(header["max_version"])

        supported_client_versions.each do |version|
          if version >= min_server_version && version <= max_server_version
            server_supported_client_versions.push(version)
          end
        end
        server_supported_client_versions
      end

      def reregister_only_v0_supported_error_msg(max_version, min_version)
        <<-EOH
The reregister command only supports server API version 0.
The server that received the request supports a min version of #{min_version} and a max version of #{max_version}.
User keys are now managed via the key rotation commmands.
Please refer to the documentation on how to manage your keys via the key rotation commands:
https://docs.chef.io/server_security.html#key-rotation
EOH
      end

    end
  end
end
