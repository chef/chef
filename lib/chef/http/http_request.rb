# frozen_string_literal: true
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
autoload :CGI, "cgi"
module Net
  autoload :HTTP, "net/http"
end
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

# To load faster, we only want ohai's version string.
# However, in ohai before 0.6.0, the version is defined
# in ohai, not ohai/version
begin
  require "ohai/version" # used in user agent string.
rescue LoadError
  require "ohai" unless defined?(Ohai::System)
end

require_relative "../version"

class Chef
  class HTTP
    class HTTPRequest

      engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"

      UA_COMMON = "/#{::Chef::VERSION} (#{engine}-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}; ohai-#{Ohai::VERSION}; #{RUBY_PLATFORM}; +#{ChefUtils::Dist::Org::WEBSITE})".freeze
      DEFAULT_UA = "Chef Client" + UA_COMMON

      USER_AGENT = "User-Agent"

      ACCEPT_ENCODING = "Accept-Encoding"
      ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3"

      GET     = "get"
      PATCH   = "patch"
      PUT     = "put"
      POST    = "post"
      DELETE  = "delete"
      HEAD    = "head"

      HTTPS = "https"

      SLASH = "/"

      HOST_LOWER = "host"

      URI_SCHEME_DEFAULT_PORT = { "http" => 80, "https" => 443 }.freeze

      def self.user_agent=(ua)
        @user_agent = ua
      end

      def self.user_agent
        @user_agent ||= DEFAULT_UA
      end

      attr_reader :method, :url, :headers, :http_request

      def initialize(method, url, req_body, base_headers = {})
        @method, @url = method, url
        @request_body = nil
        build_headers(base_headers)
        configure_http_request(req_body)
      end

      def host
        @url.hostname
      end

      def uri_safe_host
        @url.host
      end

      def port
        @url.port
      end

      def query
        @url.query
      end

      def path
        @url.path.empty? ? SLASH : @url.path
      end

      # @deprecated Call request on an HTTP client object instead.
      def call
        hide_net_http_bug do
          http_client.request(http_request) do |response|
            yield response if block_given?
            response
          end
        end
      end

      def config
        Chef::Config
      end

      # @deprecated Call request on an HTTP client object instead.
      def http_client
        @http_client ||= BasicClient.new(url).http_client
      end

      private

      def hide_net_http_bug
        yield
      rescue NoMethodError => e
        # http://redmine.ruby-lang.org/issues/show/2708
        # http://redmine.ruby-lang.org/issues/show/2758
        if /#{Regexp.escape(%q{undefined method `closed?' for nil:NilClass})}/.match?(e.to_s)
          Chef::Log.trace("Rescued error in http connect, re-raising as Errno::ECONNREFUSED to hide bug in net/http")
          Chef::Log.trace("#{e.class.name}: #{e}")
          Chef::Log.trace(e.backtrace.join("\n"))
          raise Errno::ECONNREFUSED, "Connection refused attempting to contact #{url.scheme}://#{host}:#{port}"
        else
          raise
        end
      end

      def build_headers(headers)
        @headers = headers.dup
        # No response compression unless we asked for it explicitly:
        @headers[HTTPRequest::ACCEPT_ENCODING] ||= "identity"
        @headers["X-Chef-Version"] = ::Chef::VERSION

        # Only include port in Host header when it is not the default port
        # for the url scheme (80;443) - Fixes CHEF-5355
        host_header = uri_safe_host.dup
        host_header += ":#{port}" unless URI_SCHEME_DEFAULT_PORT[@url.scheme] == port.to_i
        @headers["Host"] = host_header unless @headers.keys.any? { |k| k.downcase.to_s == HOST_LOWER }

        @headers
      end

      def configure_http_request(request_body = nil)
        req_path = path.to_s.dup
        req_path += "?#{query}" if query

        @http_request = case method.to_s.downcase
                        when GET
                          Net::HTTP::Get.new(req_path, headers)
                        when POST
                          Net::HTTP::Post.new(req_path, headers)
                        when PUT
                          Net::HTTP::Put.new(req_path, headers)
                        when PATCH
                          Net::HTTP::Patch.new(req_path, headers)
                        when DELETE
                          Net::HTTP::Delete.new(req_path, headers)
                        when HEAD
                          Net::HTTP::Head.new(req_path, headers)
                        else
                          raise ArgumentError, "You must provide :GET, :PUT, :POST, :DELETE or :HEAD as the method"
                        end

        @http_request.body = request_body if request_body && @http_request.request_body_permitted?
        # Optionally handle HTTP Basic Authentication
        if url.user
          user = CGI.unescape(url.user)
          password = CGI.unescape(url.password) if url.password
          @http_request.basic_auth(user, password)
        end

        # Overwrite default UA
        @http_request[USER_AGENT] = self.class.user_agent
      end

    end
  end
end
