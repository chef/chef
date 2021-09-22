#
# Author:: Cameron Cope (<ccope@brightcove.com>)
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
require "chef/http/basic_client"

describe "HTTP Connection" do

  let(:uri) { URI("https://example.com:4443") }
  subject(:basic_client) { Chef::HTTP::BasicClient.new(uri) }

  describe ".new" do
    it "creates an instance" do
      subject
    end
  end

  describe "#initialize" do
    it "calls .start when doing keepalives" do
      basic_client = Chef::HTTP::BasicClient.new(uri, keepalives: true)
      expect(basic_client).to receive(:configure_ssl)
      net_http_mock = instance_double(Net::HTTP, proxy_address: nil, "proxy_port=" => nil, "read_timeout=" => nil, "open_timeout=" => nil)
      expect(net_http_mock).to receive(:start).and_return(net_http_mock)
      expect(Net::HTTP).to receive(:new).and_return(net_http_mock)
      expect(basic_client.http_client).to eql(net_http_mock)
    end

    it "does not call .start when not doing keepalives" do
      basic_client = Chef::HTTP::BasicClient.new(uri)
      expect(basic_client).to receive(:configure_ssl)
      net_http_mock = instance_double(Net::HTTP, proxy_address: nil, "proxy_port=" => nil, "read_timeout=" => nil, "open_timeout=" => nil)
      expect(net_http_mock).not_to receive(:start)
      expect(Net::HTTP).to receive(:new).and_return(net_http_mock)
      expect(basic_client.http_client).to eql(net_http_mock)
    end

    it "allows setting net-http accessor options" do
      basic_client = Chef::HTTP::BasicClient.new(uri, nethttp_opts: {
        "continue_timeout" => 5,
        "max_retries" => 5,
        "read_timeout" => 5,
        "write_timeout" => 5,
        "ssl_timeout" => 5,
      })
      expect(basic_client.http_client.continue_timeout).to eql(5)
      expect(basic_client.http_client.max_retries).to eql(5)
      expect(basic_client.http_client.read_timeout).to eql(5)
      expect(basic_client.http_client.write_timeout).to eql(5)
      expect(basic_client.http_client.ssl_timeout).to eql(5)
    end

    it "allows setting net-http accssor options as symbols" do
      basic_client = Chef::HTTP::BasicClient.new(uri, nethttp_opts: {
        continue_timeout: 5,
        max_retries: 5,
        read_timeout: 5,
        write_timeout: 5,
        ssl_timeout: 5,
      })
      expect(basic_client.http_client.continue_timeout).to eql(5)
      expect(basic_client.http_client.max_retries).to eql(5)
      expect(basic_client.http_client.read_timeout).to eql(5)
      expect(basic_client.http_client.write_timeout).to eql(5)
      expect(basic_client.http_client.ssl_timeout).to eql(5)
    end
  end

  describe "#build_http_client" do
    it "should build an http client" do
      subject.build_http_client
    end

    it "should set an open timeout" do
      expect(subject.build_http_client.open_timeout).not_to be_nil
    end
  end

  describe "#proxy_uri" do
    subject(:proxy_uri) { basic_client.proxy_uri }

    it "uses ChefConfig's proxy_uri method" do
      expect(ChefConfig::Config).to receive(:proxy_uri).at_least(:once).with(
        uri.scheme, uri.host, uri.port
      )
      proxy_uri
    end
  end
end
