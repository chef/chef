#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009, 2010, 2013 Opscode, Inc.
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

require 'net/https'
require 'uri'
require 'chef/rest/rest_request'
require 'chef/monkey_patches/string'
require 'chef/monkey_patches/net_http'
require 'chef/config'
require 'chef/exceptions'

class Chef
  # == Chef::HTTP
  # Basic HTTP client, with support for adding features via middleware
  class HTTP

    def self.middlewares
      @middlewares ||= []
    end

    def self.use(middleware_class)
      middlewares << middleware_class
    end

    attr_reader :url
    attr_reader :cookies
    attr_reader :sign_on_redirect
    attr_reader :redirect_limit

    attr_reader :middlewares

    # Create a HTTP client object. The supplied +url+ is used as the base for
    # all subsequent requests. For example, when initialized with a base url
    # http://localhost:4000, a call to +get+ with 'nodes' will make an
    # HTTP GET request to http://localhost:4000/nodes
    def initialize(url, options={})
      @url = url
      @cookies = REST::CookieJar.instance
      @default_headers = options[:headers] || {}
      @sign_on_redirect = true
      @redirects_followed = 0
      @redirect_limit = 10

      @middlewares = []
      self.class.middlewares.each do |middleware_class|
        @middlewares << middleware_class.new(options)
      end
    end

    # Send an HTTP HEAD request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def head(path, headers={})
      api_request(:HEAD, create_url(path), headers)
    end

    # Send an HTTP GET request to the path
    #
    # === Parameters
    # path:: The path to GET
    def get(path, headers={})
      api_request(:GET, create_url(path), headers)
    end

    # Send an HTTP PUT request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def put(path, json, headers={})
      api_request(:PUT, create_url(path), headers, json)
    end

    # Send an HTTP POST request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def post(path, json, headers={})
      api_request(:POST, create_url(path), headers, json)
    end

    # Send an HTTP DELETE request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def delete(path, headers={})
      api_request(:DELETE, create_url(path), headers)
    end

    def create_url(path)
      if path =~ /^(http|https):\/\//
        URI.parse(path)
      else
        URI.parse("#{@url}/#{path}")
      end
    end

    def request(method, url, headers={}, data=false)

      method, url, headers, data = apply_request_middleware(method, url, headers, data)

      response, rest_request, return_value = send_http_request(method, url, headers, data)
      response, rest_request, return_value = apply_response_middleware(response, rest_request, return_value)
      response.error! unless success_response?(response)
      return_value
    rescue Exception => exception
      log_failed_request(response, return_value) unless response.nil?

      if exception.respond_to?(:chef_rest_request=)
        exception.chef_rest_request = rest_request
      end
      raise
    end

    def apply_request_middleware(method, url, headers, data)
      middlewares.inject([method, url, headers, data]) do |req_data, middleware|
        middleware.handle_request(*req_data)
      end
    end

    def apply_response_middleware(response, rest_request, return_value)
      middlewares.reverse.inject([response, rest_request, return_value]) do |res_data, middleware|
        middleware.handle_response(*res_data)
      end
    end

    def log_failed_request(response, return_value)
      return_value ||= {}
      error_message = "HTTP Request Returned #{response.code} #{response.message}: "
      error_message << (return_value["error"].respond_to?(:join) ? return_value["error"].join(", ") : return_value["error"].to_s)
      Chef::Log.info(error_message)
    end

    def success_response?(response)
      response.kind_of?(Net::HTTPSuccess) || response.kind_of?(Net::HTTPRedirection)
    end

    # Runs a synchronous HTTP request, with no middleware applied (use #request
    # to have the middleware applied). The entire response will be loaded into memory.
    def send_http_request(method, url, headers, body)
      headers = build_headers(method, url, headers, body)
      retriable_http_request(method, url, body, headers) do |rest_request|
        response = rest_request.call {|r| r.read_body}
        @last_response = response

        Chef::Log.debug("---- HTTP Status and Header Data: ----")
        Chef::Log.debug("HTTP #{response.http_version} #{response.code} #{response.msg}")

        response.each do |header, value|
          Chef::Log.debug("#{header}: #{value}")
        end
        Chef::Log.debug("---- End HTTP Status/Header Data ----")

        if response.kind_of?(Net::HTTPSuccess)
          [response, rest_request, nil]
        elsif response.kind_of?(Net::HTTPNotModified) # Must be tested before Net::HTTPRedirection because it's subclass.
          [response, rest_request, false]
        elsif redirect_location = redirected_to(response)
          if [:GET, :HEAD].include?(method)
            follow_redirect {api_request(method, create_url(redirect_location))}
          else
            raise Exceptions::InvalidRedirect, "#{method} request was redirected from #{url} to #{redirect_location}. Only GET and HEAD support redirects."
          end
        else
          [response, rest_request, nil]
        end
      end
    end

    def retriable_http_request(method, url, req_body, headers)
      rest_request = Chef::REST::RESTRequest.new(method, url, req_body, headers)

      Chef::Log.debug("Sending HTTP Request via #{method} to #{url.host}:#{url.port}#{rest_request.path}")

      http_attempts = 0

      begin
        http_attempts += 1

        yield rest_request

      rescue SocketError, Errno::ETIMEDOUT => e
        e.message.replace "Error connecting to #{url} - #{e.message}"
        raise e
      rescue Errno::ECONNREFUSED
        if http_retry_count - http_attempts + 1 > 0
          Chef::Log.error("Connection refused connecting to #{url.host}:#{url.port} for #{rest_request.path}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        raise Errno::ECONNREFUSED, "Connection refused connecting to #{url.host}:#{url.port} for #{rest_request.path}, giving up"
      rescue Timeout::Error
        if http_retry_count - http_attempts + 1 > 0
          Chef::Log.error("Timeout connecting to #{url.host}:#{url.port} for #{rest_request.path}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        raise Timeout::Error, "Timeout connecting to #{url.host}:#{url.port} for #{rest_request.path}, giving up"
      rescue Net::HTTPFatalError => e
        if http_retry_count - http_attempts + 1 > 0
          sleep_time = 1 + (2 ** http_attempts) + rand(2 ** http_attempts)
          Chef::Log.error("Server returned error for #{url}, retrying #{http_attempts}/#{http_retry_count} in #{sleep_time}s")
          sleep(sleep_time)
          retry
        end
        raise
      end
    end

    def http_retry_delay
      config[:http_retry_delay]
    end

    def http_retry_count
      config[:http_retry_count]
    end

    def config
      Chef::Config
    end

    def follow_redirect
      raise Chef::Exceptions::RedirectLimitExceeded if @redirects_followed >= redirect_limit
      @redirects_followed += 1
      Chef::Log.debug("Following redirect #{@redirects_followed}/#{redirect_limit}")
      if @sign_on_redirect
        yield
      else
        @authenticator.sign_request = false
        yield
      end
    ensure
      @redirects_followed = 0
      @authenticator.sign_request = true
    end

    private

    def redirected_to(response)
      return nil  unless response.kind_of?(Net::HTTPRedirection)
      # Net::HTTPNotModified is undesired subclass of Net::HTTPRedirection so test for this
      return nil  if response.kind_of?(Net::HTTPNotModified)
      response['location']
    end

    def build_headers(method, url, headers={}, json_body=false)
      headers                 = @default_headers.merge(headers)
      headers['Content-Length'] = json_body.bytesize.to_s if json_body
      headers.merge!(Chef::Config[:custom_http_headers]) if Chef::Config[:custom_http_headers]
      headers
    end

    public

    ############################################################################
    # DEPRECATED
    ############################################################################

    # This is only kept around to provide access to cache control data in
    # lib/chef/provider/remote_file/http.rb
    # Find a better API.
    def last_response
      @last_response
    end

  end
end

