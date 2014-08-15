#--
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'uri'
require 'chef/http/basic_client'

class Chef
  class HTTP
    class BasicClientCache

      attr_accessor :client_cache

      def initialize
        @client_cache = {}
      end

      def client_for(uri, opts = {})
        opts ||= {}
        uri = URI.parse(uri) if uri.is_a? String
        cache_key = uri.hostname + ';' + uri.port.to_s + ';' + opts[:ssl_policy].to_s
        client_cache[cache_key] ||= BasicClient.new(uri, opts)
      end
    end
  end
end
