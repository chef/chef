#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright 2014-2016, Onddo Labs, SL.
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

require "chef/http"
require "chef/http/basic_client"
require "chef/http/socketless_chef_zero_client"

class Chef::HTTP
  public :create_url
end

describe Chef::HTTP do

  let(:uri) { "https://chef.example/organizations/default/" }

  context "when given a chefzero:// URL" do

    let(:uri) { URI("chefzero://localhost:1") }

    subject(:http) { Chef::HTTP.new(uri) }

    it "uses the SocketlessChefZeroClient to handle requests" do
      expect(http.http_client).to be_a_kind_of(Chef::HTTP::SocketlessChefZeroClient)
      expect(http.http_client.url).to eq(uri)
    end

  end

  describe "#intialize" do
    it "accepts a keepalive option and passes it to the http_client" do
      http = Chef::HTTP.new(uri, keepalives: true)
      expect(Chef::HTTP::BasicClient).to receive(:new).with(uri, ssl_policy: Chef::HTTP::APISSLPolicy, keepalives: true).and_call_original
      expect(http.http_client).to be_a_kind_of(Chef::HTTP::BasicClient)
    end

    it "the default is not to use keepalives" do
      http = Chef::HTTP.new(uri)
      expect(Chef::HTTP::BasicClient).to receive(:new).with(uri, ssl_policy: Chef::HTTP::APISSLPolicy, keepalives: false).and_call_original
      expect(http.http_client).to be_a_kind_of(Chef::HTTP::BasicClient)
    end
  end

  describe "create_url" do

    it "should return a correctly formatted url 1/3 CHEF-5261" do
      http = Chef::HTTP.new("http://www.getchef.com")
      expect(http.create_url("api/endpoint")).to eql(URI.parse("http://www.getchef.com/api/endpoint"))
    end

    it "should return a correctly formatted url 2/3 CHEF-5261" do
      http = Chef::HTTP.new("http://www.getchef.com/")
      expect(http.create_url("/organization/org/api/endpoint/")).to eql(URI.parse("http://www.getchef.com/organization/org/api/endpoint/"))
    end

    it "should return a correctly formatted url 3/3 CHEF-5261" do
      http = Chef::HTTP.new("http://www.getchef.com/organization/org///")
      expect(http.create_url("///api/endpoint?url=http://foo.bar")).to eql(URI.parse("http://www.getchef.com/organization/org/api/endpoint?url=http://foo.bar"))
    end

    # As per: https://github.com/chef/chef/issues/2500
    it "should treat scheme part of the URI in a case-insensitive manner" do
      http = Chef::HTTP.allocate # Calling Chef::HTTP::new sets @url, don't want that.
      expect { http.create_url("HTTP://www1.chef.io/") }.not_to raise_error
      expect(http.create_url("HTTP://www2.chef.io/")).to eql(URI.parse("http://www2.chef.io/"))
    end

  end # create_url

  describe "#stream_to_tempfile" do

    it "should only close an existing Tempfile" do
      resp = Net::HTTPOK.new("1.1", 200, "OK")
      http = Chef::HTTP.new(uri)
      expect(Tempfile).to receive(:open).and_raise("TestError")
      expect_any_instance_of(Tempfile).not_to receive(:close!)
      expect { http.send(:stream_to_tempfile, uri, resp) }.to raise_error("TestError")
    end

  end

  describe "head" do

    it 'should return nil for a "200 Success" response (CHEF-4762)' do
      resp = Net::HTTPOK.new("1.1", 200, "OK")
      expect(resp).to receive(:read_body).and_return(nil)
      http = Chef::HTTP.new("")
      expect_any_instance_of(Chef::HTTP::BasicClient).to receive(:request).and_return(["request", resp])

      expect(http.head("http://www.getchef.com/")).to eql(nil)
    end

    it 'should return false for a "304 Not Modified" response (CHEF-4762)' do
      resp = Net::HTTPNotModified.new("1.1", 304, "Not Modified")
      expect(resp).to receive(:read_body).and_return(nil)
      http = Chef::HTTP.new("")
      expect_any_instance_of(Chef::HTTP::BasicClient).to receive(:request).and_return(["request", resp])

      expect(http.head("http://www.getchef.com/")).to eql(false)
    end

  end # head

  describe "retrying connection errors" do

    subject(:http) { Chef::HTTP.new(uri) }

    # http#http_client gets stubbed later, so eager create
    let!(:low_level_client) { http.http_client(URI(uri)) }

    let(:http_ok_response) do
      Net::HTTPOK.new("1.1", 200, "OK").tap do |r|
        allow(r).to receive(:read_body).and_return("")
      end
    end

    before do
      allow(http).to receive(:http_client).with(URI(uri)).and_return(low_level_client)
    end

    shared_examples_for "retriable_request_errors" do

      before do
        expect(low_level_client).to receive(:request).exactly(5).times.and_raise(exception)
        expect(http).to receive(:sleep).exactly(5).times.and_return(1)
        expect(low_level_client).to receive(:request).and_return([low_level_client, http_ok_response])
      end

      it "retries the request 5 times" do
        http.get("/")
      end

    end

    shared_examples_for "errors_that_are_not_retried" do

      before do
        expect(low_level_client).to receive(:request).exactly(1).times.and_raise(exception)
        expect(http).to_not receive(:sleep)
      end

      it "raises the error without retrying or sleeping" do
        # We modify the strings to give addtional context, but the exception class should be the same
        expect { http.get("/") }.to raise_error(exception.class)
      end
    end

    context "when ECONNRESET is raised" do

      let(:exception) { Errno::ECONNRESET.new("example error") }

      include_examples "retriable_request_errors"

    end

    context "when SocketError is raised" do

      let(:exception) { SocketError.new("example error") }

      include_examples "retriable_request_errors"

    end

    context "when ETIMEDOUT is raised" do

      let(:exception) { Errno::ETIMEDOUT.new("example error") }

      include_examples "retriable_request_errors"

    end

    context "when ECONNREFUSED is raised" do

      let(:exception) { Errno::ECONNREFUSED.new("example error") }

      include_examples "retriable_request_errors"

    end

    context "when Timeout::Error is raised" do

      let(:exception) { Timeout::Error.new("example error") }

      include_examples "retriable_request_errors"

    end

    context "when OpenSSL::SSL::SSLError is raised" do

      let(:exception) { OpenSSL::SSL::SSLError.new("example error") }

      include_examples "retriable_request_errors"

    end

    context "when OpenSSL::SSL::SSLError is raised for certificate validation failure" do

      let(:exception) { OpenSSL::SSL::SSLError.new("ssl_connect returned=1 errno=0 state=sslv3 read server certificate b: certificate verify failed") }

      include_examples "errors_that_are_not_retried"

    end
  end
end
