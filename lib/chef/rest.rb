#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require 'net/https'
require 'uri'
require 'json'

class Chef
  class REST
    
    def initialize(url)
      @url = url
      @cookies = Hash.new
    end
    
    # Send an HTTP GET request to the path
    def get_rest(path)
      run_request(:GET, create_url(path))    
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
    def run_request(method, url, data=false, limit=10)
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0
      
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true 
        if Chef::Config[:ssl_verify_mode] == :verify_none
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
      http.read_timeout = Chef::Config[:rest_timeout]
      headers = { 
        'Accept' => "application/json",
      }
      if @cookies["#{url.host}:#{url.port}"]
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
      res = http.request(req)
      if res.kind_of?(Net::HTTPSuccess)
        if res['set-cookie']
          @cookies["#{url.host}:#{url.port}"] = res['set-cookie']
        end
        if res['content-type'] == "application/json"
          JSON.parse(res.body)
        else
          res.body
        end
      elsif res.kind_of?(Net::HTTPRedirection)
        if res['set-cookie']
          @cookies["#{url.host}:#{url.port}"] = res['set-cookie']
        end
        run_request(:GET, create_url(res['location']), false, limit - 1)
      else
        res.error!
      end
    end
 
  end
end