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

require 'zlib'
require 'net/https'
require 'uri'
require 'chef/json_compat'
require 'tempfile'
require 'chef/rest/auth_credentials'
require 'chef/rest/rest_request'
require 'chef/monkey_patches/string'
require 'chef/monkey_patches/net_http'
require 'chef/config'



class Chef
  # == Chef::REST
  # Chef's custom REST client with built-in JSON support and RSA signed header
  # authentication.
  class REST

    class NoopInflater
      def inflate(chunk)
        chunk
      end
    end

    attr_reader :auth_credentials
    attr_accessor :url, :cookies, :sign_on_redirect, :redirect_limit

    CONTENT_ENCODING  = "content-encoding".freeze
    GZIP              = "gzip".freeze
    DEFLATE           = "deflate".freeze
    IDENTITY          = "identity".freeze

    # Create a REST client object. The supplied +url+ is used as the base for
    # all subsequent requests. For example, when initialized with a base url
    # http://localhost:4000, a call to +get_rest+ with 'nodes' will make an
    # HTTP GET request to http://localhost:4000/nodes
    def initialize(url, client_name=Chef::Config[:node_name], signing_key_filename=Chef::Config[:client_key], options={})
      @url = url
      @cookies = CookieJar.instance
      @default_headers = options[:headers] || {}
      @auth_credentials = AuthCredentials.new(client_name, signing_key_filename)
      @sign_on_redirect, @sign_request = true, true
      @redirects_followed = 0
      @redirect_limit = 10
      @disable_gzip = false
      handle_options(options)
    end

    def signing_key_filename
      @auth_credentials.key_file
    end

    def client_name
      @auth_credentials.client_name
    end

    def signing_key
      @auth_credentials.raw_key
    end

    # Register the client
    #--
    # Requires you to load chef/api_client beforehand. explicit require is removed since
    # most users of this class have no need for chef/api_client. This functionality
    # should be moved anyway...
    def register(name=Chef::Config[:node_name], destination=Chef::Config[:client_key])
      if (File.exists?(destination) &&  !File.writable?(destination))
        raise Chef::Exceptions::CannotWritePrivateKey, "I cannot write your private key to #{destination} - check permissions?"
      end
      nc = Chef::ApiClient.new
      nc.name(name)

      catch(:done) do
        retries = config[:client_registration_retries] || 5
        0.upto(retries) do |n|
          begin
            response = nc.save(true, true)
            Chef::Log.debug("Registration response: #{response.inspect}")
            private_key = if response.respond_to?(:[])
              response["private_key"]
            else
              response.private_key
            end
            unless private_key
              raise Chef::Exceptions::CannotWritePrivateKey, "The response from the server did not include a private key!"
            end
            # Write out the private key
            ::File.open(destination, "w") {|f|
              f.chmod(0600)
              f.print(private_key)
            }
            throw :done
          rescue IOError
            raise Chef::Exceptions::CannotWritePrivateKey, "I cannot write your private key to #{destination}"
          rescue Net::HTTPFatalError => e
            Chef::Log.warn("Failed attempt #{n} of #{retries+1} on client creation")
            raise unless e.response.code == "500"
          end
        end
      end

      true
    end

    # Send an HTTP GET request to the path
    #
    # Using this method to +fetch+ a file is considered deprecated.
    #
    # === Parameters
    # path:: The path to GET
    # raw:: Whether you want the raw body returned, or JSON inflated.  Defaults
    #   to JSON inflated.
    def get_rest(path, raw=false, headers={})
      if raw
        streaming_request(create_url(path), headers)
      else
        api_request(:GET, create_url(path), headers)
      end
    end

    # Send an HTTP DELETE request to the path
    def delete_rest(path, headers={})
      api_request(:DELETE, create_url(path), headers)
    end

    # Send an HTTP POST request to the path
    def post_rest(path, json, headers={})
      api_request(:POST, create_url(path), headers, json)
    end

    # Send an HTTP PUT request to the path
    def put_rest(path, json, headers={})
      api_request(:PUT, create_url(path), headers, json)
    end

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

    def sign_requests?
      auth_credentials.sign_requests? && @sign_request
    end

    # ==== DEPRECATED
    # Use +api_request+ instead
    #--
    # Actually run an HTTP request.  First argument is the HTTP method,
    # which should be one of :GET, :PUT, :POST or :DELETE.  Next is the
    # URL, then an object to include in the body (which will be converted with
    # .to_json). The limit argument is unused, it is present for backwards
    # compatibility. Configure the redirect limit with #redirect_limit=
    # instead.
    #
    # Typically, you won't use this method -- instead, you'll use one of
    # the helper methods (get_rest, post_rest, etc.)
    #
    # Will return the body of the response on success.
    def run_request(method, url, headers={}, data=false, limit=nil, raw=false)
      json_body = data ? Chef::JSONCompat.to_json(data) : nil
      # Force encoding to binary to fix SSL related EOFErrors
      # cf. http://tickets.opscode.com/browse/CHEF-2363
      # http://redmine.ruby-lang.org/issues/5233
      json_body.force_encoding(Encoding::BINARY) if json_body.respond_to?(:force_encoding)
      headers = build_headers(method, url, headers, json_body, raw)

      tf, response_body = nil, nil

      retriable_rest_request(method, url, json_body, headers) do |rest_request|

        res = rest_request.call do |response|
          if raw
            tf = stream_to_tempfile(url, response)
          else
            response_body = decompress_body(response)
          end
        end

        case res
        when Net::HTTPSuccess
          if res['content-type'] =~ /json/
            Chef::JSONCompat.from_json(response_body)
          else
            if method == :HEAD
              true
            elsif raw
              tf
            else
              response_body
            end
          end
        when Net::HTTPNotModified # Must be tested before Net::HTTPRedirection because it's subclass.
          false
        when Net::HTTPRedirection
          follow_redirect {run_request(method, create_url(res['location']), headers, false, nil, raw)}
        else
          if res['content-type'] =~ /json/
            exception = Chef::JSONCompat.from_json(response_body)
            msg = "HTTP Request Returned #{res.code} #{res.message}: "
            msg << (exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"].to_s)
            Chef::Log.warn(msg)
          end
          res.error!
        end
      end
    end

    # Runs an HTTP request to a JSON API with JSON body. File Download not supported.
    def api_request(method, url, headers={}, data=false)
      json_body = data ? Chef::JSONCompat.to_json(data) : nil
      # Force encoding to binary to fix SSL related EOFErrors
      # cf. http://tickets.opscode.com/browse/CHEF-2363
      # http://redmine.ruby-lang.org/issues/5233
      json_body.force_encoding(Encoding::BINARY) if json_body.respond_to?(:force_encoding)
      raw_http_request(method, url, headers, json_body)
    end
    
    # Runs an HTTP request to a JSON API with raw body. File Download not supported.
    def raw_http_request(method, url, headers, body)
      headers = build_headers(method, url, headers, body)
      retriable_rest_request(method, url, body, headers) do |rest_request|
        begin
          response = rest_request.call {|r| r.read_body}

          Chef::Log.debug("---- HTTP Status and Header Data: ----")
          Chef::Log.debug("HTTP #{response.http_version} #{response.code} #{response.msg}")

          response.each do |header, value|
            Chef::Log.debug("#{header}: #{value}")
          end
          Chef::Log.debug("---- End HTTP Status/Header Data ----")

          response_body = decompress_body(response)

          if response.kind_of?(Net::HTTPSuccess)
            if response['content-type'] =~ /json/
              Chef::JSONCompat.from_json(response_body.chomp)
            else
              Chef::Log.warn("Expected JSON response, but got content-type '#{response['content-type']}'")
              response_body
            end
          elsif redirect_location = redirected_to(response)
            if [:GET, :HEAD].include?(method)
              follow_redirect {api_request(method, create_url(redirect_location), headers)}
            else
              raise Exceptions::InvalidRedirect, "#{method} request was redirected from #{url} to #{redirect_location}. Only GET and HEAD support redirects."
            end
          else
            # have to decompress the body before making an exception for it. But the body could be nil.
            response.body.replace(decompress_body(response)) if response.body.respond_to?(:replace)

            if response['content-type'] =~ /json/
              exception = Chef::JSONCompat.from_json(response_body)
              msg = "HTTP Request Returned #{response.code} #{response.message}: "
              msg << (exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"].to_s)
              Chef::Log.info(msg)
            end
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

    def decompress_body(response)
      if gzip_disabled?
        response.body
      else
        case response[CONTENT_ENCODING]
        when GZIP
          Chef::Log.debug "decompressing gzip response"
          Zlib::Inflate.new(Zlib::MAX_WBITS + 16).inflate(response.body)
        when DEFLATE
          Chef::Log.debug "decompressing deflate response"
          Zlib::Inflate.inflate(response.body)
        else
          response.body
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

    def authentication_headers(method, url, json_body=nil)
      request_params = {:http_method => method, :path => url.path, :body => json_body, :host => "#{url.host}:#{url.port}"}
      request_params[:body] ||= ""
      auth_credentials.signature_headers(request_params)
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
        @sign_request = false
        yield
      end
    ensure
      @redirects_followed = 0
      @sign_request = true
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
      #headers['Accept']       = "application/json" unless raw
      headers['Accept']       = "application/json" unless raw
      headers["Content-Type"] = 'application/json' if json_body
      headers['Content-Length'] = json_body.bytesize.to_s if json_body
      headers[RESTRequest::ACCEPT_ENCODING] = RESTRequest::ENCODING_GZIP_DEFLATE unless gzip_disabled?
      headers.merge!(authentication_headers(method, url, json_body)) if sign_requests?
      headers.merge!(Chef::Config[:custom_http_headers]) if Chef::Config[:custom_http_headers]
      headers
    end

    def stream_to_tempfile(url, response)
      tf = Tempfile.open("chef-rest")
      if Chef::Platform.windows?
        tf.binmode #required for binary files on Windows platforms
      end
      Chef::Log.debug("Streaming download from #{url.to_s} to tempfile #{tf.path}")
      # Stolen from http://www.ruby-forum.com/topic/166423
      # Kudos to _why!

      inflater = if gzip_disabled?
        NoopInflater.new
      else
        case response[CONTENT_ENCODING]
        when GZIP
          Chef::Log.debug "decompressing gzip stream"
          Zlib::Inflate.new(Zlib::MAX_WBITS + 16)
        when DEFLATE
          Chef::Log.debug "decompressing inflate stream"
          Zlib::Inflate.new
        else
          NoopInflater.new
        end
      end

      response.read_body do |chunk|
        tf.write(inflater.inflate(chunk))
      end
      tf.close
      tf
    rescue Exception
      tf.close!
      raise
    end

    # gzip is disabled using the disable_gzip => true option in the
    # constructor. When gzip is disabled, no 'Accept-Encoding' header will be
    # set, and the response will not be decompressed, no matter what the
    # Content-Encoding header of the response is. The intended use case for
    # this is to work around situations where you request +file.tar.gz+, but
    # the server responds with a content type of tar and a content encoding of
    # gzip, tricking the client into decompressing the response so you end up
    # with a tar archive (no gzip) named file.tar.gz
    def gzip_disabled?
      @disable_gzip
    end

    def handle_options(opts)
      opts.each do |name, value|
        case name.to_s
        when 'disable_gzip'
          @disable_gzip = value
        end
      end
    end

  end
end
