#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class HttpRequest < Chef::Resource
      unified_mode true

      provides :http_request

      description "Use the **http_request** resource to send an HTTP request (`GET`, `PUT`, `POST`, `DELETE`, `HEAD`, or `OPTIONS`) with an arbitrary message. This resource is often useful when custom callbacks are necessary."

      default_action :get
      allowed_actions :get, :patch, :put, :post, :delete, :head, :options

      property :url, String, identity: true,
               description: "The URL to which an HTTP request is sent."

      property :headers, Hash, default: {},
               description: "A Hash of custom headers."

      def initialize(name, run_context = nil)
        super
        @message = name
      end

      def message(args = nil, &block)
        args = block if block_given?
        set_or_return(
          :message,
          args,
          kind_of: Object
        )
      end

    end
  end
end
