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

require 'spec_helper'
require 'tiny_server'

describe TinyServer::API do
  before do
    @api = TinyServer::API.instance
    @api.clear
  end

  it "is a Singleton" do
    lambda {TinyServer::API.new}.should raise_error
  end

  it "clears the router" do
    @api.get('/blargh', 200, "blargh")
    @api.clear
    @api.routes["GET"].should be_empty
  end

  it "creates a route for a GET request" do
    @api.get('/foo/bar', 200, 'hello foobar')
    # WEBrick gives you the full URI with host, Thin only gave the part after scheme+host+port
    response = @api.call("REQUEST_METHOD" => "GET", "REQUEST_URI" => 'http://localhost:1974/foo/bar')
    response.should == [200, {'Content-Type' => 'application/json'}, [ 'hello foobar' ]]
  end

  it "creates a route for a request with a block" do
    block_called = false
    @api.get('/bar/baz', 200) { block_called = true; 'hello barbaz' }
    response = @api.call("REQUEST_METHOD" => "GET", "REQUEST_URI" => 'http://localhost:1974/bar/baz')
    response.should == [200, {'Content-Type' => 'application/json'}, [ 'hello barbaz' ]]
    block_called.should be_true
  end

  it "returns debugging info for 404s" do
    response = @api.call("REQUEST_METHOD" => "GET", "REQUEST_URI" => '/no_such_thing')
    response[0].should == 404
    response[1].should == {'Content-Type' => 'application/json'}
    response[2].should be_a_kind_of(String)
    response_obj = Chef::JSONCompat.from_json(response[2])
    response_obj["message"].should == "no data matches the request for /no_such_thing"
    response_obj["available_routes"].should == {"GET"=>[], "PUT"=>[], "POST"=>[], "DELETE"=>[]}
    response_obj["request"].should == {"REQUEST_METHOD"=>"GET", "REQUEST_URI"=>"/no_such_thing"}
  end

end

describe TinyServer::Manager do
  it "runs the server" do
    @server = TinyServer::Manager.new
    @server.start

    TinyServer::API.instance.get("/index", 200, "[\"hello\"]")

    rest = Chef::REST.new('http://localhost:9000', false, false)
    rest.get_rest("index").should == ["hello"]

    @server.stop
  end
end
