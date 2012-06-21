#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
  module Formatters

    module APIErrorFormatting

      # Parses JSON from the error response sent by Chef Server and returns the
      # error message
      def format_rest_error
        Array(Chef::JSONCompat.from_json(exception.response.body)["error"]).join('; ')
      rescue Exception
        exception.response.body
      end

      def username
        config[:node_name]
      end

      def api_key
        config[:client_key]
      end

      def server_url
        config[:chef_server_url]
      end

      def clock_skew?
        exception.response.body =~ /synchronize the clock/i
      end

    end
  end
end
