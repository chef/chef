#
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
require 'json'
require 'tempfile'
require 'chef/api_client'
require 'chef/rest/auth_credentials'
require 'chef/rest/rest_request'

class Chef
  class REST
    attr_reader :auth_credentials
    attr_accessor :url, :cookies, :sign_on_redirect, :sign_request

    def initialize(url, client_name=Chef::Config[:node_name], signing_key_filename=Chef::Config[:client_key], options={})
      @url = url
      @cookies = CookieJar.instance
      @default_headers = options[:headers] || {}
      @auth_credentials = AuthCredentials.new(client_name, signing_key_filename)
      @sign_on_redirect = true
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
    def register(name=Chef::Config[:node_name], destination=Chef::Config[:client_key])
      raise Chef::Exceptions::CannotWritePrivateKey, "I cannot write your private key to #{destination} - check permissions?" if (File.exists?(destination) &&  !File.writable?(destination))

      nc = Chef::ApiClient.new
      nc.name(name)

      catch(:done) do
        retries = config[:client_registration_retries] || 5
        0.upto(retries) do |n|
          begin
            response = nc.save(true, true)
            Chef::Log.debug("Registration response: #{response.inspect}")
            raise Chef::Exceptions::CannotWritePrivateKey, "The response from the server did not include a private key!" unless response.has_key?("private_key")
            # Write out the private key
            file = ::File.open(destination, File::WRONLY|File::EXCL|File::CREAT, 0600)
            file.print(response["private_key"])
            file.close
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
    # === Parameters
    # path:: The path to GET
    # raw:: Whether you want the raw body returned, or JSON inflated.  Defaults
    #   to JSON inflated.
    def get_rest(path, raw=false, headers={})
      run_request(:GET, create_url(path), headers, false, 10, raw)
    end

    # Send an HTTP DELETE request to the path
    def delete_rest(path, headers={})
      run_request(:DELETE, create_url(path), headers)
    end

    # Send an HTTP POST request to the path
    def post_rest(path, json, headers={})
      run_request(:POST, create_url(path), headers, json)
    end

    # Send an HTTP PUT request to the path
    def put_rest(path, json, headers={})
      run_request(:PUT, create_url(path), headers, json)
    end

    def create_url(path)
      if path =~ /^(http|https):\/\//
        URI.parse(path)
      else
        URI.parse("#{@url}/#{path}")
      end
    end

    # def sign_request(http_method, path, body="", host="localhost")
    #   auth_credentials.signature_headers(:http_method => http_method, :path => path, :body => body, :host => host)
    # end

    def sign_requests?
      auth_credentials.sign_requests?
    end

    # Actually run an HTTP request.  First argument is the HTTP method,
    # which should be one of :GET, :PUT, :POST or :DELETE.  Next is the
    # URL, then an object to include in the body (which will be converted with
    # .to_json) and finally, the limit of HTTP Redirects to follow (10).
    #
    # Typically, you won't use this method -- instead, you'll use one of
    # the helper methods (get_rest, post_rest, etc.)
    #
    # Will return the body of the response on success.
    def run_request(method, url, headers={}, data=false, limit=10, raw=false)
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      headers = @default_headers.merge(headers)
      headers['Accept'] = "application/json" unless raw

      if data
        json_body = data.to_json
        headers["Content-Type"] = 'application/json'
      else
        json_body = nil
      end

      headers.merge!(authentication_headers(method, url, json_body)) if sign_requests?
      rest_request = Chef::REST::RESTRequest.new(method, url, json_body, headers)


      Chef::Log.debug("Sending HTTP Request via #{method} to #{url.host}:#{url.port}#{rest_request.path}")

      tf = nil
      http_attempts = 0

      begin
        http_attempts += 1

        res = rest_request.call do |response|
          if raw
            tf = stream_to_tempfile(url, response)
          else
            response.read_body
          end
        end

        if res.kind_of?(Net::HTTPSuccess)
          if res['content-type'] =~ /json/
            response_body = res.body.chomp
            JSON.parse(response_body)
          else
            if raw
              tf
            else
              res.body
            end
          end
        elsif res.kind_of?(Net::HTTPFound) or res.kind_of?(Net::HTTPMovedPermanently)
          #store_cookie(url, res)
          @sign_request = false if @sign_on_redirect == false
          run_request(:GET, create_url(res['location']), {}, false, limit - 1, raw)
        else
          if res['content-type'] =~ /json/
            exception = JSON.parse(res.body)
            Chef::Log.debug("HTTP Request Returned #{res.code} #{res.message}: #{exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"]}")
          end
          res.error!
        end

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
      rescue Net::HTTPServerException
        if res.kind_of?(Net::HTTPForbidden)
          if http_retry_count - http_attempts + 1 > 0
            Chef::Log.error("Received 403 Forbidden against #{url.host}:#{url.port} for #{rest_request.path}, retry #{http_attempts}/#{http_retry_count}")
            sleep(http_retry_delay)
            retry
          end
        end
        raise
      end
    end

    def authentication_headers(method, url, json_body=nil)
      # TODO: this method is untested
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

    private

    def stream_to_tempfile(url, response)
      tf = Tempfile.new("chef-rest")
      # Stolen from http://www.ruby-forum.com/topic/166423
      # Kudos to _why!
      size, total = 0, response.header['Content-Length'].to_i
      response.read_body do |chunk|
        tf.write(chunk)
        size += chunk.size
        if size == 0
          Chef::Log.debug("#{url.path} done (0 length file)")
        elsif total == 0
          Chef::Log.debug("#{url.path} (zero content length)")
        else
          Chef::Log.debug("#{url.path}" + " %d%% done (%d of %d)" % [(size * 100) / total, size, total])
        end
      end
      tf.close
      tf
    end

  end
end
