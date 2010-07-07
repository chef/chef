#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'rubygems'
require 'rack'
require 'thin'
require 'singleton'
require 'json'
require 'open-uri'

module TinyServer

  class Server < Rack::Server

    attr_writer :app

    def self.run(options=nil, &block)
      tiny_app = new(options)
      app_code = Rack::Builder.new(&block).to_app
      tiny_app.app = app_code
      tiny_app.start
    end
  end

  class Manager

    DEFAULT_OPTIONS = {:server => 'thin', :Port => 9000, :Host => 'localhost', :environment => :none}

    def initialize(options=nil)
      @options = options ? DEFAULT_OPTIONS.merge(options) : DEFAULT_OPTIONS
      @creator = caller.first
    end

    def start
      @server_thread = Thread.new do
        @server = Server.run(@options) do
          run API.instance
        end
      end
      block_until_started
    end

    def url
      "http://localhost:#{@options[:Port]}"
    end

    def block_until_started
      20.times do
        return true if started?
      end
      raise "TinyServer failed to boot :/"
    end

    def started?
      open(url)
      true
    rescue OpenURI::HTTPError
      true
    rescue Errno::ECONNREFUSED => e
      sleep 0.1
      false
    end

    def stop
      # yes, this is terrible.
      @server_thread.kill
      @server_thread.join
      @server_thread = nil
    end

  end

  class API
    include Singleton

    GET     = "GET"
    PUT     = "PUT"
    POST    = "POST"
    DELETE  = "DELETE"

    attr_reader :api_data

    def initialize
      clear
    end

    def clear
      @api_data = {GET => [], PUT => [], POST => [], DELETE => []}
    end

    def get(path, response_code, data=nil, &block)
      @api_data[GET] << [path, Response.new(response_code,data, &block)]
    end

    def put(path, response_code, data=nil, &block)
      @api_data[PUT] << [path, Response.new(response_code,data, &block)]
    end

    def post(path, response_code, data=nil, &block)
      @api_data[POST] << [path, Response.new(response_code,data, &block)]
    end

    def delete(path, response_code, data=nil, &block)
      @api_data[DELETE] << [path, Response.new(response_code,data, &block)]
    end

    def call(env)
      if response = response_for_request(env)
        response.call
      else
        debug_info = {:message => "no data matches the request for #{env['REQUEST_URI']}",
                      :available_data => @api_data, :request => env}
        [404, {'Content-Type' => 'application/json'}, debug_info.to_json]
      end
    end

    def response_for_request(env)
      if route_tuple = @api_data[env["REQUEST_METHOD"]].find { |route, response| route === env["REQUEST_URI"] }
        route_tuple[1]
      end
    end
  end

  class Response
    HEADERS = {'Content-Type' => 'application/json'}

    def initialize(response_code=200,data=nil, &block)
      @response_code, @data = response_code, data
      @block = block_given? ? block : nil
    end

    def call
      data = @data || @block.call
      [@response_code, HEADERS, data]
    end
  end

end
