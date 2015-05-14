#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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

require 'chef/exceptions'

class Chef
  module Mixin
    module ServerApiVersion


      # Input: server_api_version should be a string of an integer
      def handle_request_api_version(server_api_version)
        # raise Chef::Exceptions::InvalidCommandOption if the server_api_version requested is not supported by the client
        server_api_version = config[:server_api_version].to_s
        supported_versions = Chef::REST::SUPPORTED_SERVER_API_VERSIONS
        unless supported_versions.include? config[:server_api_version].to_s
          raise Chef::Exceptions::InvalidCommandOption "You requested a server API version of #{server_api_version} via --server-api version. This version of the Chef client only supports supported_versions.join(', ')."
        end
      end
    end
  end
end
