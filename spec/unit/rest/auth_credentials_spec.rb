#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "uri"
require "net/https"

describe Chef::REST::AuthCredentials do
  before do
    @key_file_fixture = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    @key = OpenSSL::PKey::RSA.new(IO.read(@key_file_fixture).strip)
    @auth_credentials = Chef::REST::AuthCredentials.new("client-name", @key)
  end

  it "has a client name" do
    expect(@auth_credentials.client_name).to eq("client-name")
  end

  it "loads the private key when initialized with the path to the key" do
    expect(@auth_credentials.key).to respond_to(:private_encrypt)
    expect(@auth_credentials.key).to eq(@key)
  end

  describe "when loading the private key" do
    it "strips extra whitespace before checking the key" do
      key_file_fixture = CHEF_SPEC_DATA + "/ssl/private_key_with_whitespace.pem"
      expect { Chef::REST::AuthCredentials.new("client-name", @key_file_fixture) }.not_to raise_error
    end
  end

  describe "generating signature headers for a request" do
    before do
      @request_time = Time.at(1270920860)
      @request_params = { :http_method => :POST, :path => "/clients", :body => '{"some":"json"}', :host => "localhost" }
      allow(Chef::Config).to(
        receive(:[]).with(:authentication_protocol_version).and_return(protocol_version))
    end

    context "when configured for version 1.0 of the authn protocol" do
      let(:protocol_version) { "1.0" }

      it "generates signature headers for the request" do
        allow(Time).to receive(:now).and_return(@request_time)
        actual = @auth_credentials.signature_headers(@request_params)
        expect(actual["HOST"]).to eq("localhost")
        expect(actual["X-OPS-AUTHORIZATION-1"]).to eq("kBssX1ENEwKtNYFrHElN9vYGWS7OeowepN9EsYc9csWfh8oUovryPKDxytQ/")
        expect(actual["X-OPS-AUTHORIZATION-2"]).to eq("Wc2/nSSyxdWJjjfHzrE+YrqNQTaArOA7JkAf5p75eTUonCWcvNPjFrZVgKGS")
        expect(actual["X-OPS-AUTHORIZATION-3"]).to eq("yhzHJQh+lcVA9wwARg5Hu9q+ddS8xBOdm3Vp5atl5NGHiP0loiigMYvAvzPO")
        expect(actual["X-OPS-AUTHORIZATION-4"]).to eq("r9853eIxwYMhn5hLGhAGFQznJbE8+7F/lLU5Zmk2t2MlPY8q3o1Q61YD8QiJ")
        expect(actual["X-OPS-AUTHORIZATION-5"]).to eq("M8lIt53ckMyUmSU0DDURoiXLVkE9mag/6Yq2tPNzWq2AdFvBqku9h2w+DY5k")
        expect(actual["X-OPS-AUTHORIZATION-6"]).to eq("qA5Rnzw5rPpp3nrWA9jKkPw4Wq3+4ufO2Xs6w7GCjA==")
        expect(actual["X-OPS-CONTENT-HASH"]).to eq("1tuzs5XKztM1ANrkGNPah6rW9GY=")
        expect(actual["X-OPS-SIGN"]).to         match(%r{(version=1\.0)|(algorithm=sha1;version=1.0;)})
        expect(actual["X-OPS-TIMESTAMP"]).to    eq("2010-04-10T17:34:20Z")
        expect(actual["X-OPS-USERID"]).to       eq("client-name")
      end
    end

    context "when configured for version 1.1 of the authn protocol" do
      let(:protocol_version) { "1.1" }

      it "generates the correct signature for version 1.1" do
        allow(Time).to receive(:now).and_return(@request_time)
        actual = @auth_credentials.signature_headers(@request_params)
        expect(actual["HOST"]).to eq("localhost")
        expect(actual["X-OPS-CONTENT-HASH"]).to eq("1tuzs5XKztM1ANrkGNPah6rW9GY=")
        expect(actual["X-OPS-SIGN"]).to         eq("algorithm=sha1;version=1.1;")
        expect(actual["X-OPS-TIMESTAMP"]).to    eq("2010-04-10T17:34:20Z")
        expect(actual["X-OPS-USERID"]).to       eq("client-name")

        # mixlib-authN will test the actual signature stuff for each version of
        # the protocol so we won't test it again here.
      end
    end
  end
end

