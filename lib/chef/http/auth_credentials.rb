#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Author:: Nuo Yan (<nuo@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require_relative "../log"
module Mixlib
  module Authentication
    autoload :SignedHeaderAuth, "mixlib/authentication/signedheaderauth"
  end
end

class Chef
  class HTTP
    class AuthCredentials
      attr_reader :client_name, :key

      def initialize(client_name = nil, key = nil, use_ssh_agent: false)
        @client_name = client_name
        @key = key
        @use_ssh_agent = use_ssh_agent
      end

      def sign_requests?
        !!key
      end

      def signature_headers(request_params = {})
        raise ArgumentError, "Cannot sign the request without a client name, check that :node_name is assigned" if client_name.nil?

        Chef::Log.trace("Signing the request as #{client_name}")

        # params_in = {:http_method => :GET, :path => "/clients", :body => "", :host => "localhost"}
        request_params                 = request_params.dup
        request_params[:timestamp]     = Time.now.utc.iso8601
        request_params[:user_id]       = client_name
        request_params[:proto_version] = Chef::Config[:authentication_protocol_version]
        host = request_params.delete(:host) || "localhost"

        sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(request_params)
        signed = sign_obj.sign(key, use_ssh_agent: @use_ssh_agent).merge({ host: host })
        signed.inject({}) { |memo, kv| memo[(kv[0].to_s.upcase).to_s] = kv[1]; memo }
      end

    end
  end
end
