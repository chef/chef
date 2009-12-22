#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::REST do
  before(:each) do
    Chef::REST::CookieJar.stub!(:instance).and_return({})
    @rest = Chef::REST.new("url", nil, nil)
  end

  describe "initialize" do
    it "should create a new Chef::REST" do
      @rest.should be_kind_of(Chef::REST)
    end
  end

  describe "load_signing_key" do
    before(:each) do
      @private_key = <<EOH
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAx8xAfO2BO8kUughpjWwHPN2rgDcES15PbMEGe6OdJgjFARkt
FMdEusbGxmXKpk51Ggxi2P6ZYEoZfniZWt4qSt4i1vanDayRlJ1qoRCOaYj5cQS7
gpHspHWqkY3HfGvx4svdutQ06o/gypx2QYfi68YrIUQexPiTUhsnP9FlgNt40Rl1
YgBiIlJUk7d3q+1b/+POTNKPeyjGK9hoTloplbSx+cYdZgc4/YpU0eLBoHPuPv5l
QD+Y8VNS39bvY2NWbCqhV508gExAK26FxXTDNpi2mTZmbRZ8U0PKrCgF6gBSeod5
EdQnNgoZHmA2fzfPHWfJd2OEuMcNM7DWpPDizQIDAQABAoIBAAGVDYGvw9E8Y2yh
umxDSb9ipgQK637JTWm4EZwTDKCLezvp/iBm/5VXE6XoknVEs8q0BGhhg8dubstA
mz5L+hvDrJT1ORdzoWeC46BI6EfPrOIHPpDnJO+cevBSJh1HIZBBOw1KtuyQnSAd
oxYbxGFHnXnS90dqDIie7G2l897UWoiQWNMLY+A+l5H4GLC+4Phq02pLd4OQwXA3
Nd+3Nq69aOeccyfSDeeG7u35TKrjQPIxU210aR18d/0trR20BKsKbT30GPE1tQQd
jm4uReSPttTQ+NjwBQKKYmO2F9b9MPzmQ7c+KycBRmf+IOgZeZ54JN0GzUXsDTjJ
+ZSgdgUCgYEA41aetBJwsKkF973gL54QCB5vFhRw3TdUgYhQgz04B5JGouGTSALy
u1XtO6il65Zf6FwFSzXiggYYxTKyP/zwL88CQAVA7rleyhoZrw2bD6R2RZLivRba
50rstltUbjevd96TagFY7i9gVHL9E6DKJH4unZfIM0Bl2IZQraqCR8MCgYEA4PzC
FfUwiLa5drN6OVWZZfwxOeMbQUsYVeq7pHyeuvIe0euhcCLabBqfVt0pxqf1hem+
l2+PnSKtvbI9siwt6WvJCtB3e/3aHOA3d6Y9TYxoyJAK007mRlQbbgqLzG83tZH2
twO2tjo+h1+nv5yjE7aF9ItszegwTWsupvR+Ei8CgYAy0nt6MCEnLTIbV0RWANT+
q6cT3Y/5tFPc/Vdab4YmEypdYWZmk9olzSjSzHoDN8PLEz9PuAUiIjDJbPLyYR5k
4bdUDpicha5OKhWRz83Zal/SX+r2cLSRPmu6vKIcXbCJcKWt7g0uekLjvi0bhTeL
fvX23yavZnceN7Czkkm7twKBgEFTgrNHdykrDRzXLhT5ssm2+UAani5ONKm1t3gi
KyCS7rn7FevuYsdiz4M0Qk4JNLQGU6262dNBX3smBt32D/qnrj8ymo7o/WzG+bQH
E+OxcjdSA6KpVRl0kGZaL49Td7SDxkQLkwDEVqWN87IiNAOkSq7f0N7UnTnNdkVJ
1lVHAoGBANYgMoEj7gIJdch7hMdQcFfq9+4ntAAbsl3JFW+T9ChATn0XHAylP9ha
ZaGlRrC7vxcF06vMe0HXyH1XVK3J9186zliTa4oDjkQ0D5X7Ga7KktLXAmQTysUH
V3jwIQbAF6LqLUnGOq6rJzQxrWKvFt0mVDyuJzIJGSbnN/Sl5J6P
-----END RSA PRIVATE KEY-----
EOH
      IO.stub!(:read).and_return(@private_key)
    end

    it "should return the contents of the key file" do
      File.stub!(:exists?).and_return(true)
      File.stub!(:readable?).and_return(true)
      @rest.load_signing_key("/tmp/keyfile.pem").should be(@private_key)
    end

    it "should raise a Chef::Exceptions::PrivateKeyMissing exception if the key cannot be found" do
      File.stub!(:exists?).and_return(false)
      File.stub!(:readable?).and_return(true) #42!
      lambda {
        @rest.load_signing_key("/tmp/keyfile.pem")
      }.should raise_error(Chef::Exceptions::PrivateKeyMissing)
    end

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

  describe Chef::REST, "run_request method" do
    before(:each) do
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
    
    it "should raise an exception if the redirect limit is 0" do
      lambda { @rest.run_request(:GET, "/", {}, false, 0)}.should raise_error(ArgumentError)
    end
    
    it "should use SSL if the url starts with https" do
      @url_mock.should_receive(:scheme).and_return("https")
      @http_mock.should_receive(:use_ssl=).with(true).and_return(true)
      do_run_request
    end
    
    it "should set the OpenSSL Verify Mode to verify_none if requested" do
      @http_mock.should_receive(:verify_mode=).and_return(true)
      do_run_request
    end
    
    describe "with OpenSSL Verify Mode set to :verify peer" do
      before(:each) do
        Chef::Config[:ssl_verify_mode] = :verify_peer
        @url_mock.should_receive(:scheme).and_return("https")
      end

      after(:each) do
        Chef::Config[:ssl_verify_mode] = :verify_none
      end

      it "should set the OpenSSL Verify Mode to verify_peer if requested" do
        @http_mock.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER).and_return(true)
        do_run_request
      end

      it "should set the CA path if that is set in the configuration" do
        Chef::Config[:ssl_ca_path] = File.join(File.dirname(__FILE__), "..", "data", "ssl")
        @http_mock.should_receive(:ca_path=).with(Chef::Config[:ssl_ca_path]).and_return(true)
        do_run_request
        Chef::Config[:ssl_ca_path] = nil
      end

      it "should set the CA file if that is set in the configuration" do
        Chef::Config[:ssl_ca_file] = File.join(File.dirname(__FILE__), "..", "data", "ssl", "5e707473.0")
        @http_mock.should_receive(:ca_file=).with(Chef::Config[:ssl_ca_file]).and_return(true)
        do_run_request
        Chef::Config[:ssl_ca_file] = nil
      end
    end

    describe "with a client SSL cert" do
      before(:each) do
        Chef::Config[:ssl_client_cert] = "/etc/chef/client-cert.pem"
        Chef::Config[:ssl_client_key] = "/etc/chef/client-cert.key"
        File.stub!(:exists?).with("/etc/chef/client-cert.pem").and_return(true)
        File.stub!(:exists?).with("/etc/chef/client-cert.key").and_return(true)
        File.stub!(:read).with("/etc/chef/client-cert.pem").and_return("monkey magic client")
        File.stub!(:read).with("/etc/chef/client-cert.key").and_return("monkey magic key")
        OpenSSL::X509::Certificate.stub!(:new).and_return("monkey magic client data")
        OpenSSL::PKey::RSA.stub!(:new).and_return("monkey magic key data")
      end

      it "should check that the client cert file exists" do
        File.should_receive(:exists?).with("/etc/chef/client-cert.pem").and_return(true)
        do_run_request
      end

      it "should read the cert file" do
        File.should_receive(:read).with("/etc/chef/client-cert.pem").and_return("monkey magic client")
        do_run_request
      end

      it "should read the cert into OpenSSL" do
        OpenSSL::X509::Certificate.should_receive(:new).and_return("monkey magic client data")
        do_run_request
      end

      it "should set the cert" do
        @http_mock.should_receive(:cert=).and_return(true)
        do_run_request
      end

      it "should read the key file" do
        File.should_receive(:read).with("/etc/chef/client-cert.key").and_return("monkey magic key")
        do_run_request
      end

      it "should read the key into OpenSSL" do
        OpenSSL::PKey::RSA.should_receive(:new).and_return("monkey magic key data")
        do_run_request
      end

      it "should set the key" do
        @http_mock.should_receive(:key=).and_return(true)
        do_run_request
      end

    end

    it "should set a read timeout based on the rest_timeout config option" do
      Chef::Config[:rest_timeout] = 10
      @http_mock.should_receive(:read_timeout=).with(10).and_return(true)
      do_run_request
    end
    
    it "should set the cookie for this request if one exists for the given host:port" do
      @rest.cookies = { "#{@url_mock.host}:#{@url_mock.port}" => "cookie monster" }
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar", 
        { 'Accept' => 'application/json', 'Cookie' => 'cookie monster' }
      ).and_return(@request_mock)
      do_run_request
      @rest.cookies = Hash.new
    end
    
    it "should build a new HTTP GET request" do
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar", 
        { 'Accept' => 'application/json' }
      ).and_return(@request_mock)
      do_run_request
    end
    
    it "should build a new HTTP POST request" do
      Net::HTTP::Post.should_receive(:new).with("/?foo=bar", 
        { 'Accept' => 'application/json', "Content-Type" => 'application/json' }
      ).and_return(@request_mock)
      do_run_request(:POST, @data_mock)
    end
    
    it "should build a new HTTP PUT request" do
      Net::HTTP::Put.should_receive(:new).with("/?foo=bar", 
        { 'Accept' => 'application/json', "Content-Type" => 'application/json' }
      ).and_return(@request_mock)
      do_run_request(:PUT, @data_mock)
    end
    
    it "should build a new HTTP DELETE request" do
      Net::HTTP::Delete.should_receive(:new).with("/?foo=bar", 
        { 'Accept' => 'application/json' }
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
      Net::HTTP::Get.should_receive(:new).with("/?foo=bar", {}).and_return(@request_mock)
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

