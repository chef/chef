#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'uri'
require 'net/https'

KEY_DOT_PEM=<<-END_RSA_KEY
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA49TA0y81ps0zxkOpmf5V4/c4IeR5yVyQFpX3JpxO4TquwnRh
8VSUhrw8kkTLmB3cS39Db+3HadvhoqCEbqPE6915kXSuk/cWIcNozujLK7tkuPEy
YVsyTioQAddSdfe+8EhQVf3oHxaKmUd6waXrWqYCnhxgOjxocenREYNhZ/OETIei
PbOku47vB4nJK/0GhKBytL2XnsRgfKgDxf42BqAi1jglIdeq8lAWZNF9TbNBU21A
O1iuT7Pm6LyQujhggPznR5FJhXKRUARXBJZawxpGV4dGtdcahwXNE4601aXPra+x
PcRd2puCNoEDBzgVuTSsLYeKBDMSfs173W1QYwIDAQABAoIBAGF05q7vqOGbMaSD
2Q7YbuE/JTHKTBZIlBI1QC2x+0P5GDxyEFttNMOVzcs7xmNhkpRw8eX1LrInrpMk
WsIBKAFFEfWYlf0RWtRChJjNl+szE9jQxB5FJnWtJH/FHa78tR6PsF24aQyzVcJP
g0FGujBihwgfV0JSCNOBkz8MliQihjQA2i8PGGmo4R4RVzGfxYKTIq9vvRq/+QEa
Q4lpVLoBqnENpnY/9PTl6JMMjW2b0spbLjOPVwDaIzXJ0dChjNXo15K5SHI5mALJ
I5gN7ODGb8PKUf4619ez194FXq+eob5YJdilTFKensIUvt3YhP1ilGMM+Chi5Vi/
/RCTw3ECgYEA9jTw4wv9pCswZ9wbzTaBj9yZS3YXspGg26y6Ohq3ZmvHz4jlT6uR
xK+DDcUiK4072gci8S4Np0fIVS7q6ivqcOdzXPrTF5/j+MufS32UrBbUTPiM1yoO
ECcy+1szl/KoLEV09bghPbvC58PFSXV71evkaTETYnA/F6RK12lEepcCgYEA7OSy
bsMrGDVU/MKJtwqyGP9ubA53BorM4Pp9VVVSCrGGVhb9G/XNsjO5wJC8J30QAo4A
s59ZzCpyNRy046AB8jwRQuSwEQbejSdeNgQGXhZ7aIVUtuDeFFdaIz/zjVgxsfj4
DPOuzieMmJ2MLR4F71ocboxNoDI7xruPSE8dDhUCgYA3vx732cQxgtHwAkeNPJUz
dLiE/JU7CnxIoSB9fYUfPLI+THnXgzp7NV5QJN2qzMzLfigsQcg3oyo6F2h7Yzwv
GkjlualIRRzCPaCw4Btkp7qkPvbs1QngIHALt8fD1N69P3DPHkTwjG4COjKWgnJq
qoHKS6Fe/ZlbigikI6KsuwKBgQCTlSLoyGRHr6oj0hqz01EDK9ciMJzMkZp0Kvn8
OKxlBxYW+jlzut4MQBdgNYtS2qInxUoAnaz2+hauqhSzntK3k955GznpUatCqx0R
b857vWviwPX2/P6+E3GPdl8IVsKXCvGWOBZWTuNTjQtwbDzsUepWoMgXnlQJSn5I
YSlLxQKBgQD16Gw9kajpKlzsPa6XoQeGmZALT6aKWJQlrKtUQIrsIWM0Z6eFtX12
2jjHZ0awuCQ4ldqwl8IfRogWMBkHOXjTPVK0YKWWlxMpD/5+bGPARa5fir8O1Zpo
Y6S6MeZ69Rp89ma4ttMZ+kwi1+XyHqC/dlcVRW42Zl5Dc7BALRlJjQ==
-----END RSA PRIVATE KEY-----
  END_RSA_KEY


