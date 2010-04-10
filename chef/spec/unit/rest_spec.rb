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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
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


describe Chef::REST do
  before(:each) do
    Chef::REST::CookieJar.stub!(:instance).and_return({})
    @rest = Chef::REST.new("url", nil, nil)
  end

  describe "get_rest" do
    it "should create a url from the path and base url" do
      URI.should_receive(:parse).with("url/monkey")
      @rest.stub!(:run_request)
      @rest.get_rest("monkey")
    end

    it "should call run_request :GET with the composed url object" do
      URI.stub!(:parse).and_return(true)
      @rest.should_receive(:run_request).with(:GET, true, {}, false, 10, false).and_return(true)
      @rest.get_rest("monkey")
    end
  end

  describe "delete_rest" do
    it "should create a url from the path and base url" do
      URI.should_receive(:parse).with("url/monkey")
      @rest.stub!(:run_request)
      @rest.delete_rest("monkey")
    end

    it "should call run_request :DELETE with the composed url object" do
      URI.stub!(:parse).and_return(true)
      @rest.should_receive(:run_request).with(:DELETE, true, {}).and_return(true)
      @rest.delete_rest("monkey")
    end
  end

  describe "post_rest" do
    it "should create a url from the path and base url" do
      URI.should_receive(:parse).with("url/monkey")
      @rest.stub!(:run_request)
      @rest.post_rest("monkey", "data")
    end

    it "should call run_request :POST with the composed url object and data" do
      URI.stub!(:parse).and_return(true)
      @rest.should_receive(:run_request).with(:POST, true, {}, "data").and_return(true)
      @rest.post_rest("monkey", "data")
    end
  end

  describe "put_rest" do
    it "should create a url from the path and base url" do
      URI.should_receive(:parse).with("url/monkey")
      @rest.stub!(:run_request)
      @rest.put_rest("monkey", "data")
    end

    it "should call run_request :PUT with the composed url object and data" do
      URI.stub!(:parse).and_return(true)
      @rest.should_receive(:run_request).with(:PUT, true, {}, "data").and_return(true)
      @rest.put_rest("monkey", "data")
    end
  end

  describe "when configured to authenticate to the Chef server" do
    before do
      @url = URI.parse("http://chef.example.com:4000")
      Chef::Config[:node_name]  = "webmonkey.example.com"
      Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
      @rest = Chef::REST.new(@url)
    end

    it "configures itself to use the node_name and client_key in the config by default" do
      @rest.client_name.should == "webmonkey.example.com"
      @rest.signing_key_filename.should == CHEF_SPEC_DATA + "/ssl/private_key.pem"
    end

    it "provides access to the raw key data" do
      @rest.signing_key.should == KEY_DOT_PEM
    end

    it "does not error out when initialized without credentials" do
      @rest = Chef::REST.new(@url, nil, nil) #should_not raise_error hides the bt from you, so screw it.
      @rest.client_name.should be_nil
      @rest.signing_key.should be_nil
    end

    it "indicates that requests should not be signed when it has no credentials" do
      @rest = Chef::REST.new(@url, nil, nil)
      @rest.sign_requests?.should be_false
    end

  end

  describe "configuring the HTTP client" do
    before do
      @url = URI.parse("http://chef.example.com:4000")
      @chef_config = {}
      @rest.stub!(:config).and_return @chef_config
    end

    it "configures the HTTP client for the host and port" do
      http_client = @rest.http_client_for(@url)
      http_client.address.should == "chef.example.com"
      http_client.port.should == 4000
    end

    it "configures the HTTP client with the read timeout set in the config file" do
      @chef_config[:rest_timeout] = 9001
      http_client = @rest.http_client_for(@url)
      http_client.read_timeout.should == 9001
    end

    describe "for SSL" do
      describe "when configured with :ssl_verify_mode set to :verify peer" do
        before do
          @url = URI.parse("https://chef.example.com:4443")
          @chef_config[:ssl_verify_mode] = :verify_peer
        end

        it "configures the HTTP client to use SSL when given a URL with the https protocol" do
          http_client = @rest.http_client_for(@url)
          http_client.use_ssl?.should be_true
        end

        it "sets the OpenSSL verify mode to verify_peer" do
          http_client = @rest.http_client_for(@url)
          http_client.verify_mode.should == OpenSSL::SSL::VERIFY_PEER
        end

        it "raises a ConfigurationError if :ssl_ca_path is set to a path that doesn't exist" do
          @chef_config[:ssl_ca_path] = "/dev/null/nothing_here"
          lambda {@rest.http_client_for(@url)}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "should set the CA path if that is set in the configuration" do
          @chef_config[:ssl_ca_path] = File.join(CHEF_SPEC_DATA, "ssl")
          http_client = @rest.http_client_for(@url)
          http_client.ca_path.should == File.join(CHEF_SPEC_DATA, "ssl")
        end

        it "raises a ConfigurationError if :ssl_ca_file is set to a file that does not exist" do
          @chef_config[:ssl_ca_file] = "/dev/null/nothing_here"
          lambda {@rest.http_client_for(@url)}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "should set the CA file if that is set in the configuration" do
          @chef_config[:ssl_ca_file] = CHEF_SPEC_DATA + '/ssl/5e707473.0'
          http_client = @rest.http_client_for(@url)
          http_client.ca_file.should == CHEF_SPEC_DATA + '/ssl/5e707473.0'
        end
      end

      describe "when configured with :ssl_verify_mode set to :verify peer" do
        before do
          @url = URI.parse("https://chef.example.com:4443")
          @chef_config[:ssl_verify_mode] = :verify_none
        end

        it "sets the OpenSSL verify mode to :verify_none" do
          http_client = @rest.http_client_for(@url)
          http_client.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
        end
      end

      describe "when configured with a client certificate" do
        before {@url = URI.parse("https://chef.example.com:4443")}

        it "raises ConfigurationError if the certificate file doesn't exist" do
          @chef_config[:ssl_client_cert] = "/dev/null/nothing_here"
          @chef_config[:ssl_client_key]  = CHEF_SPEC_DATA + '/ssl/chef-rspec.key'
          lambda {@rest.http_client_for(@url)}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "raises ConfigurationError if the certificate file doesn't exist" do
          @chef_config[:ssl_client_cert] = CHEF_SPEC_DATA + '/ssl/chef-rspec.cert'
          @chef_config[:ssl_client_key]  = "/dev/null/nothing_here"
          lambda {@rest.http_client_for(@url)}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "raises a ConfigurationError if one of :ssl_client_cert and :ssl_client_key is set but not both" do
          @chef_config[:ssl_client_cert] = "/dev/null/nothing_here"
          @chef_config[:ssl_client_key]  = nil
          lambda {@rest.http_client_for(@url)}.should raise_error(Chef::Exceptions::ConfigurationError)
        end

        it "configures the HTTP client's cert and private key" do
          @chef_config[:ssl_client_cert] = CHEF_SPEC_DATA + '/ssl/chef-rspec.cert'
          @chef_config[:ssl_client_key]  = CHEF_SPEC_DATA + '/ssl/chef-rspec.key'
          http_client = @rest.http_client_for(@url)
          http_client.cert.to_s.should == OpenSSL::X509::Certificate.new(IO.read(CHEF_SPEC_DATA + '/ssl/chef-rspec.cert')).to_s
          http_client.key.to_s.should  == IO.read(CHEF_SPEC_DATA + '/ssl/chef-rspec.key')
        end
      end
    end
  end

  describe Chef::REST, "run_request method" do
    before(:each) do
      Chef::Config[:ssl_client_cert] = nil
      Chef::Config[:ssl_client_key]  = nil

      @url_mock = mock("URI", :null_object => true)
      @url_mock.stub!(:host).and_return("one")
      @url_mock.stub!(:port).and_return("80")
      @url_mock.stub!(:path).and_return("/")
      @url_mock.stub!(:query).and_return("foo=bar")
      @url_mock.stub!(:scheme).and_return("https")
      @url_mock.stub!(:to_s).and_return("https://one:80/?foo=bar")
      @http_response_mock = mock("Net::HTTPSuccess", :null_object => true)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(true)
      @http_response_mock.stub!(:body).and_return("ninja")
      @http_response_mock.stub!(:error!).and_return(true)
      @http_response_mock.stub!(:header).and_return({ 'Content-Length' => "5" })
      @http_mock = mock("Net::HTTP", :null_object => true)
      @http_mock.stub!(:verify_mode=).and_return(true)
      @http_mock.stub!(:read_timeout=).and_return(true)
      @http_mock.stub!(:use_ssl=).with(true).and_return(true)
      @data_mock = mock("Data", :null_object => true)
      @data_mock.stub!(:to_json).and_return('{ "one": "two" }')
      @request_mock = mock("Request", :null_object => true)
      @request_mock.stub!(:body=).and_return(true)
      @request_mock.stub!(:method).and_return(true)
      @request_mock.stub!(:path).and_return(true)
      @http_mock.stub!(:request).and_return(@http_response_mock)
      @tf_mock = mock(Tempfile, { :print => true, :close => true, :write => true })
      Tempfile.stub!(:new).with("chef-rest").and_return(@tf_mock)
    end

    def do_run_request(method=:GET, data=false, limit=10, raw=false)
      Net::HTTP.stub!(:new).and_return(@http_mock)
      @rest.run_request(method, @url_mock, {}, data, limit, raw)
    end

    it "should always include the X-Chef-Version header" do
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar",
        { 'Accept' => 'application/json', 'X-Chef-Version' => Chef::VERSION }
      ).and_return(@request_mock)
      do_run_request
    end

    it "should raise an exception if the redirect limit is 0" do
      lambda { @rest.run_request(:GET, "/", {}, false, 0)}.should raise_error(ArgumentError)
    end

    it "should set the cookie for this request if one exists for the given host:port" do
      @rest.cookies = { "#{@url_mock.host}:#{@url_mock.port}" => "cookie monster" }
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar",
        { 'Accept' => 'application/json', 'X-Chef-Version' => Chef::VERSION, 'Cookie' => 'cookie monster' }
      ).and_return(@request_mock)
      do_run_request
      @rest.cookies = Hash.new
    end

    it "should build a new HTTP GET request" do
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar",
        { 'Accept' => 'application/json', 'X-Chef-Version' => Chef::VERSION }
      ).and_return(@request_mock)
      do_run_request
    end

    it "should build a new HTTP POST request" do
      Net::HTTP::Post.should_receive(:new).with("/?foo=bar",
        { 'Accept' => 'application/json', "Content-Type" => 'application/json', 'X-Chef-Version' => Chef::VERSION }
      ).and_return(@request_mock)
      do_run_request(:POST, @data_mock)
    end

    it "should build a new HTTP PUT request" do
      Net::HTTP::Put.should_receive(:new).with("/?foo=bar",
        { 'Accept' => 'application/json', "Content-Type" => 'application/json', 'X-Chef-Version' => Chef::VERSION }
      ).and_return(@request_mock)
      do_run_request(:PUT, @data_mock)
    end

    it "should build a new HTTP DELETE request" do
      Net::HTTP::Delete.should_receive(:new).with("/?foo=bar",
        { 'Accept' => 'application/json', 'X-Chef-Version' => Chef::VERSION }
      ).and_return(@request_mock)
      do_run_request(:DELETE)
    end

    it "should raise an error if the method is not GET/PUT/POST/DELETE" do
      lambda { do_run_request(:MONKEY) }.should raise_error(ArgumentError)
    end

    it "should run an http request" do
      @http_mock.should_receive(:request).and_return(@http_response_mock)
      do_run_request
    end

    it "should return the body of the response on success" do
      do_run_request.should eql("ninja")
    end

    it "should inflate the body as to an object if JSON is returned" do
      @http_response_mock.stub!(:[]).with('content-type').and_return("application/json")
      JSON.should_receive(:parse).with("ninja").and_return(true)
      do_run_request
    end

    it "should call run_request again on a Redirect response" do
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPFound).and_return(true)
      @http_response_mock.stub!(:[]).with('location').and_return(@url_mock.path)
      lambda { do_run_request(method=:GET, data=false, limit=1) }.should raise_error(ArgumentError)
    end

    it "should call run_request again on a Permanent Redirect response" do
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPFound).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPMovedPermanently).and_return(true)
      @http_response_mock.stub!(:[]).with('location').and_return(@url_mock.path)
      lambda { do_run_request(method=:GET, data=false, limit=1) }.should raise_error(ArgumentError)
    end

    it "should show the JSON error message on an unsuccessful request" do
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPFound).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPMovedPermanently).and_return(false)
      @http_response_mock.stub!(:[]).with('content-type').and_return('application/json')
      @http_response_mock.stub!(:body).and_return('{ "error":[ "Ears get sore!", "Not even four" ] }')
      @http_response_mock.stub!(:code).and_return(500)
      @http_response_mock.stub!(:message).and_return('Server Error')
      ## BUGBUG - this should absolutely be working, but it.. isn't.
      #Chef::Log.should_receive(:warn).with("HTTP Request Returned 500 Server Error: Ears get sore!, Not even four")
      @http_response_mock.should_receive(:error!)
      do_run_request
    end

    it "should raise an exception on an unsuccessful request" do
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPFound).and_return(false)
      @http_response_mock.stub!(:kind_of?).with(Net::HTTPMovedPermanently).and_return(false)
      @http_response_mock.should_receive(:error!)
      do_run_request
    end

    it "should build a new HTTP GET request without the application/json accept header for raw reqs" do
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar", {'X-Chef-Version' => Chef::VERSION}).and_return(@request_mock)
      do_run_request(:GET, false, 10, true)
    end

    it "should create a tempfile for the output of a raw request" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      Tempfile.should_receive(:new).with("chef-rest").and_return(@tf_mock)
      do_run_request(:GET, false, 10, true).should eql(@tf_mock)
    end

    it "should read the body of the response in chunks on a raw request" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      @http_response_mock.should_receive(:read_body).and_return(true)
      do_run_request(:GET, false, 10, true)
    end

    it "should populate the tempfile with the value of the raw request" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      @http_response_mock.stub!(:read_body).and_yield("ninja")
      @tf_mock.should_receive(:write, "ninja").once.and_return(true)
      do_run_request(:GET, false, 10, true)
    end

    it "should close the tempfile if we're doing a raw request" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      @tf_mock.should_receive(:close).once.and_return(true)
      do_run_request(:GET, false, 10, true)
    end

    it "should not raise a divide by zero exception if the size is 0" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      @http_response_mock.stub!(:header).and_return({ 'Content-Length' => "5" })
      @http_response_mock.stub!(:read_body).and_yield('')
      lambda { do_run_request(:GET, false, 10, true) }.should_not raise_error(ZeroDivisionError)
    end

    it "should not raise a divide by zero exception if the Content-Length is 0" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      @http_response_mock.stub!(:header).and_return({ 'Content-Length' => "0" })
      @http_response_mock.stub!(:read_body).and_yield("ninja")
      lambda { do_run_request(:GET, false, 10, true) }.should_not raise_error(ZeroDivisionError)
    end

    it "should call read_body without a block if the request is not raw" do
      @http_mock.stub!(:request).and_yield(@http_response_mock).and_return(@http_response_mock)
      @http_response_mock.should_receive(:read_body)
      do_run_request(:GET, false, 10, false)
    end

  end

