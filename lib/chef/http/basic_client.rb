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

class Chef
  class HTTP
    class BasicClient

      HTTPS = "https".freeze

      attr_reader :url

      def initialize(url)
        @url = url
      end

      def host
        @url.host
      end

      def port
        @url.port
      end

      #adapted from buildr/lib/buildr/core/transports.rb
      def proxy_uri
        proxy = Chef::Config["#{url.scheme}_proxy"]
        proxy = URI.parse(proxy) if String === proxy
        excludes = Chef::Config[:no_proxy].to_s.split(/\s*,\s*/).compact
        excludes = excludes.map { |exclude| exclude =~ /:\d+$/ ? exclude : "#{exclude}:*" }
        return proxy unless excludes.any? { |exclude| File.fnmatch(exclude, "#{host}:#{port}") }
      end

      def http_client
        http_proxy = proxy_uri
        if http_proxy.nil?
          @http_client = Net::HTTP.new(host, port)
        else
          Chef::Log.debug("Using #{http_proxy.host}:#{http_proxy.port} for proxy")
          user = Chef::Config["#{url.scheme}_proxy_user"]
          pass = Chef::Config["#{url.scheme}_proxy_pass"]
          @http_client = Net::HTTP.Proxy(http_proxy.host, http_proxy.port, user, pass).new(host, port)
        end
        if url.scheme == HTTPS
          @http_client.use_ssl = true
          if config[:ssl_verify_mode] == :verify_none
            @http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
          elsif config[:ssl_verify_mode] == :verify_peer
            @http_client.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end
          if config[:ssl_ca_path]
            unless ::File.exist?(config[:ssl_ca_path])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_path #{config[:ssl_ca_path]} does not exist"
            end
            @http_client.ca_path = config[:ssl_ca_path]
          elsif config[:ssl_ca_file]
            unless ::File.exist?(config[:ssl_ca_file])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_file #{config[:ssl_ca_file]} does not exist"
            end
            @http_client.ca_file = config[:ssl_ca_file]
          end
          if (config[:ssl_client_cert] || config[:ssl_client_key])
            unless (config[:ssl_client_cert] && config[:ssl_client_key])
              raise Chef::Exceptions::ConfigurationError, "You must configure ssl_client_cert and ssl_client_key together"
            end
            unless ::File.exists?(config[:ssl_client_cert])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_client_cert #{config[:ssl_client_cert]} does not exist"
            end
            unless ::File.exists?(config[:ssl_client_key])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_client_key #{config[:ssl_client_key]} does not exist"
            end
            @http_client.cert = OpenSSL::X509::Certificate.new(::File.read(config[:ssl_client_cert]))
            @http_client.key = OpenSSL::PKey::RSA.new(::File.read(config[:ssl_client_key]))
          end
        end

        @http_client.read_timeout = config[:rest_timeout]
        @http_client
      end

      def config
        Chef::Config
      end


    end
  end
end
