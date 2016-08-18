#
# Author:: Serdar Sutay (<serdar@chef.io>)
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
require "stringio"

describe Chef::HTTP::ValidateContentLength do
  class TestClient < Chef::HTTP
    use Chef::HTTP::ValidateContentLength
  end

  let(:method) { "GET" }
  let(:url) { "http://dummy.com" }
  let(:headers) { {} }
  let(:data) { false }

  let(:request) {}
  let(:return_value) { "200" }

  # Test Variables
  let(:request_type) { :streaming }
  let(:content_length_value) { 23 }
  let(:streaming_length) { 23 }
  let(:response_body) { "Thanks for checking in." }
  let(:response_headers) do
    {
      "content-length" => content_length_value,
    }
  end

  let(:response) do
    m = double("HttpResponse", :body => response_body)
    allow(m).to receive(:[]) do |key|
      response_headers[key]
    end

    m
  end

  let(:middleware) do
    client = TestClient.new(url)
    client.middlewares[0]
  end

  def run_content_length_validation
    stream_handler = middleware.stream_response_handler(response)
    middleware.handle_request(method, url, headers, data)

    case request_type
    when :streaming
      # First stream the data
      data_length = streaming_length
      while data_length > 0
        chunk_size = data_length > 10 ? 10 : data_length
        stream_handler.handle_chunk(double("Chunk", :bytesize => chunk_size))
        data_length -= chunk_size
      end

      # Finally call stream complete
      middleware.handle_stream_complete(response, request, return_value)
    when :direct
      middleware.handle_response(response, request, return_value)
    else
      raise "Unknown request_type: #{request_type}"
    end
  end

  let(:debug_stream) { StringIO.new }
  let(:debug_output) { debug_stream.string }

  before(:each) do
    @original_log_level = Chef::Log.level
    Chef::Log.level = :debug
    allow(Chef::Log).to receive(:debug) do |message|
      debug_stream.puts message
    end
  end

  after(:each) do
    Chef::Log.level = @original_log_level
  end

  describe "without response body" do
    let(:request_type) { :direct }
    let(:response_body) { "Thanks for checking in." }

    it "shouldn't raise error" do
      expect { run_content_length_validation }.not_to raise_error
    end
  end

  describe "without Content-Length header" do
    let(:response_headers) { {} }

    %w{direct streaming}.each do |req_type|
      describe "when running #{req_type} request" do
        let(:request_type) { req_type.to_sym }

        it "should skip validation and log for debug" do
          run_content_length_validation
          expect(debug_output).to include("HTTP server did not include a Content-Length header in response")
        end
      end
    end
  end

  describe "with negative Content-Length header" do
    let(:content_length_value) { "-1" }

    %w{direct streaming}.each do |req_type|
      describe "when running #{req_type} request" do
        let(:request_type) { req_type.to_sym }

        it "should skip validation and log for debug" do
          run_content_length_validation
          expect(debug_output).to include("HTTP server responded with a negative Content-Length header (-1), cannot identify truncated downloads.")
        end
      end
    end
  end

  describe "with correct Content-Length header" do
    %w{direct streaming}.each do |req_type|
      describe "when running #{req_type} request" do
        let(:request_type) { req_type.to_sym }

        it "should validate correctly" do
          run_content_length_validation
          expect(debug_output).to include("Content-Length validated correctly.")
        end
      end
    end
  end

  describe "with wrong Content-Length header" do
    let(:content_length_value) { 25 }
    %w{direct streaming}.each do |req_type|
      describe "when running #{req_type} request" do
        let(:request_type) { req_type.to_sym }

        it "should raise ContentLengthMismatch error" do
          expect { run_content_length_validation }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
        end
      end
    end
  end

  describe "when download is interrupted" do
    let(:streaming_length) { 12 }

    it "should raise ContentLengthMismatch error" do
      expect { run_content_length_validation }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
    end
  end

  describe "when Transfer-Encoding & Content-Length is set" do
    let(:response_headers) do
      {
        "content-length" => content_length_value,
        "transfer-encoding" => "chunked",
      }
    end

    %w{direct streaming}.each do |req_type|
      describe "when running #{req_type} request" do
        let(:request_type) { req_type.to_sym }

        it "should skip validation and log for debug" do
          run_content_length_validation
          expect(debug_output).to include("Transfer-Encoding header is set, skipping Content-Length check.")
        end
      end
    end
  end

  describe "when client is being reused" do
    before do
      run_content_length_validation
      expect(debug_output).to include("Content-Length validated correctly.")
    end

    it "should reset internal counter" do
      expect(middleware.instance_variable_get(:@content_length_counter)).to be_nil
    end

    it "should validate correctly second time" do
      run_content_length_validation
      expect(debug_output).to include("Content-Length validated correctly.")
    end
  end

end
