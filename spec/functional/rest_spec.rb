#
# Author:: Lamont Granquist (<lamont@chef.io>)
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
require "tiny_server"
require "support/shared/functional/http"

describe Chef::REST do
  include ChefHTTPShared

  let(:http_client) { described_class.new(source) }
  let(:http_client_disable_gzip) { described_class.new(source, Chef::Config[:node_name], Chef::Config[:client_key], { :disable_gzip => true } ) }

  shared_examples_for "downloads requests correctly" do
    it "successfully downloads a streaming request" do
      tempfile = http_client.streaming_request(source, {})
      tempfile.close
      expect(Digest::MD5.hexdigest(binread(tempfile.path))).to eq(Digest::MD5.hexdigest(expected_content))
    end

    it "successfully downloads a GET request" do
      tempfile = http_client.get(source, {})
      tempfile.close
      expect(Digest::MD5.hexdigest(binread(tempfile.path))).to eq(Digest::MD5.hexdigest(expected_content))
    end
  end

  shared_examples_for "validates content length and throws an exception" do
    it "fails validation on a streaming download" do
      expect { http_client.streaming_request(source, {}) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
    end

    it "fails validation on a GET request" do
      expect { http_client.get(source, {}) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
    end
  end

  shared_examples_for "an endpoint that 403s" do
    it "fails with a Net::HTTPServerException on a streaming download" do
      expect { http_client.streaming_request(source, {}) }.to raise_error(Net::HTTPServerException)
    end

    it "fails with a Net::HTTPServerException on a GET request" do
      expect { http_client.get(source, {}) }.to raise_error(Net::HTTPServerException)
    end
  end

  # see CHEF-5100
  shared_examples_for "a 403 after a successful request when reusing the request object" do
    it "fails with a Net::HTTPServerException on a streaming download" do
      tempfile = http_client.streaming_request(source, {})
      tempfile.close
      expect(Digest::MD5.hexdigest(binread(tempfile.path))).to eq(Digest::MD5.hexdigest(expected_content))
      expect { http_client.streaming_request(source2, {}) }.to raise_error(Net::HTTPServerException)
    end

    it "fails with a Net::HTTPServerException on a GET request" do
      tempfile = http_client.get(source, {})
      tempfile.close
      expect(Digest::MD5.hexdigest(binread(tempfile.path))).to eq(Digest::MD5.hexdigest(expected_content))
      expect { http_client.get(source2, {}) }.to raise_error(Net::HTTPServerException)
    end
  end

  before do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    Chef::Config[:treat_deprecation_warnings_as_errors] = false
  end

  before(:all) do
    start_tiny_server
  end

  after(:all) do
    stop_tiny_server
  end

  it_behaves_like "downloading all the things"
end
