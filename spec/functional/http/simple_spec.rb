# frozen_string_literal: true
#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "support/shared/functional/http"

describe Chef::HTTP::Simple do
  include ChefHTTPShared

  let(:http_client) { described_class.new(source) }
  let(:http_client_disable_gzip) { described_class.new(source, { disable_gzip: true } ) }

  before(:all) do
    start_tiny_server(RequestTimeout: 1)
  end

  before(:each) do
    Chef::Config[:rest_timeout] = 2
    Chef::Config[:http_retry_delay] = 1
    Chef::Config[:http_retry_count] = 2
  end

  after(:all) do
    stop_tiny_server
  end

  shared_examples_for "downloads requests correctly" do
    it "successfully downloads a streaming request" do
      tempfile = http_client.streaming_request(source, {})
      tempfile.close
      expect(Digest::MD5.hexdigest(binread(tempfile.path))).to eq(Digest::MD5.hexdigest(expected_content))
    end
    it "successfully does a non-streaming GET request" do
      expect(Digest::MD5.hexdigest(http_client.get(source))).to eq(Digest::MD5.hexdigest(expected_content))
    end
  end

  shared_examples_for "validates content length and throws an exception" do
    it "a streaming request throws a content length exception" do
      expect { http_client.streaming_request(source) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
    end
    it "a non-streaming GET request throws a content length exception" do
      expect { http_client.get(source) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
    end
  end

  shared_examples_for "an endpoint that 403s" do
    it "fails with a Net::HTTPClientException for a streaming request" do
      expect { http_client.streaming_request(source) }.to raise_error(Net::HTTPClientException)
    end

    it "fails with a Net::HTTPClientException for a GET request" do
      expect { http_client.get(source) }.to raise_error(Net::HTTPClientException)
    end
  end

  # see CHEF-5100
  shared_examples_for "a 403 after a successful request when reusing the request object" do
    it "fails with a Net::HTTPClientException for a streaming request" do
      tempfile = http_client.streaming_request(source)
      tempfile.close
      expect(Digest::MD5.hexdigest(binread(tempfile.path))).to eq(Digest::MD5.hexdigest(expected_content))
      expect { http_client.streaming_request(source2) }.to raise_error(Net::HTTPClientException)
    end

    it "fails with a Net::HTTPClientException for a GET request" do
      expect(Digest::MD5.hexdigest(http_client.get(source))).to eq(Digest::MD5.hexdigest(expected_content))
      expect { http_client.get(source2) }.to raise_error(Net::HTTPClientException)
    end
  end

  it_behaves_like "downloading all the things"

  context "when Chef::Log.level = :trace" do
    before do
      Chef::Log.level = :trace
      @debug_log = String.new
      allow(Chef::Log).to receive(:trace) { |str| @debug_log << str }
    end

    let(:source) { "http://localhost:9000" }

    it "Logs the request and response for 200's but not the body" do
      http_client.get("http://localhost:9000/nyan_cat.png")
      expect(@debug_log).to match(/200/)
      expect(@debug_log).to match(/HTTP Request Header Data/)
      expect(@debug_log).to match(/HTTP Status and Header Data/)
      expect(@debug_log).not_to match(/HTTP Request Body/)
      expect(@debug_log).not_to match(/HTTP Response Body/)
      expect(@debug_log).not_to match(/Your request is just terrible./)
    end

    it "Logs the request and response for 200 POST, but not the body" do
      http_client.post("http://localhost:9000/posty", "hithere")
      expect(@debug_log).to match(/200/)
      expect(@debug_log).to match(/HTTP Request Header Data/)
      expect(@debug_log).to match(/HTTP Status and Header Data/)
      expect(@debug_log).not_to match(/HTTP Request Body/)
      expect(@debug_log).not_to match(/hithere/)
      expect(@debug_log).not_to match(/HTTP Response Body/)
      expect(@debug_log).not_to match(/Your request is just terrible./)
    end

    it "Logs the request and response and bodies for 400 response" do
      expect do
        http_client.get("http://localhost:9000/bad_request")
      end.to raise_error(Net::HTTPClientException)
      expect(@debug_log).to match(/400/)
      expect(@debug_log).to match(/HTTP Request Header Data/)
      expect(@debug_log).to match(/HTTP Status and Header Data/)
      expect(@debug_log).not_to match(/HTTP Request Body/)
      expect(@debug_log).not_to match(/hithere/)
      expect(@debug_log).to match(/HTTP Response Body/)
      expect(@debug_log).to match(/Your request is just terrible./)
    end

    it "Logs the request and response and bodies for 400 POST response" do
      expect do
        http_client.post("http://localhost:9000/bad_request", "hithere")
      end.to raise_error(Net::HTTPClientException)
      expect(@debug_log).to match(/400/)
      expect(@debug_log).to match(/HTTP Request Header Data/)
      expect(@debug_log).to match(/HTTP Status and Header Data/)
      expect(@debug_log).to match(/HTTP Request Body/)
      expect(@debug_log).to match(/hithere/)
      expect(@debug_log).to match(/HTTP Response Body/)
      expect(@debug_log).to match(/Your request is just terrible./)
    end
  end
end
