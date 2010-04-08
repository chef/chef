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

require 'chef/mixin/params_validate'
require 'net/https'
require 'uri'
require 'json'
require 'tempfile'
require 'singleton'
require 'mixlib/authentication/signedheaderauth'
require 'chef/api_client'

include Mixlib::Authentication::SignedHeaderAuth

class Chef
  class REST

    class CookieJar < Hash
      include Singleton
    end

    attr_accessor :url, :cookies, :client_name, :signing_key, :signing_key_filename, :sign_on_redirect, :sign_request

    def initialize(url, client_name=Chef::Config[:node_name], signing_key_filename=Chef::Config[:client_key], options={})
      @url = url
      @cookies = CookieJar.instance
      @client_name = client_name
      @default_headers = options[:headers] || {}
      if signing_key_filename
        @signing_key_filename = signing_key_filename
        @signing_key = load_signing_key(signing_key_filename)
        @sign_request = true
      else
        @signing_key = nil
        @sign_request = false
      end
      @sign_on_redirect = true
    end

    def load_signing_key(key)
      begin
        IO.read(key)
      rescue StandardError=>se
        Chef::Log.error "Failed to read the private key #{key}: #{se.inspect}, #{se.backtrace}"
        raise Chef::Exceptions::PrivateKeyMissing, "I cannot read #{key}, which you told me to use to sign requests!"
      end
    end

    # Register the client
    def register(name=Chef::Config[:node_name], destination=Chef::Config[:client_key])
      raise Chef::Exceptions::CannotWritePrivateKey, "I cannot write your private key to #{destination} - check permissions?" if (File.exists?(destination) &&  !File.writable?(destination))

      nc = Chef::ApiClient.new
      nc.name(name)

      catch(:done) do
        retries = Chef::Config[:client_registration_retries] || 5
        0.upto(retries) do |n|
          begin
            response = nc.save(true, true)
            Chef::Log.debug("Registration response: #{response.inspect}")
            raise Chef::Exceptions::CannotWritePrivateKey, "The response from the server did not include a private key!" unless response.has_key?("private_key")
            # Write out the private key
            file = File.open(destination, File::WRONLY|File::EXCL|File::CREAT, 0600)
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

    def sign_request(http_method, path, private_key, user_id, body = "", host="localhost")
      #body = "" if body == false
      timestamp = Time.now.utc.iso8601
      sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(
                                                         :http_method=>http_method,
                                                         :path => path,
                                                         :body=>body,
                                                         :user_id=>user_id,
                                                         :timestamp=>timestamp)
      signed =  sign_obj.sign(private_key).merge({:host => host})
      signed.inject({}){|memo, kv| memo["#{kv[0].to_s.upcase}"] = kv[1];memo}
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

      http = http_client_for(url)

      json_body = data ? data.to_json : nil

      headers = build_headers(headers, url, raw)

      if @sign_request
        raise ArgumentError, "Cannot sign the request without a client name, check that :node_name is assigned" if @client_name.nil?
        Chef::Log.debug("Signing the request as #{@client_name}")
        headers.merge!(authentication_headers(method, url, json_body))
      end

      req = http_request_for(url, method, headers, json_body)

      Chef::Log.debug("Sending HTTP Request via #{req.method} to #{url.host}:#{url.port}#{req.path}")

      res = nil
      tf = nil
      http_attempts = 0

      begin
        http_attempts += 1

        res = http.request(url, req) do |response|
          if raw
            tf = stream_to_tempfile(url, response)
          else
            response.read_body
          end
          response
        end

        if res.kind_of?(Net::HTTPSuccess)
          store_cookie(url, res)

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
          store_cookie(url, res)
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
          Chef::Log.error("Connection refused connecting to #{url.host}:#{url.port} for #{req.path}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        raise Errno::ECONNREFUSED, "Connection refused connecting to #{url.host}:#{url.port} for #{req.path}, giving up"
      rescue Timeout::Error
        if http_retry_count - http_attempts + 1 > 0
          Chef::Log.error("Timeout connecting to #{url.host}:#{url.port} for #{req.path}, retry #{http_attempts}/#{http_retry_count}")
          sleep(http_retry_delay)
          retry
        end
        raise Timeout::Error, "Timeout connecting to #{url.host}:#{url.port} for #{req.path}, giving up"
      rescue Net::HTTPServerException
        if res.kind_of?(Net::HTTPForbidden)
          if http_retry_count - http_attempts + 1 > 0
            Chef::Log.error("Received 403 Forbidden against #{url.host}:#{url.port} for #{req.path}, retry #{http_attempts}/#{http_retry_count}")
            sleep(http_retry_delay)
            retry
          end
        end
        raise
      end
    end

    def authentication_headers(method, url, json_body=nil)
      json_body ||= ""
      sign_request(method, url.path, OpenSSL::PKey::RSA.new(@signing_key), @client_name, json_body, "#{url.host}:#{url.port}")
    end

    def http_retry_delay
      Chef::Config[:http_retry_delay]
    end

    def http_retry_count
      Chef::Config[:http_retry_count]
    end

    private

    def build_headers(headers, url, raw=false)
      headers = @default_headers.merge(headers)
      headers.merge!('Accept' => "application/json") unless raw
      headers['X-Chef-Version'] = ::Chef::VERSION

      if @cookies.has_key?("#{url.host}:#{url.port}")
        headers['Cookie'] = @cookies["#{url.host}:#{url.port}"]
      end
      headers
    end

    def store_cookie(url, response)
      if response['set-cookie']
        @cookies["#{url.host}:#{url.port}"] = response['set-cookie']
      end
    end

    def http_client_for(url)
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true
        if Chef::Config[:ssl_verify_mode] == :verify_none
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        elsif Chef::Config[:ssl_verify_mode] == :verify_peer
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
        if Chef::Config[:ssl_ca_path] and File.exists?(Chef::Config[:ssl_ca_path])
          http.ca_path = Chef::Config[:ssl_ca_path]
        elsif Chef::Config[:ssl_ca_file] and File.exists?(Chef::Config[:ssl_ca_file])
          http.ca_file = Chef::Config[:ssl_ca_file]
        end
        if Chef::Config[:ssl_client_cert] && File.exists?(Chef::Config[:ssl_client_cert])
          http.cert = OpenSSL::X509::Certificate.new(File.read(Chef::Config[:ssl_client_cert]))
          http.key = OpenSSL::PKey::RSA.new(File.read(Chef::Config[:ssl_client_key]))
        end
      end

      http.read_timeout = Chef::Config[:rest_timeout]

      http
    end

    def http_request_for(url, method, headers={}, body=nil)
      headers["Content-Type"] = 'application/json' if body

      req_path = "#{url.path}"
      req_path << "?#{url.query}" if url.query

      request = case method
      when :GET
        Net::HTTP::Get.new(req_path, headers)
      when :POST
        #headers["Content-Type"] = 'application/json' if body
        Net::HTTP::Post.new(req_path, headers)
        #req.body = body if body
        #req
      when :PUT
        #headers["Content-Type"] = 'application/json' if body
        Net::HTTP::Put.new(req_path, headers)
        #req.body = body if body
        #req
      when :DELETE
        Net::HTTP::Delete.new(req_path, headers)
      else
        raise ArgumentError, "You must provide :GET, :PUT, :POST or :DELETE as the method"
      end

      request.body = body if (body && request.request_body_permitted?)
      # Optionally handle HTTP Basic Authentication
      request.basic_auth(url.user, url.password) if url.user
      request
    end

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
