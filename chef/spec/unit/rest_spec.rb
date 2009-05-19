#
# Author:: Adam Jacob (<adam@opscode.com>)
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

describe Chef::REST, "initialize method" do
  it "should create a new Chef::REST" do
    Chef::REST.new("url").should be_kind_of(Chef::REST)
  end
end

describe Chef::REST, "get_rest method" do
  it "should create a url from the path and base url" do
    URI.should_receive(:parse).with("url/monkey")
    r = Chef::REST.new("url")
    r.stub!(:run_request)
    r.get_rest("monkey")
  end
  
  it "should call run_request :GET with the composed url object" do
    URI.stub!(:parse).and_return(true)
    r = Chef::REST.new("url")
    r.should_receive(:run_request).with(:GET, true, false, 10, false).and_return(true)
    r.get_rest("monkey")
  end
end

describe Chef::REST, "delete_rest method" do
  it "should create a url from the path and base url" do
    URI.should_receive(:parse).with("url/monkey")
    r = Chef::REST.new("url")
    r.stub!(:run_request)
    r.delete_rest("monkey")
  end
  
  it "should call run_request :DELETE with the composed url object" do
    URI.stub!(:parse).and_return(true)
    r = Chef::REST.new("url")
    r.should_receive(:run_request).with(:DELETE, true).and_return(true)
    r.delete_rest("monkey")
  end
end

describe Chef::REST, "post_rest method" do
  it "should create a url from the path and base url" do
    URI.should_receive(:parse).with("url/monkey")
    r = Chef::REST.new("url")
    r.stub!(:run_request)
    r.post_rest("monkey", "data")
  end
  
  it "should call run_request :POST with the composed url object and data" do
    URI.stub!(:parse).and_return(true)
    r = Chef::REST.new("url")
    r.should_receive(:run_request).with(:POST, true, "data").and_return(true)
    r.post_rest("monkey", "data")
  end
end

describe Chef::REST, "put_rest method" do
  it "should create a url from the path and base url" do
    URI.should_receive(:parse).with("url/monkey")
    r = Chef::REST.new("url")
    r.stub!(:run_request)
    r.put_rest("monkey", "data")
  end
  
  it "should call run_request :PUT with the composed url object and data" do
    URI.stub!(:parse).and_return(true)
    r = Chef::REST.new("url")
    r.should_receive(:run_request).with(:PUT, true, "data").and_return(true)
    r.put_rest("monkey", "data")
  end
end

describe Chef::REST, "run_request method" do
  before(:each) do
    Chef::REST::CookieJar.stub!(:instance).and_return({})
    @r = Chef::REST.new("url")
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
    @r.run_request(method, @url_mock, data, limit, raw)
  end
  
  it "should raise an exception if the redirect limit is 0" do
    lambda { @r.run_request(:GET, "/", false, 0)}.should raise_error(ArgumentError)
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
    @r.cookies = { "#{@url_mock.host}:#{@url_mock.port}" => "cookie monster" }
    Net::HTTP::Get.should_receive(:new).with("/?foo=bar", 
      { 'Accept' => 'application/json', 'Cookie' => 'cookie monster' }
    ).and_return(@request_mock)
    do_run_request
  end
  
  it "should build a new HTTP GET request" do
    Net::HTTP::Get.should_receive(:new).with("/?foo=bar", 
      { 'Accept' => 'application/json' }
    ).and_return(@request_mock)
    do_run_request
  end
  
  it "should build a new HTTP POST request" do
    Net::HTTP::Post.should_receive(:new).with("/", 
      { 'Accept' => 'application/json', "Content-Type" => 'application/json' }
    ).and_return(@request_mock)
    do_run_request(:POST, @data_mock)
  end
  
  it "should build a new HTTP PUT request" do
    Net::HTTP::Put.should_receive(:new).with("/", 
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
