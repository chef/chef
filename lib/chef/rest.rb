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
require 'chef/http/json_to_model_inflater'
require 'chef/http/cookie_manager'
require 'chef/config'
require 'chef/exceptions'
require 'chef/platform/query_helpers'

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
      options[:client_name] = client_name
      options[:signing_key_filename] = signing_key_filename
      super(url, options)

      @chef_json_inflater = JSONToModelInflater.new(options)
      @cookie_manager = CookieManager.new(options)
      @decompressor = Decompressor.new(options)
      @authenticator = Authenticator.new(options)
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
        streaming_request(create_url(path), headers)
      else
        request(:GET, create_url(path), headers)
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

    # Chef::REST doesn't define middleware in the normal way for backcompat reasons, so it's hardcoded here.
    def middlewares
      [@chef_json_inflater, @cookie_manager, @decompressor, @authenticator]
    end

    alias :api_request :request

    alias :raw_http_request :send_http_request

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
