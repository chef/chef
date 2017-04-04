#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/http/socketless_chef_zero_client"

describe Chef::HTTP::SocketlessChefZeroClient do

  let(:relative_url) { "" }
  let(:uri_str) { "chefzero://localhost:1/#{relative_url}" }
  let(:uri) { URI(uri_str) }

  subject(:zero_client) { Chef::HTTP::SocketlessChefZeroClient.new(uri) }

  it "has a host" do
    expect(zero_client.host).to eq("localhost")
  end

  it "has a port" do
    expect(zero_client.port).to eq(1)
  end

  describe "converting requests to rack format" do

    let(:expected_rack_req) do
      {
        "SCRIPT_NAME"     => "",
        "SERVER_NAME"     => "localhost",
        "REQUEST_METHOD"  => method.to_s.upcase,
        "PATH_INFO"       => uri.path,
        "QUERY_STRING"    => uri.query,
        "SERVER_PORT"     => uri.port,
        "HTTP_HOST"       => "localhost:#{uri.port}",
        "rack.url_scheme" => "chefzero",
      }
    end

    context "when the request has no body" do

      let(:method) { :GET }
      let(:relative_url) { "clients" }
      let(:headers) { { "Accept" => "application/json" } }
      let(:body) { false }
      let(:expected_body_str) { "" }

      let(:rack_req) { zero_client.req_to_rack(method, uri, body, headers) }

      it "creates a rack request env" do
        # StringIO doesn't implement == in a way that we can compare, so we
        # check rack.input individually and then iterate over everything else
        expect(rack_req["rack.input"].string).to eq(expected_body_str)
        expected_rack_req.each do |key, value|
          expect(rack_req[key]).to eq(value)
        end
      end

    end

    context "when the request has a body" do

      let(:method) { :PUT }
      let(:relative_url) { "clients/foo" }
      let(:headers) { { "Accept" => "application/json" } }
      let(:body) { "bunch o' JSON" }
      let(:expected_body_str) { "bunch o' JSON" }

      let(:rack_req) { zero_client.req_to_rack(method, uri, body, headers) }

      it "creates a rack request env" do
        # StringIO doesn't implement == in a way that we can compare, so we
        # check rack.input individually and then iterate over everything else
        expect(rack_req["rack.input"].string).to eq(expected_body_str)
        expected_rack_req.each do |key, value|
          expect(rack_req[key]).to eq(value)
        end
      end

    end

  end

  describe "converting responses to Net::HTTP objects" do

    let(:net_http_response) { zero_client.to_net_http(code, headers, body) }

    context "when the request was successful (2XX)" do

      let(:code) { 200 }
      let(:headers) { { "Content-Type" => "Application/JSON" } }
      let(:body) { [ "bunch o' JSON" ] }

      it "creates a Net::HTTP success response object" do
        expect(net_http_response).to be_a_kind_of(Net::HTTPOK)
        expect(net_http_response.read_body).to eq("bunch o' JSON")
        expect(net_http_response["content-type"]).to eq("Application/JSON")
      end

      it "does not fail when calling read_body with a block" do
        expect(net_http_response.read_body { |chunk| chunk }).to eq("bunch o' JSON")
      end

    end

    context "when the requested object doesn't exist (404)" do

      let(:code) { 404 }
      let(:headers) { { "Content-Type" => "Application/JSON" } }
      let(:body) { [ "nope" ] }

      it "creates a Net::HTTPNotFound response object" do
        expect(net_http_response).to be_a_kind_of(Net::HTTPNotFound)
      end
    end

  end

  describe "request-response round trip" do

    let(:method) { :GET }
    let(:relative_url) { "clients" }
    let(:headers) { { "Accept" => "application/json", "X-Ops-Server-API-Version" => "2" } }
    let(:body) { false }

    let(:expected_rack_req) do
      {
        "SCRIPT_NAME"     => "",
        "SERVER_NAME"     => "localhost",
        "REQUEST_METHOD"  => method.to_s.upcase,
        "PATH_INFO"       => uri.path,
        "QUERY_STRING"    => uri.query,
        "SERVER_PORT"     => uri.port,
        "HTTP_HOST"       => "localhost:#{uri.port}",
        "HTTP_X_OPS_SERVER_API_VERSION" => "2",
        "rack.url_scheme" => "chefzero",
        "rack.input"      => an_instance_of(StringIO),
      }
    end

    let(:response_code) { 200 }
    let(:response_headers) { { "Content-Type" => "Application/JSON" } }
    let(:response_body) { [ "bunch o' JSON" ] }

    let(:rack_response) { [ response_code, response_headers, response_body ] }

    let(:response) { zero_client.request(method, uri, body, headers) }

    before do
      expect(ChefZero::SocketlessServerMap).to receive(:request).with(1, expected_rack_req).and_return(rack_response)
    end

    it "makes a rack request to Chef Zero and returns the response as a Net::HTTP object" do
      _client, net_http_response = response
      expect(net_http_response).to be_a_kind_of(Net::HTTPOK)
      expect(net_http_response.code).to eq("200")
      expect(net_http_response.body).to eq("bunch o' JSON")
    end

  end

end
