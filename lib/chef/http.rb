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

require 'tempfile'
require 'net/https'
require 'uri'
require 'chef/http/basic_client'
require 'chef/http/socketless_chef_zero_client'
require 'chef/monkey_patches/net_http'
require 'chef/config'
require 'chef/platform/query_helpers'
require 'chef/exceptions'

class Chef

  # == Chef::HTTP
  # Basic HTTP client, with support for adding features via middleware
  class HTTP

    # Class for applying middleware behaviors to streaming
    # responses. Collects stream handlers (if any) from each
    # middleware. When #handle_chunk is called, the chunk gets
    # passed to all handlers in turn for processing.
    class StreamHandler
      def initialize(middlewares, response)
        middlewares = middlewares.flatten
        @stream_handlers = []
        middlewares.each do |middleware|
          stream_handler = middleware.stream_response_handler(response)
          @stream_handlers << stream_handler unless stream_handler.nil?
        end
      end

      def handle_chunk(next_chunk)
        # stream handlers handle responses so must be applied in reverse order
        # (same as #apply_stream_complete_middleware or #apply_response_midddleware)
        @stream_handlers.reverse.inject(next_chunk) do |chunk, handler|
          Chef::Log.debug("Chef::HTTP::StreamHandler calling #{handler.class}#handle_chunk")
          handler.handle_chunk(chunk)
        end
      end

    end


    def self.middlewares
      @middlewares ||= []
    end

    def self.use(middleware_class)
      middlewares << middleware_class
    end

    attr_reader :url
    attr_reader :sign_on_redirect
    attr_reader :redirect_limit

    attr_reader :middlewares

    # Create a HTTP client object. The supplied +url+ is used as the base for
    # all subsequent requests. For example, when initialized with a base url
    # http://localhost:4000, a call to +get+ with 'nodes' will make an
    # HTTP GET request to http://localhost:4000/nodes
    def initialize(url, options={})
      @url = url
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
      request(:HEAD, path, headers)
    end

    # Send an HTTP GET request to the path
    #
    # === Parameters
    # path:: The path to GET
    def get(path, headers={})
      request(:GET, path, headers)
    end

    # Send an HTTP PUT request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def put(path, json, headers={})
      request(:PUT, path, headers, json)
    end

    # Send an HTTP POST request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def post(path, json, headers={})
      request(:POST, path, headers, json)
    end

    # Send an HTTP DELETE request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def delete(path, headers={})
      request(:DELETE, path, headers)
    end

    # Makes an HTTP request to +path+ with the given +method+, +headers+, and
    # +data+ (if applicable).
    def request(method, path, headers={}, data=false)
      url = create_url(path)
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

    # Makes a streaming download request, streaming the response body to a
    # tempfile. If a block is given, the tempfile is passed to the block and
    # the tempfile will automatically be unlinked after the block is executed.
    #
    # If no block is given, the tempfile is returned, which means it's up to
    # you to unlink the tempfile when you're done with it.
    def streaming_request(path, headers={}, &block)
      url = create_url(path)
      response, rest_request, return_value = nil, nil, nil
      tempfile = nil

      method = :GET
      method, url, headers, data = apply_request_middleware(method, url, headers, data)

      response, rest_request, return_value = send_http_request(method, url, headers, data) do |http_response|
        if http_response.kind_of?(Net::HTTPSuccess)
          tempfile = stream_to_tempfile(url, http_response)
        end
        apply_stream_complete_middleware(http_response, rest_request, return_value)
      end

      return nil if response.kind_of?(Net::HTTPRedirection)
      unless response.kind_of?(Net::HTTPSuccess)
        response.error!
      end

      if block_given?
        begin
          yield tempfile
        ensure
          tempfile && tempfile.close!
        end
      end
      tempfile
    rescue Exception => e
      log_failed_request(response, return_value) unless response.nil?
      if e.respond_to?(:chef_rest_request=)
        e.chef_rest_request = rest_request
      end
      raise
    end

    def http_client(base_url=nil)
      base_url ||= url
      if chef_zero_uri?(base_url)
        SocketlessChefZeroClient.new(base_url)
      else
        BasicClient.new(base_url, :ssl_policy => Chef::HTTP::APISSLPolicy)
      end
    end

    protected

    def create_url(path)
      return path if path.is_a?(URI)
      if path =~ /^(http|https|chefzero):\/\//i
        URI.parse(path)
      elsif path.nil? or path.empty?
        URI.parse(@url)
      else
        # The regular expressions used here are to make sure '@url' does not have
        # any trailing slashes and 'path' does not have any leading slashes. This
        # way they are always joined correctly using just one slash.
        URI.parse(@url.gsub(%r{/+$}, '') + '/' + path.gsub(%r{^/+}, ''))
      end
    end

    def apply_request_middleware(method, url, headers, data)
      middlewares.inject([method, url, headers, data]) do |req_data, middleware|
        Chef::Log.debug("Chef::HTTP calling #{middleware.class}#handle_request")
        middleware.handle_request(*req_data)
      end
    end

    def apply_response_middleware(response, rest_request, return_value)
      middlewares.reverse.inject([response, rest_request, return_value]) do |res_data, middleware|
        Chef::Log.debug("Chef::HTTP calling #{middleware.class}#handle_response")
        middleware.handle_response(*res_data)
      end
    end

    def apply_stream_complete_middleware(response, rest_request, return_value)
      middlewares.reverse.inject([response, rest_request, return_value]) do |res_data, middleware|
        Chef::Log.debug("Chef::HTTP calling #{middleware.class}#handle_stream_complete")
        middleware.handle_stream_complete(*res_data)
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
    def send_http_request(method, url, headers, body, &response_handler)
      headers = build_headers(method, url, headers, body)

      retrying_http_errors(url) do
        client = http_client(url)
        return_value = nil
        if block_given?
          request, response = client.request(method, url, body, headers, &response_handler)
        else
          request, response = client.request(method, url, body, headers) {|r| r.read_body }
          return_value = response.read_body
        end
        @last_response = response

        if response.kind_of?(Net::HTTPSuccess)
          [response, request, return_value]
        elsif response.kind_of?(Net::HTTPNotModified) # Must be tested before Net::HTTPRedirection because it's subclass.
          [response, request, false]
        elsif redirect_location = redirected_to(response)
          if [:GET, :HEAD].include?(method)
            follow_redirect do
              send_http_request(method, url+redirect_location, headers, body, &response_handler)
            end
          else
            raise Exceptions::InvalidRedirect, "#{method} request was redirected from #{url} to #{redirect_location}. Only GET and HEAD support redirects."
          end
        else
          [response, request, nil]
        end
      end
    end


    # Wraps an HTTP request with retry logic.
    # === Arguments
    # url:: URL of the request, used for error messages
    def retrying_http_errors(url)
      http_attempts = 0
      begin
        loop do
          http_attempts += 1
          response, request, return_value = yield
          # handle HTTP 50X Error
          if response.kind_of?(Net::HTTPServerError) && !Chef::Config.local_mode
            if http_retry_count - http_attempts + 1 > 0
              sleep_time = 1 + (2 ** http_attempts) + rand(2 ** http_attempts)
              Chef::Log.error("Server returned error #{response.code} for #{url}, retrying #{http_attempts}/#{http_retry_count} in #{sleep_time}s")
              sleep(sleep_time)
              redo
            end
          end
          return [response, request, return_value]
        end
      rescue SocketError, Errno::ETIMEDOUT => e
        if http_retry_count - http_attempts + 1 > 0
          Chef::Log.error("Error connecting to #{url}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        e.message.replace "Error connecting to #{url} - #{e.message}"
        raise e
      rescue Errno::ECONNREFUSED
        if http_retry_count - http_attempts + 1 > 0
          Chef::Log.error("Connection refused connecting to #{url}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        raise Errno::ECONNREFUSED, "Connection refused connecting to #{url}, giving up"
      rescue Timeout::Error
        if http_retry_count - http_attempts + 1 > 0
          Chef::Log.error("Timeout connecting to #{url}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        raise Timeout::Error, "Timeout connecting to #{url}, giving up"
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

      yield
    ensure
      @redirects_followed = 0
    end

    private

    def chef_zero_uri?(uri)
      uri = URI.parse(uri) unless uri.respond_to?(:scheme)
      uri.scheme == "chefzero"
    end

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

    def stream_to_tempfile(url, response)
      tf = Tempfile.open("chef-rest")
      if Chef::Platform.windows?
        tf.binmode # required for binary files on Windows platforms
      end
      Chef::Log.debug("Streaming download from #{url.to_s} to tempfile #{tf.path}")
      # Stolen from http://www.ruby-forum.com/topic/166423
      # Kudos to _why!

      stream_handler = StreamHandler.new(middlewares, response)

      response.read_body do |chunk|
        tf.write(stream_handler.handle_chunk(chunk))
      end
      tf.close
      tf
    rescue Exception
      tf.close!
      raise
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
