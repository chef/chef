#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'chef/openid_registration'
require 'net/https'
require 'uri'
require 'json'
require 'tempfile'
require 'singleton'

class Chef
  class REST

    class CookieJar < Hash
      include Singleton
    end
    
    attr_accessor :url, :cookies
    
    def initialize(url)
      @url = url
      @cookies = CookieJar.instance
    end
    
    # Register for an OpenID
    def register(user, pass, validation_token=nil)
      Chef::Log.debug("Registering #{user} for an openid") 
      registration = nil
      begin
        registration = get_rest("registrations/#{user}")
      rescue Net::HTTPServerException => e
        unless e.message =~ /^404/
          raise e
        end
      end
      unless registration
        post_rest(
          "registrations", 
          { 
            :id => user, 
            :password => pass, 
            :validation_token => validation_token 
          }
        )
      end
    end
    
    # Authenticate 
    def authenticate(user, pass)
      Chef::Log.debug("Authenticating #{user} via openid") 
      response = post_rest('openid/consumer/start', { 
        "openid_identifier" => "#{Chef::Config[:openid_url]}/openid/server/node/#{user}",
        "submit" => "Verify"
      })
      post_rest(
        "#{Chef::Config[:openid_url]}#{response["action"]}",
        { "password" => pass }
      )
    end

    # Send an HTTP GET request to the path
    #
    # === Parameters
    # path:: The path to GET
    # raw:: Whether you want the raw body returned, or JSON inflated.  Defaults 
    #   to JSON inflated.
    def get_rest(path, raw=false)
      run_request(:GET, create_url(path), false, 10, raw)    
    end                               
                          
    # Send an HTTP DELETE request to the path
    def delete_rest(path)             
      run_request(:DELETE, create_url(path))       
    end                               
    
    # Send an HTTP POST request to the path                                  
    def post_rest(path, json)          
      run_request(:POST, create_url(path), json)    
    end                               
                                      
    # Send an HTTP PUT request to the path
    def put_rest(path, json)           
      run_request(:PUT, create_url(path), json)
    end
    
    def create_url(path)
      if path =~ /^(http|https):\/\//
        URI.parse(path)
      else
        URI.parse("#{@url}/#{path}")
      end
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
    def run_request(method, url, data=false, limit=10, raw=false)
      http_retry_delay = Chef::Config[:http_retry_delay] 
      http_retry_count = Chef::Config[:http_retry_count]

      raise ArgumentError, 'HTTP redirect too deep' if limit == 0 

      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true 
        if Chef::Config[:ssl_verify_mode] == :verify_none
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        if File.exists?(Chef::Config[:ssl_client_cert])
          http.cert = OpenSSL::X509::Certificate.new(File.read(Chef::Config[:ssl_client_cert]))
          http.key = OpenSSL::PKey::RSA.new(File.read(Chef::Config[:ssl_client_key]))
        end
      end
      http.read_timeout = Chef::Config[:rest_timeout]
      headers = Hash.new
      unless raw
        headers = { 
          'Accept' => "application/json",
        }
      end
      if @cookies.has_key?("#{url.host}:#{url.port}")
        headers['Cookie'] = @cookies["#{url.host}:#{url.port}"]
      end
      req = nil
      case method
      when :GET
        req_path = "#{url.path}"
        req_path << "?#{url.query}" if url.query
        req = Net::HTTP::Get.new(req_path, headers)
      when :POST
        headers["Content-Type"] = 'application/json' if data
        req = Net::HTTP::Post.new(url.path, headers)          
        req.body = data.to_json if data
      when :PUT
        headers["Content-Type"] = 'application/json' if data
        req = Net::HTTP::Put.new(url.path, headers)
        req.body = data.to_json if data
      when :DELETE
        req_path = "#{url.path}"
        req_path << "?#{url.query}" if url.query
        req = Net::HTTP::Delete.new(req_path, headers)
      else
        raise ArgumentError, "You must provide :GET, :PUT, :POST or :DELETE as the method"
      end
      
      # Optionally handle HTTP Basic Authentication
      req.basic_auth(url.user, url.password) if url.user

      Chef::Log.debug("Sending HTTP Request via #{req.method} to #{req.path}")
      res = nil
      tf = nil
      http_retries = 1

      begin
        res = http.request(req) do |response|
          if raw
            tf = Tempfile.new("chef-rest") 
            # Stolen from http://www.ruby-forum.com/topic/166423
            # Kudos to _why!
            size, total = 0, response.header['Content-Length'].to_i
            response.read_body do |chunk|
              tf.write(chunk) 
              size += chunk.size
              if size == 0
                Chef::Log.debug("#{req.path} done (0 length file)")
              elsif total == 0
                Chef::Log.debug("#{req.path} (zero content length)")
              else
                Chef::Log.debug("#{req.path}" + " %d%% done (%d of %d)" % [(size * 100) / total, size, total])
              end
            end
            tf.close 
            tf
          else
            response.read_body
          end
          response
        end
      rescue Errno::ECONNREFUSED
        Chef::Log.error("Connection refused connecting to #{url.host}:#{url.port} for #{req.path} #{http_retries}/#{http_retry_count}")
        sleep(http_retry_delay)
        retry if (http_retries += 1) < http_retry_count
        raise Errno::ECONNREFUSED, "Connection refused connecting to #{url.host}:#{url.port} for #{req.path}, giving up"
      rescue Timeout::Error
        Chef::Log.error("Timeout connecting to #{url.host}:#{url.port} for #{req.path}, retry #{http_retries}/#{http_retry_count}")
        sleep(http_retry_delay)
        retry if (http_retries += 1) < http_retry_count
        raise Timeout::Error, "Timeout connecting to #{url.host}:#{url.port} for #{req.path}, giving up"
      end
      
      if res.kind_of?(Net::HTTPSuccess)
        if res['set-cookie']
          @cookies["#{url.host}:#{url.port}"] = res['set-cookie']
        end
        if res['content-type'] =~ /json/
          JSON.parse(res.body)
        else
          if raw
            tf
          else
            res.body
          end
        end
      elsif res.kind_of?(Net::HTTPFound) or res.kind_of?(Net::HTTPMovedPermanently)
        if res['set-cookie']
          @cookies["#{url.host}:#{url.port}"] = res['set-cookie']
        end
        run_request(:GET, create_url(res['location']), false, limit - 1, raw)
      else
        res.error!
      end
    end
 
  end
end
