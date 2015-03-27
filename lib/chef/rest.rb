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

module ChefZero
  # TODO: this needs to wrap all the things in a mutex
  class Socketless

    include Singleton

    def initialize()
      reset!
    end

    def reset!(options={})
      @server = ChefZero::Server.new(options)
      # TODO: make this public or whatever we need to do so we don't need #send
      @app = @server.send(:app)
    end

    def request(rack_env)
      @app.call(rack_env)
    end

  end
end

class Chef

  class SocketlessChefZeroClient

    module Response

      def read_body(dest = nil, &block)
        if dest
          raise "responses from socketless chef zero can't be written to specific destination"
        end

        if block_given?
          block.call(@body)
        else
          super
        end
      end

    end

    # copied verbatim from webrick
    #
    # HTTP status codes and descriptions
    STATUS_MESSAGE = { # :nodoc:
      100 => 'Continue',
      101 => 'Switching Protocols',
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      207 => 'Multi-Status',
      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      307 => 'Temporary Redirect',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      402 => 'Payment Required',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      407 => 'Proxy Authentication Required',
      408 => 'Request Timeout',
      409 => 'Conflict',
      410 => 'Gone',
      411 => 'Length Required',
      412 => 'Precondition Failed',
      413 => 'Request Entity Too Large',
      414 => 'Request-URI Too Large',
      415 => 'Unsupported Media Type',
      416 => 'Request Range Not Satisfiable',
      417 => 'Expectation Failed',
      422 => 'Unprocessable Entity',
      423 => 'Locked',
      424 => 'Failed Dependency',
      426 => 'Upgrade Required',
      428 => 'Precondition Required',
      429 => 'Too Many Requests',
      431 => 'Request Header Fields Too Large',
      500 => 'Internal Server Error',
      501 => 'Not Implemented',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      505 => 'HTTP Version Not Supported',
      507 => 'Insufficient Storage',
      511 => 'Network Authentication Required',
    }

    STATUS_MESSAGE.values.each {|v| v.freeze }
    STATUS_MESSAGE.freeze

    def initialize(base_url)
      @url = base_url
    end

    def host
      @url.hostname
    end

    def port
      "no port"
    end

    # request, response = client.request(method, url, body, headers) {|r| r.read_body }
    def request(method, url, body, headers, &handler_block)
      #pp req: [method, url, body, headers]
      body_str = body || ""
      r = {}
      r["REQUEST_METHOD"] = method.to_s.upcase
      r["SCRIPT_NAME"] = ""
      r["PATH_INFO"] = url.path
      r["QUERY_STRING"] = url.query
      r["SERVER_NAME"] = "localhost"
      r["SERVER_PORT"] = ""
      r["rack.url_scheme"] = "chefzero"
      r["rack.input"] = StringIO.new(body_str)
      pp rack_req: r

      res = ChefZero::Socketless.instance.request(r)

      pp raw_rack_response: res

      net_http_response = to_net_http(res[0], res[1], res[2])

      #pp net_http_response: net_http_response

      yield net_http_response if block_given?

      [self, net_http_response]
    end

    # TODO: this is copied verbatim from the fakeweb project, MIT licensed
    # Add credits where appropriate

    def to_net_http(code, headers, chunked_body)
      body = chunked_body.join('')
      msg = STATUS_MESSAGE[code] or raise "Cannot determine HTTP status message for code #{code}"
      response = Net::HTTPResponse.send(:response_class, code.to_s).new("1.0", code.to_s, msg)
      response.instance_variable_set(:@body, body)
      headers.each do |name, value|
        if value.respond_to?(:each)
          value.each { |v| response.add_field(name, v) }
        else
          response[name] = value
        end
      end

      response.instance_variable_set(:@read, true)
      response.extend(Response)
      response
    end

    private

    def headers_extracted_from_options
      options.reject {|name, _| KNOWN_OPTIONS.include?(name) }.map { |name, value|
        [name.to_s.split("_").map { |segment| segment.capitalize }.join("-"), value]
      }
    end


  end

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

      url_as_uri = url.respond_to?(:scheme) ? url : URI.parse(url)

      # TODO: NEW STUFF ADD TESTS
      scheme = url_as_uri.scheme
      @socketless = (scheme == "chefzero")
      signing_key_filename = nil if @socketless


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

    def create_url(path)
      return path if path.is_a?(URI)
      if path =~ /^(chefzero):\/\//i
        URI.parse(path)
      else
        super
      end
    end

    def http_client(base_url=nil)
      base_url ||= url
      pp url_class: base_url.class, value: base_url
      base_url = URI.parse(base_url) if base_url.kind_of?(String)
      if base_url.scheme == "chefzero"
        pp using_zero_client: base_url
        SocketlessChefZeroClient.new(base_url)
      else
        BasicClient.new(base_url, :ssl_policy => Chef::HTTP::APISSLPolicy)
      end
    end

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