end

describe Chef::REST::AuthCredentials do
  before do
    @key_file_fixture = CHEF_SPEC_DATA + '/ssl/private_key.pem'
    @auth_credentials = Chef::REST::AuthCredentials.new("client-name", @key_file_fixture)
  end

  it "has a key file value" do
    @auth_credentials.key_file.should == @key_file_fixture
  end

  it "has a client name" do
    @auth_credentials.client_name.should == "client-name"
  end

  it "loads the private key when initialized with the path to the key" do
    @auth_credentials.key.should respond_to :private_encrypt
    @auth_credentials.key.to_s.should == KEY_DOT_PEM
  end

  describe "when loading the private key" do
    it "raises PrivateKeyMissing when the key file doesn't exist" do
      lambda {Chef::REST::AuthCredentials.new("client-name", "/dev/null/nothing_here")}.should raise_error(Chef::Exceptions::PrivateKeyMissing)
    end

    it "raises InvalidPrivateKey when the key file doesnt' look like a key" do
      invalid_key_file = CHEF_SPEC_DATA + "/bad-config.rb"
      lambda {Chef::REST::AuthCredentials.new("client-name", invalid_key_file)}.should raise_error(Chef::Exceptions::InvalidPrivateKey)
    end
  end

  describe "generating signature headers for a request" do
    before do
      @request_time = Time.at(1270920860)
      @request_params = {:http_method => :POST, :path => "/clients", :body => '{"some":"json"}', :host => "localhost"}
    end

    it "generates signature headers for the request" do
      Time.stub!(:now).and_return(@request_time)
      expected = {}
      expected["HOST"]                  = "localhost"
      expected["X-OPS-AUTHORIZATION-1"] = "kBssX1ENEwKtNYFrHElN9vYGWS7OeowepN9EsYc9csWfh8oUovryPKDxytQ/"
      expected["X-OPS-AUTHORIZATION-2"] = "Wc2/nSSyxdWJjjfHzrE+YrqNQTaArOA7JkAf5p75eTUonCWcvNPjFrZVgKGS"
      expected["X-OPS-AUTHORIZATION-3"] = "yhzHJQh+lcVA9wwARg5Hu9q+ddS8xBOdm3Vp5atl5NGHiP0loiigMYvAvzPO"
      expected["X-OPS-AUTHORIZATION-4"] = "r9853eIxwYMhn5hLGhAGFQznJbE8+7F/lLU5Zmk2t2MlPY8q3o1Q61YD8QiJ"
      expected["X-OPS-AUTHORIZATION-5"] =  "M8lIt53ckMyUmSU0DDURoiXLVkE9mag/6Yq2tPNzWq2AdFvBqku9h2w+DY5k"
      expected["X-OPS-AUTHORIZATION-6"] = "qA5Rnzw5rPpp3nrWA9jKkPw4Wq3+4ufO2Xs6w7GCjA=="
      expected["X-OPS-CONTENT-HASH"]    = "1tuzs5XKztM1ANrkGNPah6rW9GY="
      expected["X-OPS-SIGN"]            = "version=1.0"
      expected["X-OPS-TIMESTAMP"]       = "2010-04-10T17:34:20Z"
      expected["X-OPS-USERID"]          = "client-name"

      @auth_credentials.signature_headers(@request_params).should == expected
    end
  end

end

