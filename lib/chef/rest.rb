#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

require 'net/https'
require 'uri'
require 'tempfile'
require 'chef/rest/auth_credentials'
require 'chef/rest/decompressor'
require 'chef/rest/json_to_model_inflater'
require 'chef/rest/rest_request'
require 'chef/monkey_patches/string'
require 'chef/monkey_patches/net_http'
require 'chef/config'
require 'chef/exceptions'
require 'chef/platform/query_helpers'

class Chef
  # == Chef::REST
  # Chef's custom REST client with built-in JSON support and RSA signed header
  # authentication.
  class REST

    class Authenticator

      attr_reader :signing_key_filename
      attr_reader :raw_key
      attr_reader :attr_names
      attr_reader :auth_credentials

      attr_accessor :sign_request

      def initialize(opts={})
        @raw_key = nil
        @sign_request = true
        @signing_key_filename = opts[:signing_key_filename]
        @key = load_signing_key(opts[:signing_key_filename], opts[:raw_key])
        @auth_credentials = AuthCredentials.new(opts[:client_name], @key)
      end

      def handle_request(method, url, headers={}, data=false)
        headers.merge!(authentication_headers(method, url, data)) if sign_requests?
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

      def sign_requests?
        auth_credentials.sign_requests? && @sign_request
      end

      def client_name
        @auth_credentials.client_name
      end

      def load_signing_key(key_file, raw_key = nil)
        if (!!key_file)
          @raw_key = IO.read(key_file).strip
        elsif (!!raw_key)
          @raw_key = raw_key.strip
        else
          return nil
        end
        @key = OpenSSL::PKey::RSA.new(@raw_key)
      rescue SystemCallError, IOError => e
        Chef::Log.warn "Failed to read the private key #{key_file}: #{e.inspect}"
        raise Chef::Exceptions::PrivateKeyMissing, "I cannot read #{key_file}, which you told me to use to sign requests!"
      rescue OpenSSL::PKey::RSAError
        msg = "The file #{key_file} or :raw_key option does not contain a correctly formatted private key.\n"
        msg << "The key file should begin with '-----BEGIN RSA PRIVATE KEY-----' and end with '-----END RSA PRIVATE KEY-----'"
        raise Chef::Exceptions::InvalidPrivateKey, msg
      end

      def authentication_headers(method, url, json_body=nil)
        request_params = {:http_method => method, :path => url.path, :body => json_body, :host => "#{url.host}:#{url.port}"}
        request_params[:body] ||= ""
        auth_credentials.signature_headers(request_params)
      end


    end


    attr_reader :auth_credentials
    attr_accessor :url, :cookies, :sign_on_redirect, :redirect_limit

    attr_reader :authenticator

    # Create a REST client object. The supplied +url+ is used as the base for
    # all subsequent requests. For example, when initialized with a base url
    # http://localhost:4000, a call to +get_rest+ with 'nodes' will make an
    # HTTP GET request to http://localhost:4000/nodes
    def initialize(url, client_name=Chef::Config[:node_name], signing_key_filename=Chef::Config[:client_key], options={})
      options[:client_name] = client_name
      options[:signing_key_filename] = signing_key_filename
      @url = url
      @cookies = CookieJar.instance
      @default_headers = options[:headers] || {}
      @sign_on_redirect = true
      @redirects_followed = 0
      @redirect_limit = 10

      @chef_json_inflater = JSONToModelInflater.new(options)
      @decompressor = Decompressor.new(options)
      @authenticator = Authenticator.new(options)
    end

    def signing_key_filename
      authenticator.signing_key_filename
    end

    def client_name
      authenticator.client_name
    end

    def signing_key
      authenticator.raw_key
    end

    def sign_requests?
      authenticator.sign_requests?
    end

    def last_response
      @last_response
    end

    # Send an HTTP GET request to the path
    #
    # Using this method to +fetch+ a file is considered deprecated.
    #
    # === Parameters
    # path:: The path to GET
    # raw:: Whether you want the raw body returned, or JSON inflated.  Defaults
    #   to JSON inflated.
    def get(path, raw=false, headers={})
      if raw
        streaming_request(create_url(path), headers)
      else
        api_request(:GET, create_url(path), headers)
      end
    end

    def head(path, headers={})
      api_request(:HEAD, create_url(path), headers)
    end

    alias :get_rest :get

    # Send an HTTP DELETE request to the path
    def delete(path, headers={})
      api_request(:DELETE, create_url(path), headers)
    end

    alias :delete_rest :delete

    # Send an HTTP POST request to the path
    def post(path, json, headers={})
      api_request(:POST, create_url(path), headers, json)
    end

    alias :post_rest :post

    # Send an HTTP PUT request to the path
    def put(path, json, headers={})
      api_request(:PUT, create_url(path), headers, json)
    end

    alias :put_rest :put

    # Streams a download to a tempfile, then yields the tempfile to a block.
    # After the download, the tempfile will be closed and unlinked.
    # If you rename the tempfile, it will not be deleted.
    # Beware that if the server streams infinite content, this method will
    # stream it until you run out of disk space.
    def fetch(path, headers={})
      streaming_request(create_url(path), headers) {|tmp_file| yield tmp_file }
    end

    def create_url(path)
      if path =~ /^(http|https):\/\//
        URI.parse(path)
      else
        URI.parse("#{@url}/#{path}")
      end
    end

    # Runs an HTTP request to a JSON API with JSON body. File Download not supported.
    def api_request(method, url, headers={}, data=false)

      method, url, headers, data = @chef_json_inflater.handle_request(method, url, headers, data)
      method, url, headers, data = @decompressor.handle_request(method, url, headers, data)
      method, url, headers, data = @authenticator.handle_request(method, url, headers, data)

      response, rest_request, return_value = raw_http_request(method, url, headers, data)
      response, rest_request, return_value = @authenticator.handle_response(response, rest_request, return_value)
      response, rest_request, return_value = @decompressor.handle_response(response, rest_request, return_value)
      response, rest_request, return_value = @chef_json_inflater.handle_response(response, rest_request, return_value)
      response.error! unless success_response?(response)
      return_value
    rescue Exception => exception
      log_failed_request(response, return_value) unless response.nil?

      if exception.respond_to?(:chef_rest_request=)
        exception.chef_rest_request = rest_request
      end
      raise
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

    # Runs an HTTP request to a JSON API with raw body. File Download not supported.
    def raw_http_request(method, url, headers, body)
      headers = build_headers(method, url, headers, body)
      retriable_rest_request(method, url, body, headers) do |rest_request|
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

    # Makes a streaming download request. <b>Doesn't speak JSON.</b>
    # Streams the response body to a tempfile. If a block is given, it's
    # passed to Tempfile.open(), which means that the tempfile will automatically
    # be unlinked after the block is executed.
    #
    # If no block is given, the tempfile is returned, which means it's up to
    # you to unlink the tempfile when you're done with it.
    def streaming_request(url, headers, &block)
      headers = build_headers(:GET, url, headers, nil, true)
      retriable_rest_request(:GET, url, nil, headers) do |rest_request|
        begin
          tempfile = nil
          response = rest_request.call do |r|
            if block_given? && r.kind_of?(Net::HTTPSuccess)
              begin
                tempfile = stream_to_tempfile(url, r, &block)
                yield tempfile
              ensure
                tempfile.close!
              end
            else
              tempfile = stream_to_tempfile(url, r)
            end
          end
          @last_response = response
          if response.kind_of?(Net::HTTPSuccess)
            tempfile
          elsif redirect_location = redirected_to(response)
            # TODO: test tempfile unlinked when following redirects.
            tempfile && tempfile.close!
            follow_redirect {streaming_request(create_url(redirect_location), {}, &block)}
          else
            tempfile && tempfile.close!
            response.error!
          end
        rescue Exception => e
          if e.respond_to?(:chef_rest_request=)
            e.chef_rest_request = rest_request
          end
          raise
        end
      end
    end

    def retriable_rest_request(method, url, req_body, headers)
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

    def build_headers(method, url, headers={}, json_body=false, raw=false)
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

      inflater = @decompressor.stream_decompressor_for(response)

      response.read_body do |chunk|
        tf.write(inflater.inflate(chunk))
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

    def decompress_body(body)
      @decompressor.decompress_body(body)
    end

    def authentication_headers(method, url, json_body=nil)
      authenticator.authentication_headers(method, url, json_body)
    end

  end
end
