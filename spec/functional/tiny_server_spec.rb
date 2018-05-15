#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

require "spec_helper"
require "tiny_server"

describe TinyServer::API do
  before do
    @api = TinyServer::API.instance
    @api.clear
  end

  it "is a Singleton" do
    expect { TinyServer::API.new }.to raise_error NoMethodError
  end

  it "clears the router" do
    @api.get("/blargh", 200, "blargh")
    @api.clear
    expect(@api.routes["GET"]).to be_empty
  end

  it "creates a route for a GET request" do
    @api.get("/foo/bar", 200, "hello foobar")
    # WEBrick gives you the full URI with host, Thin only gave the part after scheme+host+port
    response = @api.call("REQUEST_METHOD" => "GET", "REQUEST_URI" => "http://localhost:1974/foo/bar")
    expect(response).to eq([200, { "Content-Type" => "application/json" }, [ "hello foobar" ]])
  end

  it "creates a route for a request with a block" do
    block_called = false
    @api.get("/bar/baz", 200) { block_called = true; "hello barbaz" }
    response = @api.call("REQUEST_METHOD" => "GET", "REQUEST_URI" => "http://localhost:1974/bar/baz")
    expect(response).to eq([200, { "Content-Type" => "application/json" }, [ "hello barbaz" ]])
    expect(block_called).to be_truthy
  end

  it "returns debugging info for 404s" do
    response = @api.call("REQUEST_METHOD" => "GET", "REQUEST_URI" => "/no_such_thing")
    expect(response[0]).to eq(404)
    expect(response[1]).to eq({ "Content-Type" => "application/json" })
    expect(response[2]).to be_a_kind_of(Array)
    response_obj = Chef::JSONCompat.from_json(response[2].first)
    expect(response_obj["message"]).to eq("no data matches the request for /no_such_thing")
    expect(response_obj["available_routes"]).to eq({ "GET" => [], "PUT" => [], "POST" => [], "DELETE" => [] })
    expect(response_obj["request"]).to eq({ "REQUEST_METHOD" => "GET", "REQUEST_URI" => "/no_such_thing" })
  end

end

describe TinyServer::Manager do
  it "runs the server" do
    server = TinyServer::Manager.new
    server.start
    begin
      TinyServer::API.instance.get("/index", 200, "[\"hello\"]")

      rest = Chef::HTTP.new("http://localhost:9000")
      expect(rest.get("index")).to eq("[\"hello\"]")
    ensure
      server.stop
    end
  end
end
