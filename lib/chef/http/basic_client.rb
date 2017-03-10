#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Author:: Nuo Yan (<nuo@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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
require "uri"
require "net/http"
require "chef/http/ssl_policies"
require "chef/http/http_request"

class Chef
  class HTTP
    class BasicClient

      HTTPS = "https".freeze

      attr_reader :url
      attr_reader :http_client
      attr_reader :ssl_policy
      attr_reader :keepalives

      # Instantiate a BasicClient.
      # === Arguments:
      # url:: An URI for the remote server.
      # === Options:
      # ssl_policy:: The SSL Policy to use, defaults to DefaultSSLPolicy
      def initialize(url, opts = {})
        @url = url
        @ssl_policy = opts[:ssl_policy] || DefaultSSLPolicy
        @keepalives = opts[:keepalives] || false
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
        Chef::Log.debug("Initiating #{method} to #{url}")
        Chef::Log.debug("---- HTTP Request Header Data: ----")
        base_headers.each do |name, value|
          Chef::Log.debug("#{name}: #{value}")
        end
        Chef::Log.debug("---- End HTTP Request Header Data ----")
        http_client.request(http_request) do |response|
          Chef::Log.debug("---- HTTP Status and Header Data: ----")
          Chef::Log.debug("HTTP #{response.http_version} #{response.code} #{response.msg}")

          response.each do |header, value|
            Chef::Log.debug("#{header}: #{value}")
          end
          Chef::Log.debug("---- End HTTP Status/Header Data ----")

          # For non-400's, log the request and response bodies
          if !response.code || !response.code.start_with?("2")
            if response.body
              Chef::Log.debug("---- HTTP Response Body ----")
              Chef::Log.debug(response.body)
              Chef::Log.debug("---- End HTTP Response Body -----")
            end
            if req_body
              Chef::Log.debug("---- HTTP Request Body ----")
              Chef::Log.debug(req_body)
              Chef::Log.debug("---- End HTTP Request Body ----")
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

        http_client.read_timeout = config[:rest_timeout]
        http_client.open_timeout = config[:rest_timeout]
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
          Chef::Log.debug("Using #{proxy_uri.host}:#{proxy_uri.port} for proxy")
          Net::HTTP.Proxy(proxy_uri.host, proxy_uri.port, http_proxy_user(proxy_uri),
                          http_proxy_pass(proxy_uri))
        end
      end

      def http_proxy_user(proxy_uri)
        proxy_uri.user || Chef::Config["#{proxy_uri.scheme}_proxy_user"]
      end

      def http_proxy_pass(proxy_uri)
        proxy_uri.password || Chef::Config["#{proxy_uri.scheme}_proxy_pass"]
      end

      def configure_ssl(http_client)
        http_client.use_ssl = true
        ssl_policy.apply_to(http_client)
      end

    end
  end
end
