#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/http/json_input"

describe Chef::HTTP::JSONInput do

  let(:json_encoder) { described_class.new() }

  let(:url) { URI.parse("http://example.com") }
  let(:headers) { {} }

  def handle_request
    json_encoder.handle_request(http_method, url, headers, data)
  end

  it "passes the response unmodified" do
    http_response = double("Net::HTTPSuccess")
    request = double("Chef::HTTP::HTTPRequest")
    return_value = "response body"

    result = json_encoder.handle_response(http_response, request, return_value)
    expect(result).to eq([http_response, request, return_value])
  end

  it "doesn't handle streaming responses" do
    http_response = double("Net::HTTPSuccess")
    expect(json_encoder.stream_response_handler(http_response)).to be nil
  end

  it "does nothing for stream completion" do
    http_response = double("Net::HTTPSuccess")
    request = double("Chef::HTTP::HTTPRequest")
    return_value = "response body"

    result = json_encoder.handle_response(http_response, request, return_value)
    expect(result).to eq([http_response, request, return_value])
  end

  context "when handling a request with no body" do

    let(:http_method) { :get }
    let(:data) { nil }

    it "passes the request unmodified" do
      expect(handle_request).to eq([http_method, url, headers, data])
    end
  end

  context "when the request should be serialized" do

    let(:http_method) { :put }
    let(:data) { { foo: "bar" } }
    let(:expected_data) { %q[{"foo":"bar"}] }

    context "and the request has a ruby object as the body and no explicit content-type" do

      it "serializes the body to json" do
        # Headers Hash get mutated, so we start by asserting it's empty:
        expect(headers).to be_empty

        expect(handle_request).to eq([http_method, url, headers, expected_data])

        # Now the headers Hash should have json content type:
        expect(headers).to have_key("Content-Type")
        expect(headers["Content-Type"]).to eq("application/json")
      end
    end

    context "ant the request has an explicit content type of json" do

      it "serializes the body to json when content-type is all lowercase" do
        headers["content-type"] = "application/json"

        expect(handle_request).to eq([http_method, url, headers, expected_data])

        # Content-Type header should be normalized:
        expect(headers.size).to eq(1)
        expect(headers).to have_key("Content-Type")
        expect(headers["Content-Type"]).to eq("application/json")
      end

    end

  end

  context "when handling a request with an explicit content type other than json" do

    let(:http_method) { :put }
    let(:data) { "some arbitrary bytes" }

    it "does not serialize the body to json when content type is given as lowercase" do
      headers["content-type"] = "application/x-binary"

      expect(handle_request).to eq([http_method, url, headers, data])

      # not normalized
      expect(headers).to eq({ "content-type" => "application/x-binary" })
    end

    it "does not serialize the body to json when content type is given in capitalized form" do
      headers["Content-Type"] = "application/x-binary"

      expect(handle_request).to eq([http_method, url, headers, data])

      # not normalized
      expect(headers).to eq({ "Content-Type" => "application/x-binary" })
    end

  end

end