describe Chef::REST::AuthCredentials do
  before do
    @key_file_fixture = CHEF_SPEC_DATA + '/ssl/private_key.pem'
    @key = OpenSSL::PKey::RSA.new(IO.read(@key_file_fixture).strip)
    @auth_credentials = Chef::REST::AuthCredentials.new("client-name", @key)
  end

  it "has a client name" do
    @auth_credentials.client_name.should == "client-name"
  end

  it "loads the private key when initialized with the path to the key" do
    @auth_credentials.key.should respond_to(:private_encrypt)
    @auth_credentials.key.to_s.should == KEY_DOT_PEM
  end

  describe "when loading the private key" do
    it "strips extra whitespace before checking the key" do
      key_file_fixture = CHEF_SPEC_DATA + '/ssl/private_key_with_whitespace.pem'
      lambda {Chef::REST::AuthCredentials.new("client-name", @key_file_fixture)}.should_not raise_error
    end
  end

  describe "generating signature headers for a request" do
    before do
      @request_time = Time.at(1270920860)
      @request_params = {:http_method => :POST, :path => "/clients", :body => '{"some":"json"}', :host => "localhost"}
    end

    it "generates signature headers for the request" do
      Time.stub!(:now).and_return(@request_time)
      actual = @auth_credentials.signature_headers(@request_params)
      actual["HOST"].should                    == "localhost"
      actual["X-OPS-AUTHORIZATION-1"].should == "kBssX1ENEwKtNYFrHElN9vYGWS7OeowepN9EsYc9csWfh8oUovryPKDxytQ/"
      actual["X-OPS-AUTHORIZATION-2"].should == "Wc2/nSSyxdWJjjfHzrE+YrqNQTaArOA7JkAf5p75eTUonCWcvNPjFrZVgKGS"
      actual["X-OPS-AUTHORIZATION-3"].should == "yhzHJQh+lcVA9wwARg5Hu9q+ddS8xBOdm3Vp5atl5NGHiP0loiigMYvAvzPO"
      actual["X-OPS-AUTHORIZATION-4"].should == "r9853eIxwYMhn5hLGhAGFQznJbE8+7F/lLU5Zmk2t2MlPY8q3o1Q61YD8QiJ"
      actual["X-OPS-AUTHORIZATION-5"].should ==  "M8lIt53ckMyUmSU0DDURoiXLVkE9mag/6Yq2tPNzWq2AdFvBqku9h2w+DY5k"
      actual["X-OPS-AUTHORIZATION-6"].should == "qA5Rnzw5rPpp3nrWA9jKkPw4Wq3+4ufO2Xs6w7GCjA=="
      actual["X-OPS-CONTENT-HASH"].should == "1tuzs5XKztM1ANrkGNPah6rW9GY="
      actual["X-OPS-SIGN"].should         =~ %r{(version=1\.0)|(algorithm=sha1;version=1.0;)}
      actual["X-OPS-TIMESTAMP"].should    == "2010-04-10T17:34:20Z"
      actual["X-OPS-USERID"].should       == "client-name"

    end

    describe "when configured for version 1.1 of the authn protocol" do
      before do
        Chef::Config[:authentication_protocol_version] = "1.1"
      end

      after do
        Chef::Config[:authentication_protocol_version] = "1.0"
      end

      it "generates the correct signature for version 1.1" do
        Time.stub!(:now).and_return(@request_time)
        actual = @auth_credentials.signature_headers(@request_params)
        actual["HOST"].should                    == "localhost"
        actual["X-OPS-CONTENT-HASH"].should == "1tuzs5XKztM1ANrkGNPah6rW9GY="
        actual["X-OPS-SIGN"].should         == "algorithm=sha1;version=1.1;"
        actual["X-OPS-TIMESTAMP"].should    == "2010-04-10T17:34:20Z"
        actual["X-OPS-USERID"].should       == "client-name"

        # mixlib-authN will test the actual signature stuff for each version of
        # the protocol so we won't test it again here.
      end
    end
  end
end

