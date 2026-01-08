#--
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
autoload :URI, "uri"
module Net
  autoload :HTTP, "net/http"
end
require_relative "ssl_policies"
require_relative "http_request"

class Chef
  class HTTP
    class BasicClient

      HTTPS = "https".freeze

      attr_reader :url
      attr_reader :ssl_policy
      attr_reader :keepalives
      attr_reader :nethttp_opts

      # Instantiate a BasicClient.
      # === Arguments:
      # url:: An URI for the remote server.
      # === Options:
      # ssl_policy:: The SSL Policy to use, defaults to DefaultSSLPolicy
      def initialize(url, ssl_policy: DefaultSSLPolicy, keepalives: false, nethttp_opts: {})
        @url = url
        @ssl_policy = ssl_policy
        @keepalives = keepalives
        @nethttp_opts = ChefUtils::Mash.new(nethttp_opts)
      end

      def http_client
        @http_client ||= build_http_client
      end

      def host
        @url.hostname
      end

      def port
        @url.port
      end

      def request(method, url, req_body, base_headers = {})
        http_request = HTTPRequest.new(method, url, req_body, base_headers).http_request
        Chef::Log.trace("Initiating #{method} to #{url}")
        Chef::Log.trace("---- HTTP Request Header Data: ----")
        base_headers.each do |name, value|
          Chef::Log.trace("#{name}: #{value}")
        end
        Chef::Log.trace("---- End HTTP Request Header Data ----")
        http_client.request(http_request) do |response|
          Chef::Log.trace("---- HTTP Status and Header Data: ----")
          Chef::Log.trace("HTTP #{response.http_version} #{response.code} #{response.msg}")

          response.each do |header, value|
            Chef::Log.trace("#{header}: #{value}")
          end
          Chef::Log.trace("---- End HTTP Status/Header Data ----")

          # For non-400's, log the request and response bodies
          if !response.code || !response.code.start_with?("2")
            if response.body
              Chef::Log.trace("---- HTTP Response Body ----")
              Chef::Log.trace(response.body)
              Chef::Log.trace("---- End HTTP Response Body -----")
            end
            if req_body
              Chef::Log.trace("---- HTTP Request Body ----")
              Chef::Log.trace(req_body)
              Chef::Log.trace("---- End HTTP Request Body ----")
            end
          end

          yield response if block_given?
          # http_client.request may not have the return signature we want, so
          # force the issue:
          return [http_request, response]
        end
      rescue OpenSSL::SSL::SSLError => e
        Chef::Log.error("SSL Validation failure connecting to host: #{host} - #{e.message}")
        raise
      end

      def proxy_uri
        @proxy_uri ||= Chef::Config.proxy_uri(url.scheme, host, port)
      end

      def build_http_client
        # Note: the last nil in the new below forces Net::HTTP to ignore the
        # no_proxy environment variable. This is a workaround for limitations
        # in Net::HTTP use of the no_proxy environment variable. We internally
        # match no_proxy with a fuzzy matcher, rather than letting Net::HTTP
        # do it.
        http_client = http_client_builder.new(host, port, nil)
        http_client.proxy_port = nil if http_client.proxy_address.nil?

        if url.scheme == HTTPS
          configure_ssl(http_client)
        end

        opts = nethttp_opts.dup
        opts["read_timeout"] ||= config[:rest_timeout]
        opts["open_timeout"] ||= config[:rest_timeout]

        opts.each do |key, value|
          http_client.send(:"#{key}=", value)
        end

        if keepalives
          http_client.start
        else
          http_client
        end
      end

      def config
        Chef::Config
      end

      def http_client_builder
        if proxy_uri.nil?
          Net::HTTP
        else
          Chef::Log.trace("Using #{proxy_uri.host}:#{proxy_uri.port} for proxy")
          Net::HTTP.Proxy(proxy_uri.host, proxy_uri.port, http_proxy_user(proxy_uri),
            http_proxy_pass(proxy_uri))
        end
      end

      def http_proxy_user(proxy_uri)
        proxy_uri.user || config["#{proxy_uri.scheme}_proxy_user"]
      end

      def http_proxy_pass(proxy_uri)
        proxy_uri.password || config["#{proxy_uri.scheme}_proxy_pass"]
      end

      def configure_ssl(http_client)
        http_client.use_ssl = true
        ssl_policy.apply_to(http_client)
      end

    end
  end
end
