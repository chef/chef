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

require 'tempfile'
require 'chef/http'
class Chef
  class HTTP; end
  class REST < HTTP; end
end

require 'chef/http/authenticator'
require 'chef/http/decompressor'
require 'chef/http/json_input'
require 'chef/http/json_to_model_output'
require 'chef/http/cookie_manager'
require 'chef/http/validate_content_length'
require 'chef/config'
require 'chef/exceptions'
require 'chef/platform/query_helpers'
require 'chef/http/remote_request_id'

class Chef

  # == Chef::REST
  # Chef's custom REST client with built-in JSON support and RSA signed header
  # authentication.
  class REST < HTTP

    # Backwards compatibility for things that use
    # Chef::REST::RESTRequest or its constants
    RESTRequest = HTTP::HTTPRequest

    attr_accessor :url, :cookies, :sign_on_redirect, :redirect_limit

    attr_reader :authenticator

    # Create a REST client object. The supplied +url+ is used as the base for
    # all subsequent requests. For example, when initialized with a base url
    # http://localhost:4000, a call to +get_rest+ with 'nodes' will make an
    # HTTP GET request to http://localhost:4000/nodes
    def initialize(url, client_name=Chef::Config[:node_name], signing_key_filename=Chef::Config[:client_key], options={})

      signing_key_filename = nil if chef_zero_uri?(url)

      options = options.dup
      options[:client_name] = client_name
      options[:signing_key_filename] = signing_key_filename
      super(url, options)

      @decompressor = Decompressor.new(options)
      @authenticator = Authenticator.new(options)
      @request_id = RemoteRequestID.new(options)

      @middlewares << JSONInput.new(options)
      @middlewares << JSONToModelOutput.new(options)
      @middlewares << CookieManager.new(options)
      @middlewares << @decompressor
      @middlewares << @authenticator
      @middlewares << @request_id

      # ValidateContentLength should come after Decompressor
      # because the order of middlewares is reversed when handling
      # responses.
      @middlewares << ValidateContentLength.new(options)

    end

    def signing_key_filename
      authenticator.signing_key_filename
    end

    def auth_credentials
      authenticator.auth_credentials
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
        streaming_request(path, headers)
      else
        request(:GET, path, headers)
      end
    end

    alias :get_rest :get

    alias :delete_rest :delete

    alias :post_rest :post

    alias :put_rest :put

    # Streams a download to a tempfile, then yields the tempfile to a block.
    # After the download, the tempfile will be closed and unlinked.
    # If you rename the tempfile, it will not be deleted.
    # Beware that if the server streams infinite content, this method will
    # stream it until you run out of disk space.
    def fetch(path, headers={})
      streaming_request(create_url(path), headers) {|tmp_file| yield tmp_file }
    end

    alias :api_request :request

    # Do a HTTP request where no middleware is loaded (e.g. JSON input/output
    # conversion) but the standard Chef Authentication headers are added to the
    # request.
    def raw_http_request(method, path, headers, data)
      url = create_url(path)
      method, url, headers, data = @authenticator.handle_request(method, url, headers, data)
      method, url, headers, data = @request_id.handle_request(method, url, headers, data)
      response, rest_request, return_value = send_http_request(method, url, headers, data)
      response.error! unless success_response?(response)
      return_value
    rescue Exception => exception
      log_failed_request(response, return_value) unless response.nil?

      if exception.respond_to?(:chef_rest_request=)
        exception.chef_rest_request = rest_request
      end
      raise
    end

    # Deprecated:
    # Responsibilities of this method have been split up. The #http_client is
    # now responsible for making individual requests, while
    # #retrying_http_errors handles error/retry logic.
    def retriable_http_request(method, url, req_body, headers)
      rest_request = Chef::HTTP::HTTPRequest.new(method, url, req_body, headers)

      Chef::Log.debug("Sending HTTP Request via #{method} to #{url.host}:#{url.port}#{rest_request.path}")

      retrying_http_errors(url) do
        yield rest_request
      end
    end

    # Customized streaming behavior; sets the accepted content type to "*/*"
    # if not otherwise specified for compatibility purposes
    def streaming_request(url, headers, &block)
      headers["Accept"] ||= "*/*"
      super
    end

    alias :retriable_rest_request :retriable_http_request

    def follow_redirect
      unless @sign_on_redirect
        @authenticator.sign_request = false
      end
      super
    ensure
      @authenticator.sign_request = true
    end

    public :create_url

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