describe Chef::REST::RESTRequest do
  def new_request(method=nil)
    method ||= :POST
    Chef::REST::RESTRequest.new(method, @url, @req_body, @headers)
  end

  before do
    @auth_credentials = Chef::REST::AuthCredentials.new("client-name", CHEF_SPEC_DATA + '/ssl/private_key.pem')
    @url = URI.parse("http://chef.example.com:4000/?q=chef_is_awesome")
    @req_body = '{"json_data":"as_a_string"}'
    @headers = {"Content-type" =>"application/json", "Accept"=>"application/json", "Accept-Encoding" => Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE}
    @request = Chef::REST::RESTRequest.new(:POST, @url, @req_body, @headers)
  end

  it "stores the url it was created with" do
    @request.url.should == @url
  end

  it "stores the HTTP method" do
    @request.method.should == :POST
  end

  it "adds the chef version header" do
    @request.headers.should == @headers.merge("X-Chef-Version" => ::Chef::VERSION)
  end

  describe "configuring the HTTP request" do
    it "configures GET requests" do
      @req_body = nil
      rest_req = new_request(:GET)
      rest_req.http_request.should be_a_kind_of(Net::HTTP::Get)
      rest_req.http_request.path.should == "/?q=chef_is_awesome"
      rest_req.http_request.body.should be_nil
    end

    it "configures POST requests, including the body" do
      @request.http_request.should be_a_kind_of(Net::HTTP::Post)
      @request.http_request.path.should == "/?q=chef_is_awesome"
      @request.http_request.body.should == @req_body
    end

    it "configures PUT requests, including the body" do
      rest_req = new_request(:PUT)
      rest_req.http_request.should be_a_kind_of(Net::HTTP::Put)
      rest_req.http_request.path.should == "/?q=chef_is_awesome"
      rest_req.http_request.body.should == @req_body
    end

    it "configures DELETE requests" do
      rest_req = new_request(:DELETE)
      rest_req.http_request.should be_a_kind_of(Net::HTTP::Delete)
      rest_req.http_request.path.should == "/?q=chef_is_awesome"
      rest_req.http_request.body.should be_nil
    end

    it "configures HTTP basic auth" do
      @url = URI.parse("http://homie:theclown@chef.example.com:4000/?q=chef_is_awesome")
      rest_req = new_request(:GET)
      rest_req.http_request.to_hash["authorization"].should == ["Basic aG9taWU6dGhlY2xvd24="]
    end
  end

  describe "configuring the HTTP client" do
    it "configures the HTTP client for the host and port" do
      http_client = new_request.http_client
      http_client.address.should == "chef.example.com"
      http_client.port.should == 4000
    end

    it "configures the HTTP client with the read timeout set in the config file" do
      Chef::Config[:rest_timeout] = 9001
      new_request.http_client.read_timeout.should == 9001
    end

    describe "for SSL" do
      before do
        Chef::Config[:ssl_client_cert] = nil
        Chef::Config[:ssl_client_key]  = nil
        Chef::Config[:ssl_ca_path]     = nil
        Chef::Config[:ssl_ca_file]     = nil
      end

      after do
        Chef::Config[:ssl_client_cert] = nil
        Chef::Config[:ssl_client_key]  = nil
        Chef::Config[:ssl_ca_path]     = nil
        Chef::Config[:ssl_verify_mode] = :verify_none
        Chef::Config[:ssl_ca_file]     = nil
      end

      describe "when configured with :ssl_verify_mode set to :verify peer" do
        before do
          @url = URI.parse("https://chef.example.com:4443/")
          Chef::Config[:ssl_verify_mode] = :verify_peer
          @request = new_request
        end

        it "configures the HTTP client to use SSL when given a URL with the https protocol" do
          @request.http_client.use_ssl?.should be_true
        end

        it "sets the OpenSSL verify mode to verify_peer" do
          @request.http_client.verify_mode.should == OpenSSL::SSL::VERIFY_PEER
        end

        it "raises a ConfigurationError if :ssl_ca_path is set to a path that doesn't exist" do
          Chef::Config[:ssl_ca_path] = "/dev/null/nothing_here"
          lambda {new_request}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "should set the CA path if that is set in the configuration" do
          Chef::Config[:ssl_ca_path] = File.join(CHEF_SPEC_DATA, "ssl")
          new_request.http_client.ca_path.should == File.join(CHEF_SPEC_DATA, "ssl")
        end

        it "raises a ConfigurationError if :ssl_ca_file is set to a file that does not exist" do
          Chef::Config[:ssl_ca_file] = "/dev/null/nothing_here"
          lambda {new_request}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "should set the CA file if that is set in the configuration" do
          Chef::Config[:ssl_ca_file] = CHEF_SPEC_DATA + '/ssl/5e707473.0'
          new_request.http_client.ca_file.should == CHEF_SPEC_DATA + '/ssl/5e707473.0'
        end
      end

      describe "when configured with :ssl_verify_mode set to :verify peer" do
        before do
          @url = URI.parse("https://chef.example.com:4443/")
          Chef::Config[:ssl_verify_mode] = :verify_none
        end

        it "sets the OpenSSL verify mode to :verify_none" do
          new_request.http_client.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
        end
      end

      describe "when configured with a client certificate" do
        before {@url = URI.parse("https://chef.example.com:4443/")}

        it "raises ConfigurationError if the certificate file doesn't exist" do
          Chef::Config[:ssl_client_cert] = "/dev/null/nothing_here"
          Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + '/ssl/chef-rspec.key'
          lambda {new_request}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "raises ConfigurationError if the certificate file doesn't exist" do
          Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + '/ssl/chef-rspec.cert'
          Chef::Config[:ssl_client_key]  = "/dev/null/nothing_here"
          lambda {new_request}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "raises a ConfigurationError if one of :ssl_client_cert and :ssl_client_key is set but not both" do
          Chef::Config[:ssl_client_cert] = "/dev/null/nothing_here"
          Chef::Config[:ssl_client_key]  = nil
          lambda {new_request}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "configures the HTTP client's cert and private key" do
          Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + '/ssl/chef-rspec.cert'
          Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + '/ssl/chef-rspec.key'
          http_client = new_request.http_client
          http_client.cert.to_s.should == OpenSSL::X509::Certificate.new(IO.read(CHEF_SPEC_DATA + '/ssl/chef-rspec.cert')).to_s
          http_client.key.to_s.should  == IO.read(CHEF_SPEC_DATA + '/ssl/chef-rspec.key')
        end
      end
    end

    describe "for proxy" do
      before do
        Chef::Config[:http_proxy]  = "http://proxy.example.com:3128"
        Chef::Config[:https_proxy] = "http://sproxy.example.com:3129"
        Chef::Config[:http_proxy_user] = nil
        Chef::Config[:http_proxy_pass] = nil
        Chef::Config[:https_proxy_user] = nil
        Chef::Config[:https_proxy_pass] = nil
        Chef::Config[:no_proxy] = nil
      end

      after do
        Chef::Config[:http_proxy]  = nil
        Chef::Config[:https_proxy] = nil
        Chef::Config[:http_proxy_user] = nil
        Chef::Config[:http_proxy_pass] = nil
        Chef::Config[:https_proxy_user] = nil
        Chef::Config[:https_proxy_pass] = nil
        Chef::Config[:no_proxy] = nil
      end

      describe "with :no_proxy nil" do
        it "configures the proxy address and port when using http scheme" do
          http_client = new_request.http_client
          http_client.proxy?.should == true
          http_client.proxy_address.should == "proxy.example.com"
          http_client.proxy_port.should == 3128
          http_client.proxy_user.should be_nil
          http_client.proxy_pass.should be_nil
        end

        it "configures the proxy address and port when using https scheme" do
          @url.scheme = "https"
          http_client = new_request.http_client
          http_client.proxy?.should == true
          http_client.proxy_address.should == "sproxy.example.com"
          http_client.proxy_port.should == 3129
          http_client.proxy_user.should be_nil
          http_client.proxy_pass.should be_nil
        end
      end

      describe "with :no_proxy set" do
        before do
          Chef::Config[:no_proxy] = "10.*,*.example.com"
        end

        it "does not configure the proxy address and port when using http scheme" do
          http_client = new_request.http_client
          http_client.proxy?.should == false
          http_client.proxy_address.should be_nil
          http_client.proxy_port.should be_nil
          http_client.proxy_user.should be_nil
          http_client.proxy_pass.should be_nil
        end

        it "does not configure the proxy address and port when using https scheme" do
          @url.scheme = "https"
          http_client = new_request.http_client
          http_client.proxy?.should == false
          http_client.proxy_address.should be_nil
          http_client.proxy_port.should be_nil
          http_client.proxy_user.should be_nil
          http_client.proxy_pass.should be_nil
        end
      end

      describe "with :http_proxy_user and :http_proxy_pass set" do
        before do
          Chef::Config[:http_proxy_user] = "homie"
          Chef::Config[:http_proxy_pass] = "theclown"
        end

        after do
          Chef::Config[:http_proxy_user] = nil
          Chef::Config[:http_proxy_pass] = nil
        end

        it "configures the proxy user and pass when using http scheme" do
          http_client = new_request.http_client
          http_client.proxy?.should == true
          http_client.proxy_user.should == "homie"
          http_client.proxy_pass.should == "theclown"
        end

        it "does not configure the proxy user and pass when using https scheme" do
          @url.scheme = "https"
          http_client = new_request.http_client
          http_client.proxy?.should == true
          http_client.proxy_user.should be_nil
          http_client.proxy_pass.should be_nil
        end
      end

      describe "with :https_proxy_user and :https_proxy_pass set" do
        before do
          Chef::Config[:https_proxy_user] = "homie"
          Chef::Config[:https_proxy_pass] = "theclown"
        end

        after do
          Chef::Config[:https_proxy_user] = nil
          Chef::Config[:https_proxy_pass] = nil
        end

        it "does not configure the proxy user and pass when using http scheme" do
          http_client = new_request.http_client
          http_client.proxy?.should == true
          http_client.proxy_user.should be_nil
          http_client.proxy_pass.should be_nil
        end

        it "configures the proxy user and pass when using https scheme" do
          @url.scheme = "https"
          http_client = new_request.http_client
          http_client.proxy?.should == true
          http_client.proxy_user.should == "homie"
          http_client.proxy_pass.should == "theclown"
        end
      end
    end
  end

end
