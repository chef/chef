#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource"
require "chef/provider/http_request"

class Chef
  class Resource
    class HttpRequest < Chef::Resource

      identity_attr :url

      default_action :get
      allowed_actions :get, :put, :post, :delete, :head, :options

      def initialize(name, run_context = nil)
        super
        @message = name
        @url = nil
        @headers = {}
      end

      def url(args = nil)
        set_or_return(
          :url,
          args,
          :kind_of => String
        )
      end

      def message(args = nil, &block)
        args = block if block_given?
        set_or_return(
          :message,
          args,
          :kind_of => Object
        )
      end

      def headers(args = nil)
        set_or_return(
          :headers,
          args,
          :kind_of => Hash
        )
      end

    end
  end
end
