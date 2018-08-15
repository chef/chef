# Author:: Tyler Ball (<tball@chef.io>)
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

require "proxifier"
require "chef-config/mixin/fuzzy_hostname_matcher"

class Chef
  module Mixin
    module ProxifiedSocket

      include ChefConfig::Mixin::FuzzyHostnameMatcher

      # This looks at the environment variables and leverages Proxifier to
      # make the TCPSocket respect ENV['https_proxy'] or ENV['http_proxy'] if
      # they are present
      def proxified_socket(host, port)
        proxy = ENV["https_proxy"] || ENV["http_proxy"] || false

        if proxy && !fuzzy_hostname_match_any?(host, ENV["no_proxy"])
          Proxifier.Proxy(proxy).open(host, port)
        else
          TCPSocket.new(host, port)
        end
      end

    end
  end
end
