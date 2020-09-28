#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "webrick"
require "webrick/https"
require "rack"
require "singleton"
require "open-uri"
require "chef/config"

module TinyServer

  class Manager

    # 5 == debug, 3 == warning
    LOGGER = WEBrick::Log.new(STDOUT, 3)
    DEFAULT_OPTIONS = {
      Port: 9000,
      Host: "localhost",
      Logger: LOGGER,
      # SSLEnable: options[:ssl],
      # SSLCertName: [ [ 'CN', WEBrick::Utils::getservername ] ],
      AccessLog: [], # Remove this option to enable the access log when debugging.
    }.freeze

    def initialize(**options)
      @options = DEFAULT_OPTIONS.merge(options)
      @creator = caller.first
    end

    attr_reader :options
    attr_reader :creator
    attr_reader :server

    def start(timeout = 5)
      raise "Server already started!" if server

      # Create the server (but don't start yet)
      start_queue = Queue.new
      @server = create_server(StartCallback: proc { start_queue << true })

      @server_thread = Thread.new do
        # Ensure any exceptions will cause the main rspec thread to fail too
        Thread.current.abort_on_exception = true
        server.start
      end

      # Wait for the StartCallback to tell us we've started
      Timeout.timeout(timeout) do
        start_queue.pop
      end
    end

    def stop(timeout = 5)
      if server
        server.shutdown
        @server = nil
      end

      if server_thread
        begin
          # Wait for a normal shutdown
          server_thread.join(timeout)
        rescue
          # If it wouldn't shut down normally, kill it.
          server_thread.kill
          server_thread.join(timeout)
        end
        @server_thread = nil
      end
    end

    private

    attr_reader :server_thread

    def create_server(**extra_options)
      server = WEBrick::HTTPServer.new(**options, **extra_options)
      server.mount("/", Rack::Handler::WEBrick, API.instance)
      server
    end
  end

  class API
    include Singleton

    GET     = "GET".freeze
    PUT     = "PUT".freeze
    POST    = "POST".freeze
    DELETE  = "DELETE".freeze

    attr_reader :routes

    def initialize
      clear
    end

    def clear
      @routes = { GET => [], PUT => [], POST => [], DELETE => [] }
    end

    def get(path, response_code, data = nil, headers = nil, &block)
      @routes[GET] << Route.new(path, Response.new(response_code, data, headers, &block))
    end

    def put(path, response_code, data = nil, headers = nil, &block)
      @routes[PUT] << Route.new(path, Response.new(response_code, data, headers, &block))
    end

    def post(path, response_code, data = nil, headers = nil, &block)
      @routes[POST] << Route.new(path, Response.new(response_code, data, headers, &block))
    end

    def delete(path, response_code, data = nil, headers = nil, &block)
      @routes[DELETE] << Route.new(path, Response.new(response_code, data, headers, &block))
    end

    def call(env)
      if response = response_for_request(env)
        response.call
      else
        debug_info = { message: "no data matches the request for #{env["REQUEST_URI"]}",
                       available_routes: @routes, request: env }
        # Uncomment me for glorious debugging
        # pp :not_found => debug_info
        [404, { "Content-Type" => "application/json" }, [ Chef::JSONCompat.to_json(debug_info) ]]
      end
    end

    def response_for_request(env)
      if route = @routes[env["REQUEST_METHOD"]].find { |route| route.matches_request?(env["REQUEST_URI"]) }
        route.response
      end
    end
  end

  class Route
    attr_reader :response

    def initialize(path_spec, response)
      @path_spec, @response = path_spec, response
    end

    def matches_request?(uri)
      uri = URI.parse(uri).request_uri
      @path_spec === uri
    end

    def to_s
      "#{@path_spec} => (#{@response})"
    end

  end

  class Response
    HEADERS = { "Content-Type" => "application/json" }.freeze

    def initialize(response_code = 200, data = nil, headers = nil, &block)
      @response_code, @data = response_code, data
      @response_headers = headers ? HEADERS.merge(headers) : HEADERS
      @block = block_given? ? block : nil
    end

    def call
      data = @data || @block.call
      [@response_code, @response_headers, Array(data)]
    end

    def to_s
      "#{@response_code} => #{(@data || @block)}"
    end

  end

end
