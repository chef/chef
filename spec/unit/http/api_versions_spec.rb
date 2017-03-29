#
# Copyright:: Copyright 2017, Chef Software, Inc.
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

describe Chef::HTTP::APIVersions do
  class TestVersionClient < Chef::HTTP
    use Chef::HTTP::APIVersions
  end

  before do
    Chef::ServerAPIVersions.instance.reset!
  end

  let(:method) { "GET" }
  let(:url) { "http://dummy.com" }
  let(:headers) { {} }
  let(:data) { false }

  let(:request) {}
  let(:return_value) { "200" }

  # Test Variables
  let(:response_body) { "Thanks for checking in." }
  let(:response_headers) do
    {
      "x-ops-server-api-version" => { "min_version" => 0, "max_version" => 2 }.to_json,
    }
  end

  let(:response) do
    m = double("HttpResponse", :body => response_body)
    allow(m).to receive(:key?).with("x-ops-server-api-version").and_return(true)
    allow(m).to receive(:code).and_return(return_value)
    allow(m).to receive(:[]) do |key|
      response_headers[key]
    end

    m
  end

  let(:middleware) do
    client = TestVersionClient.new(url)
    client.middlewares[0]
  end

  def run_api_version_handler
    middleware.handle_request(method, url, headers, data)
    middleware.handle_response(response, request, return_value)
  end

  it "correctly stores server api versions" do
    run_api_version_handler
    expect(Chef::ServerAPIVersions.instance.min_server_version).to eq(0)
  end

  context "with an unacceptable api version" do
    let (:return_value) { "406" }
    it "resets the list of supported versions" do
      Chef::ServerAPIVersions.instance.set_versions({ "min_version" => 1, "max_version" => 3 })
      run_api_version_handler
      expect(Chef::ServerAPIVersions.instance.min_server_version).to eq(0)
    end
  end
end
