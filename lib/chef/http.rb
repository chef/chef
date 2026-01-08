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

require "tempfile" unless defined?(Tempfile)
autoload :OpenSSL, "openssl"
autoload :URI, "uri"
module Net
  autoload :HTTP, "net/http"
  autoload :HTTPClientException, "net/http"
end
require_relative "http/basic_client"
require_relative "config"
require_relative "platform/query_helpers"
require_relative "exceptions"

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
        # (same as #apply_stream_complete_middleware or #apply_response_middleware)
        @stream_handlers.reverse.inject(next_chunk) do |chunk, handler|
          Chef::Log.trace("Chef::HTTP::StreamHandler calling #{handler.class}#handle_chunk")
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

    attr_reader :options

    attr_reader :middlewares

    # [Boolean] if we're doing keepalives or not
    attr_reader :keepalives

    # @returns [Hash] options for Net::HTTP to be sent to setters on the object
    attr_reader :nethttp_opts

    # Create a HTTP client object. The supplied +url+ is used as the base for
    # all subsequent requests. For example, when initialized with a base url
    # http://localhost:4000, a call to +get+ with 'nodes' will make an
    # HTTP GET request to http://localhost:4000/nodes
    def initialize(url, options = {})
      @url = url
      @default_headers = options[:headers] || {}
      @sign_on_redirect = true
      @redirects_followed = 0
      @redirect_limit = 10
      @keepalives = options[:keepalives] || false
      @options = options
      @nethttp_opts = options[:nethttp] || {}

      @middlewares = []
      self.class.middlewares.each do |middleware_class|
        @middlewares << middleware_class.new(options)
      end
    end

    # Send an HTTP HEAD request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def head(path, headers = {})
      request(:HEAD, path, headers)
    end

    # Send an HTTP GET request to the path
    #
    # === Parameters
    # path:: The path to GET
    def get(path, headers = {})
      request(:GET, path, headers)
    end

    # Send an HTTP PUT request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def put(path, json, headers = {})
      request(:PUT, path, headers, json)
    end

    # Send an HTTP POST request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def post(path, json, headers = {})
      request(:POST, path, headers, json)
    end

    # Send an HTTP DELETE request to the path
    #
    # === Parameters
    # path:: path part of the request URL
    def delete(path, headers = {})
      request(:DELETE, path, headers)
    end

    # Makes an HTTP request to +path+ with the given +method+, +headers+, and
    # +data+ (if applicable).
    def request(method, path, headers = {}, data = false)
      http_attempts ||= 0
      url = create_url(path)
      processed_method, url, processed_headers, processed_data = apply_request_middleware(method, url, headers, data)

      response, rest_request, return_value = send_http_request(processed_method, url, processed_headers, processed_data)
      response, rest_request, return_value = apply_response_middleware(response, rest_request, return_value)

      response.error! unless success_response?(response)
      return_value

    rescue Net::HTTPClientException => e
      http_attempts += 1
      response = e.response
      if response.is_a?(Net::HTTPNotAcceptable) && version_retries - http_attempts >= 0
        Chef::Log.trace("Negotiating protocol version with #{url}, retry #{http_attempts}/#{version_retries}")
        retry
      else
        raise
      end
    rescue Exception => exception
      log_failed_request(response, return_value) unless response.nil?
      raise
    end

    def streaming_request_with_progress(path, headers = {}, tempfile = nil, &progress_block)
      http_attempts ||= 0
      url = create_url(path)
      response, rest_request, return_value = nil, nil, nil
      data = nil

      method = :GET
      method, url, processed_headers, data = apply_request_middleware(method, url, headers, data)

      response, rest_request, return_value = send_http_request(method, url, processed_headers, data) do |http_response|
        if http_response.is_a?(Net::HTTPSuccess)
          tempfile = stream_to_tempfile(url, http_response, tempfile, &progress_block)
        end
        apply_stream_complete_middleware(http_response, rest_request, return_value)
      end
      return nil if response.is_a?(Net::HTTPRedirection)

      unless response.is_a?(Net::HTTPSuccess)
        response.error!
      end
      tempfile
    rescue Net::HTTPClientException => e
      http_attempts += 1
      response = e.response
      if response.is_a?(Net::HTTPNotAcceptable) && version_retries - http_attempts >= 0
        Chef::Log.trace("Negotiating protocol version with #{url}, retry #{http_attempts}/#{version_retries}")
        retry
      else
        raise
      end
    rescue Exception => e
      log_failed_request(response, return_value) unless response.nil?
      raise
    end

    # Makes a streaming download request, streaming the response body to a
    # tempfile. If a block is given, the tempfile is passed to the block and
    # the tempfile will automatically be unlinked after the block is executed.
    #
    # If no block is given, the tempfile is returned, which means it's up to
    # you to unlink the tempfile when you're done with it.
    #
    # @yield [tempfile] block to process the tempfile
    # @yieldparam [tempfile<Tempfile>] tempfile
    def streaming_request(path, headers = {}, tempfile = nil)
      http_attempts ||= 0
      url = create_url(path)
      response, rest_request, return_value = nil, nil, nil
      data = nil

      method = :GET
      method, url, processed_headers, data = apply_request_middleware(method, url, headers, data)

      response, rest_request, return_value = send_http_request(method, url, processed_headers, data) do |http_response|
        if http_response.is_a?(Net::HTTPSuccess)
          tempfile = stream_to_tempfile(url, http_response, tempfile)
        end
        apply_stream_complete_middleware(http_response, rest_request, return_value)
      end

      return nil if response.is_a?(Net::HTTPRedirection)

      unless response.is_a?(Net::HTTPSuccess)
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
    rescue Net::HTTPClientException => e
      http_attempts += 1
      response = e.response
      if response.is_a?(Net::HTTPNotAcceptable) && version_retries - http_attempts >= 0
        Chef::Log.trace("Negotiating protocol version with #{url}, retry #{http_attempts}/#{version_retries}")
        retry
      else
        raise
      end
    rescue Exception => e
      log_failed_request(response, return_value) unless response.nil?
      raise
    end

    def http_client(base_url = nil)
      base_url ||= url
      if keepalives && !base_url.nil?
        # only reuse the http_client if we want keepalives and have a base_url
        @http_client ||= {}
        # the per-host per-port cache here gets persistent connections correct when
        # redirecting to different servers
        if base_url.is_a?(String) # sigh, this kind of abuse can't happen with strongly typed languages
          @http_client[base_url] ||= build_http_client(base_url)
        else
          @http_client[base_url.host] ||= {}
          @http_client[base_url.host][base_url.port] ||= build_http_client(base_url)
        end
      else
        build_http_client(base_url)
      end
    end

    # DEPRECATED: This is only kept around to provide access to cache control data in
    # lib/chef/provider/remote_file/http.rb
    # FIXME: Find a better API.
    def last_response
      @last_response
    end

    private

    # @api private
    def ssl_policy
      return Chef::HTTP::APISSLPolicy unless @options[:ssl_verify_mode]

      case @options[:ssl_verify_mode]
      when :verify_none
        Chef::HTTP::VerifyNoneSSLPolicy
      when :verify_peer
        Chef::HTTP::VerifyPeerSSLPolicy
      else
        Chef::Log.error("Chef::HTTP was passed an ssl_verify_mode of #{@options[:ssl_verify_mode]} which is unsupported. Falling back to the API policy")
        Chef::HTTP::APISSLPolicy
      end
    end

    # @api private
    def build_http_client(base_url)
      if chef_zero_uri?(base_url)
        # PERFORMANCE CRITICAL: *MUST* lazy require here otherwise we load up webrick
        # via chef-zero and that hits DNS (at *require* time) which may timeout,
        # when for most knife/chef-client work we never need/want this loaded.

        unless defined?(SocketlessChefZeroClient)
          require_relative "http/socketless_chef_zero_client"
        end

        SocketlessChefZeroClient.new(base_url)
      else
        BasicClient.new(base_url, ssl_policy: ssl_policy, keepalives: keepalives, nethttp_opts: nethttp_opts)
      end
    end

    # @api private
    def create_url(path)
      return path if path.is_a?(URI)

      if %r{^(http|https|chefzero)://}i.match?(path)
        URI.parse(path)
      elsif path.nil? || path.empty?
        URI.parse(@url)
      else
        # The regular expressions used here are to make sure '@url' does not have
        # any trailing slashes and 'path' does not have any leading slashes. This
        # way they are always joined correctly using just one slash.
        URI.parse(@url.gsub(%r{/+$}, "") + "/" + path.gsub(%r{^/+}, ""))
      end
    end

    # @api private
    def apply_request_middleware(method, url, headers, data)
      middlewares.inject([method, url, headers, data]) do |req_data, middleware|
        Chef::Log.trace("Chef::HTTP calling #{middleware.class}#handle_request")
        middleware.handle_request(*req_data)
      end
    end

    # @api private
    def apply_response_middleware(response, rest_request, return_value)
      middlewares.reverse.inject([response, rest_request, return_value]) do |res_data, middleware|
        Chef::Log.trace("Chef::HTTP calling #{middleware.class}#handle_response")
        middleware.handle_response(*res_data)
      end
    end

    # @api private
    def apply_stream_complete_middleware(response, rest_request, return_value)
      middlewares.reverse.inject([response, rest_request, return_value]) do |res_data, middleware|
        Chef::Log.trace("Chef::HTTP calling #{middleware.class}#handle_stream_complete")
        middleware.handle_stream_complete(*res_data)
      end
    end

    # @api private
    def log_failed_request(response, return_value)
      return_value ||= {}
      error_message = "HTTP Request Returned #{response.code} #{response.message}: "
      error_message << (return_value["error"].respond_to?(:join) ? return_value["error"].join(", ") : return_value["error"].to_s)
      Chef::Log.info(error_message)
    end

    # @api private
    def success_response?(response)
      response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
    end

    # Runs a synchronous HTTP request, with no middleware applied (use #request
    # to have the middleware applied). The entire response will be loaded into memory.
    # @api private
    def send_http_request(method, url, base_headers, body, &response_handler)
      retrying_http_errors(url) do
        headers = build_headers(method, url, base_headers, body)
        client = http_client(url)
        return_value = nil
        if block_given?
          request, response = client.request(method, url, body, headers, &response_handler)
        else
          request, response = client.request(method, url, body, headers, &:read_body)
          return_value = response.read_body
        end
        @last_response = response

        if response.is_a?(Net::HTTPSuccess)
          [response, request, return_value]
        elsif response.is_a?(Net::HTTPNotModified) # Must be tested before Net::HTTPRedirection because it's subclass.
          [response, request, false]
        elsif redirect_location = redirected_to(response)
          if %i{GET HEAD}.include?(method)
            follow_redirect do
              redirected_url = url + redirect_location
              if http_disable_auth_on_redirect
                new_headers = build_headers(method, redirected_url, headers, body)
                new_headers.delete("Authorization") if url.host != redirected_url.host
                send_http_request(method, redirected_url, new_headers, body, &response_handler)
              else
                send_http_request(method, redirected_url, headers, body, &response_handler)
              end
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
    # @api private
    def retrying_http_errors(url)
      http_attempts = 0
      begin
        loop do
          http_attempts += 1
          response, request, return_value = yield
          # handle HTTP 50X Error
          if response.is_a?(Net::HTTPServerError) && !Chef::Config.local_mode
            if http_retry_count - http_attempts >= 0
              sleep_time = 1 + (2**http_attempts) + rand(2**http_attempts)
              Chef::Log.warn("Server returned error #{response.code} for #{url}, retrying #{http_attempts}/#{http_retry_count} in #{sleep_time}s") # Updated from error to warn
              sleep(sleep_time)
              redo
            end
          end
          return [response, request, return_value]
        end
      rescue SocketError, Errno::ETIMEDOUT, Errno::ECONNRESET => e
        if http_retry_count - http_attempts >= 0
          Chef::Log.warn("Error connecting to #{url}, retry #{http_attempts}/#{http_retry_count}") # Updated from error to warn
          sleep(http_retry_delay)
          retry
        end
        e.message.replace "Error connecting to #{url} - #{e.message}"
        raise e
      rescue Errno::ECONNREFUSED
        if http_retry_count - http_attempts >= 0
          Chef::Log.warn("Connection refused connecting to #{url}, retry #{http_attempts}/#{http_retry_count}") # Updated from error to warn
          sleep(http_retry_delay)
          retry
        end
        raise Errno::ECONNREFUSED, "Connection refused connecting to #{url}, giving up"
      rescue Timeout::Error
        if http_retry_count - http_attempts >= 0
          Chef::Log.warn("Timeout connecting to #{url}, retry #{http_attempts}/#{http_retry_count}") # Updated from error to warn
          sleep(http_retry_delay)
          retry
        end
        raise Timeout::Error, "Timeout connecting to #{url}, giving up"
      rescue OpenSSL::SSL::SSLError => e
        if (http_retry_count - http_attempts >= 0) && !e.message.include?("certificate verify failed")
          Chef::Log.warn("SSL Error connecting to #{url}, retry #{http_attempts}/#{http_retry_count}") # Updated from error to warn
          sleep(http_retry_delay)
          retry
        end
        raise OpenSSL::SSL::SSLError, "SSL Error connecting to #{url} - #{e.message}"
      end
    end

    def version_retries
      @version_retries ||= options[:version_class]&.possible_requests || 1
    end

    # @api private
    def http_retry_delay
      options[:http_retry_delay] || config[:http_retry_delay]
    end

    # @api private
    def http_retry_count
      options[:http_retry_count] || config[:http_retry_count]
    end

    # @api private
    def http_disable_auth_on_redirect
      config[:http_disable_auth_on_redirect]
    end

    # @api private
    def config
      Chef::Config
    end

    # @api private
    def follow_redirect
      raise Chef::Exceptions::RedirectLimitExceeded if @redirects_followed >= redirect_limit

      @redirects_followed += 1
      Chef::Log.trace("Following redirect #{@redirects_followed}/#{redirect_limit}")

      yield
    ensure
      @redirects_followed = 0
    end

    # @api private
    def chef_zero_uri?(uri)
      uri = URI.parse(uri) unless uri.respond_to?(:scheme)
      uri.scheme == "chefzero"
    end

    # @api private
    def redirected_to(response)
      return nil  unless response.is_a?(Net::HTTPRedirection)
      # Net::HTTPNotModified is undesired subclass of Net::HTTPRedirection so test for this
      return nil  if response.is_a?(Net::HTTPNotModified)

      response["location"]
    end

    # @api private
    def build_headers(method, url, headers = {}, json_body = false)
      headers = @default_headers.merge(headers)
      headers["Content-Length"] = json_body.bytesize.to_s if json_body
      headers.merge!(Chef::Config[:custom_http_headers]) if Chef::Config[:custom_http_headers]
      headers
    end

    # @api private
    def stream_to_tempfile(url, response, tf = nil, &progress_block)
      content_length = response["Content-Length"]
      if tf.nil?
        tf = Tempfile.open("chef-rest")
        if ChefUtils.windows?
          tf.binmode # required for binary files on Windows platforms
        end
      end
      Chef::Log.trace("Streaming download from #{url} to tempfile #{tf.path}")
      # Stolen from http://www.ruby-forum.com/topic/166423
      # Kudos to _why!

      stream_handler = StreamHandler.new(middlewares, response)

      response.read_body do |chunk|
        tf.write(stream_handler.handle_chunk(chunk))
        yield tf.size, content_length if block_given?
      end
      tf.close
      tf
    rescue Exception
      tf.close! if tf
      raise
    end

  end
end
