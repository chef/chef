#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
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
require 'net/http'
require 'chef/http/ssl_policies'
require 'chef/http/http_request'

class Chef
  class HTTP
    class BasicClient

      HTTPS = "https".freeze

      attr_reader :url
      attr_reader :http_client
      attr_reader :ssl_policy

      # Instantiate a BasicClient.
      # === Arguments:
      # url:: An URI for the remote server.
      # === Options:
      # ssl_policy:: The SSL Policy to use, defaults to DefaultSSLPolicy
      def initialize(url, opts={})
        @url = url
        @ssl_policy = opts[:ssl_policy] || DefaultSSLPolicy
        @http_client = build_http_client
      end

      def host
        @url.hostname
      end

      def port
        @url.port
      end

      def request(method, url, req_body, base_headers={})
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

          yield response if block_given?
          # http_client.request may not have the return signature we want, so
          # force the issue:
          return [http_request, response]
        end
      rescue OpenSSL::SSL::SSLError => e
        Chef::Log.error("SSL Validation failure connecting to host: #{host} - #{e.message}")
        raise
      end

      #adapted from buildr/lib/buildr/core/transports.rb
      def proxy_uri
        proxy = Chef::Config["#{url.scheme}_proxy"]
        proxy = URI.parse(proxy) if String === proxy
        excludes = Chef::Config[:no_proxy].to_s.split(/\s*,\s*/).compact
        excludes = excludes.map { |exclude| exclude =~ /:\d+$/ ? exclude : "#{exclude}:*" }
        return proxy unless excludes.any? { |exclude| File.fnmatch(exclude, "#{host}:#{port}") }
      end

      def build_http_client
        http_client = http_client_builder.new(host, port)

        if url.scheme == HTTPS
          configure_ssl(http_client)
        end

        http_client.read_timeout = config[:rest_timeout]
        http_client.open_timeout = config[:rest_timeout]
        http_client
      end

      def config
        Chef::Config
      end

      def http_client_builder
        http_proxy = proxy_uri
        if http_proxy.nil?
          Net::HTTP
        else
          Chef::Log.debug("Using #{http_proxy.host}:#{http_proxy.port} for proxy")
          user = Chef::Config["#{url.scheme}_proxy_user"]
          pass = Chef::Config["#{url.scheme}_proxy_pass"]
          Net::HTTP.Proxy(http_proxy.host, http_proxy.port, user, pass)
        end
      end

      def configure_ssl(http_client)
        http_client.use_ssl = true
        ssl_policy.apply_to(http_client)
      end

    end
  end
end