describe Chef::REST::RESTRequest do
  let(:url) { URI.parse("http://chef.example.com:4000/?q=chef_is_awesome") }

  def new_request(method = nil)
    method ||= :POST
    Chef::REST::RESTRequest.new(method, url, @req_body, @headers)
  end

  before do
    @auth_credentials = Chef::REST::AuthCredentials.new("client-name", CHEF_SPEC_DATA + "/ssl/private_key.pem")
    @req_body = '{"json_data":"as_a_string"}'
    @headers = { "Content-type" => "application/json",
                 "Accept" => "application/json",
                 "Accept-Encoding" => Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE,
                 "Host" => "chef.example.com:4000" }
    @request = Chef::REST::RESTRequest.new(:POST, url, @req_body, @headers)
  end

  it "stores the url it was created with" do
    expect(@request.url).to eq(url)
  end

  it "stores the HTTP method" do
    expect(@request.method).to eq(:POST)
  end

  it "adds the chef version header" do
    expect(@request.headers).to eq(@headers.merge("X-Chef-Version" => ::Chef::VERSION))
  end

  describe "configuring the HTTP request" do
    let(:url) do
      URI.parse("http://homie:theclown@chef.example.com:4000/?q=chef_is_awesome")
    end

    it "configures GET requests" do
      @req_body = nil
      rest_req = new_request(:GET)
      expect(rest_req.http_request).to be_a_kind_of(Net::HTTP::Get)
      expect(rest_req.http_request.path).to eq("/?q=chef_is_awesome")
      expect(rest_req.http_request.body).to be_nil
    end

    it "configures POST requests, including the body" do
      expect(@request.http_request).to be_a_kind_of(Net::HTTP::Post)
      expect(@request.http_request.path).to eq("/?q=chef_is_awesome")
      expect(@request.http_request.body).to eq(@req_body)
    end

    it "configures PUT requests, including the body" do
      rest_req = new_request(:PUT)
      expect(rest_req.http_request).to be_a_kind_of(Net::HTTP::Put)
      expect(rest_req.http_request.path).to eq("/?q=chef_is_awesome")
      expect(rest_req.http_request.body).to eq(@req_body)
    end

    it "configures DELETE requests" do
      rest_req = new_request(:DELETE)
      expect(rest_req.http_request).to be_a_kind_of(Net::HTTP::Delete)
      expect(rest_req.http_request.path).to eq("/?q=chef_is_awesome")
      expect(rest_req.http_request.body).to be_nil
    end

    it "configures HTTP basic auth" do
      rest_req = new_request(:GET)
      expect(rest_req.http_request.to_hash["authorization"]).to eq(["Basic aG9taWU6dGhlY2xvd24="])
    end
  end

  describe "configuring the HTTP client" do
    it "configures the HTTP client for the host and port" do
      http_client = new_request.http_client
      expect(http_client.address).to eq("chef.example.com")
      expect(http_client.port).to eq(4000)
    end

    it "configures the HTTP client with the read timeout set in the config file" do
      Chef::Config[:rest_timeout] = 9001
      expect(new_request.http_client.read_timeout).to eq(9001)
    end

    describe "for proxy" do
      before do
        stub_const("ENV", "http_proxy" => "http://proxy.example.com:3128",
                          "https_proxy" => "http://sproxy.example.com:3129",
                          "http_proxy_user" => nil,
                          "http_proxy_pass" => nil,
                          "https_proxy_user" => nil,
                          "https_proxy_pass" => nil,
                          "no_proxy" => nil
                  )
      end

      describe "with :no_proxy nil" do
        it "configures the proxy address and port when using http scheme" do
          http_client = new_request.http_client
          expect(http_client.proxy?).to eq(true)
          expect(http_client.proxy_address).to eq("proxy.example.com")
          expect(http_client.proxy_port).to eq(3128)
          expect(http_client.proxy_user).to be_nil
          expect(http_client.proxy_pass).to be_nil
        end

        context "when the url has an https scheme" do
          let(:url) { URI.parse("https://chef.example.com:4000/?q=chef_is_awesome") }

          it "configures the proxy address and port when using https scheme" do
            http_client = new_request.http_client
            expect(http_client.proxy?).to eq(true)
            expect(http_client.proxy_address).to eq("sproxy.example.com")
            expect(http_client.proxy_port).to eq(3129)
            expect(http_client.proxy_user).to be_nil
            expect(http_client.proxy_pass).to be_nil
          end
        end
      end

      describe "with :no_proxy set" do
        before do
          stub_const("ENV", "no_proxy" => "10.*,*.example.com")
        end

        it "does not configure the proxy address and port when using http scheme" do
          http_client = new_request.http_client
          expect(http_client.proxy?).to eq(false)
          expect(http_client.proxy_address).to be_nil
          expect(http_client.proxy_port).to be_nil
          expect(http_client.proxy_user).to be_nil
          expect(http_client.proxy_pass).to be_nil
        end

        context "when the url has an https scheme" do
          let(:url) { URI.parse("https://chef.example.com:4000/?q=chef_is_awesome") }

          it "does not configure the proxy address and port when using https scheme" do
            http_client = new_request.http_client
            expect(http_client.proxy?).to eq(false)
            expect(http_client.proxy_address).to be_nil
            expect(http_client.proxy_port).to be_nil
            expect(http_client.proxy_user).to be_nil
            expect(http_client.proxy_pass).to be_nil
          end
        end
      end

      describe "with :http_proxy_user and :http_proxy_pass set" do
        before do
          stub_const("ENV", "http_proxy" => "http://homie:theclown@proxy.example.com:3128")
        end

        it "configures the proxy user and pass when using http scheme" do
          http_client = new_request.http_client
          expect(http_client.proxy?).to eq(true)
          expect(http_client.proxy_user).to eq("homie")
          expect(http_client.proxy_pass).to eq("theclown")
        end

        context "when the url has an https scheme" do
          let(:url) { URI.parse("https://chef.example.com:4000/?q=chef_is_awesome") }

          it "does not configure the proxy user and pass when using https scheme" do
            http_client = new_request.http_client
            expect(http_client.proxy?).to eq(false)
            expect(http_client.proxy_user).to be_nil
            expect(http_client.proxy_pass).to be_nil
          end
        end
      end

      describe "with :https_proxy_user and :https_proxy_pass set" do
        before do
          stub_const("ENV", "http_proxy" => "http://proxy.example.com:3128",
                            "https_proxy" => "https://homie:theclown@sproxy.example.com:3129"
                    )
        end

        it "does not configure the proxy user and pass when using http scheme" do
          http_client = new_request.http_client
          expect(http_client.proxy?).to eq(true)
          expect(http_client.proxy_user).to be_nil
          expect(http_client.proxy_pass).to be_nil
        end

        context "when the url has an https scheme" do
          let(:url) { URI.parse("https://chef.example.com:4000/?q=chef_is_awesome") }

          it "configures the proxy user and pass when using https scheme" do
            http_client = new_request.http_client
            expect(http_client.proxy?).to eq(true)
            expect(http_client.proxy_user).to eq("homie")
            expect(http_client.proxy_pass).to eq("theclown")
          end
        end
      end
    end
  end
end
