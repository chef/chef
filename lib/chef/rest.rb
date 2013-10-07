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

    def head(path, headers={})
      api_request(:HEAD, create_url(path), headers)
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

    alias :get_rest :get

    alias :delete_rest :delete

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

    # Chef::REST doesn't define middleware in the normal way for backcompat reasons, so it's hardcoded here.
    def middlewares
      [@chef_json_inflater, @cookie_manager, @decompressor, @authenticator]
    end

    alias :api_request :request

    alias :raw_http_request :send_http_request

    alias :retriable_rest_request :retriable_http_request

    # Makes a streaming download request. <b>Doesn't speak JSON.</b>
    # Streams the response body to a tempfile. If a block is given, it's
    # passed to Tempfile.open(), which means that the tempfile will automatically
    # be unlinked after the block is executed.
    #
    # If no block is given, the tempfile is returned, which means it's up to
    # you to unlink the tempfile when you're done with it.
    def streaming_request(url, headers, &block)
      method, url, headers, data = [@decompressor, @authenticator].inject([:GET, url, headers, nil]) do |req_data, middleware|
        middleware.handle_request(*req_data)
      end
      headers = build_headers(method, url, headers, data)
      retriable_rest_request(method, url, data, headers) do |rest_request|
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

    def follow_redirect
      unless @sign_on_redirect
        @authenticator.sign_request = false
      end
      super
    ensure
      @authenticator.sign_request = true
    end
    private

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

    # This is only kept around to provide access to cache control data in
    # lib/chef/provider/remote_file/http.rb
    # Find a better API.
    def last_response
      @last_response
    end

    def decompress_body(body)
      @decompressor.decompress_body(body)
    end

    def authentication_headers(method, url, json_body=nil)
      authenticator.authentication_headers(method, url, json_body)
    end

  end
end
