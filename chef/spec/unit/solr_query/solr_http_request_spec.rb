# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, inc.
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

require File.expand_path('../../../spec_helper', __FILE__)

require 'chef/solr_query'
require 'net/http'

describe Chef::SolrQuery::SolrHTTPRequest do
  before do
    Chef::Config[:solr_url] = "http://example.com:8983"
    Chef::SolrQuery::SolrHTTPRequest.instance_variable_set(:@solr_url, nil)
    Chef::SolrQuery::SolrHTTPRequest.instance_variable_set(:@url_prefix, nil)

    @request = Chef::SolrQuery::SolrHTTPRequest.new(:GET, '/solr/select')
  end

  it "defaults to using the configured solr_url" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url.should == "http://example.com:8983"
  end

  it "supports solr_url with a path" do
    Chef::Config[:solr_url] = "http://example.com:8983/test"
    Chef::SolrQuery::SolrHTTPRequest.instance_variable_set(:@solr_url, nil)

    Chef::SolrQuery::SolrHTTPRequest.solr_url.should == "http://example.com:8983/test"
  end

  it "updates the Solr URL as you like" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234"
    Chef::SolrQuery::SolrHTTPRequest.solr_url.should == "http://chunkybacon.org:1234"
  end

  it "updates the URL prefix with a path" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234/something"
    Chef::SolrQuery::SolrHTTPRequest.url_prefix.should == "/something"
  end

  it "removes extra / at the end of solr_url" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234/extra/"
    Chef::SolrQuery::SolrHTTPRequest.url_prefix.should == "/extra"
  end

  it "creates a Net::HTTP client for the base Solr URL" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234"
    http_client = Chef::SolrQuery::SolrHTTPRequest.http_client
    http_client.address.should == "chunkybacon.org"
    http_client.port.should == 1234
  end

  it "creates a Net::HTTP client for the base Solr URL ignoring the path" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234/test"
    http_client = Chef::SolrQuery::SolrHTTPRequest.http_client
    http_client.address.should == "chunkybacon.org"
    http_client.port.should == 1234
  end

  it "defaults url_prefix to /solr if the configured solr_url has no path" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234"
    Chef::SolrQuery::SolrHTTPRequest.url_prefix.should == "/solr"
  end

  it "defaults url_prefix to the path from the configured solr_url" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234/test"
    Chef::SolrQuery::SolrHTTPRequest.url_prefix.should == "/test"
  end

  describe "when configured with the Solr URL" do
    before do
      @http_response = mock(
        "Net::HTTP::Response",
        :kind_of? => Net::HTTPSuccess,
        :body => "{ :some => :hash }"
      )
      @http_request = mock(
        "Net::HTTP::Request",
        :body= => true
      )
      @http = mock("Net::HTTP", :request => @http_response)
      Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
    end

    describe "when executing a select query" do
      before(:each) do
        @http_response = mock(
          "Net::HTTP::Response",
          :kind_of? => Net::HTTPSuccess,
          :body => '{"some": "hash" }'
        )
        @solr = Chef::SolrQuery.from_params(:type => 'node',
                                            :q => "hostname:latte")
        @params = @solr.to_hash
        @http = mock("Net::HTTP", :request => @http_response)
        Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
      end

      describe "when the HTTP call is successful" do
        it "should call get to /solr/select with the escaped query" do
          txfm_query = "q=content%3Ahostname__%3D__latte"
          Net::HTTP::Get.should_receive(:new).with(%r(/solr/select?.+#{txfm_query}))
          Chef::SolrQuery::SolrHTTPRequest.select(@params)
        end

        it "uses Solr's JSON response format" do
          Net::HTTP::Get.should_receive(:new).with(%r(wt=json))
          Chef::SolrQuery::SolrHTTPRequest.select(@params)
        end

        it "uses indent=off to get a compact response" do
          Net::HTTP::Get.should_receive(:new).with(%r(indent=off))
          Chef::SolrQuery::SolrHTTPRequest.select(@params)
        end

        it "uses the filter query to restrict the result set" do
          filter_query =@solr.filter_query.gsub('+', '%2B').gsub(':', "%3A").gsub(' ', '+')
          Net::HTTP::Get.should_receive(:new).with(/fq=#{Regexp.escape(filter_query)}/)
          Chef::SolrQuery::SolrHTTPRequest.select(@params)
        end

        it "returns the evaluated response body" do
          res = Chef::SolrQuery::SolrHTTPRequest.select(@params)
          res.should == {"some" => "hash" }
        end
      end
    end

    describe "when updating" do
      before do
        Net::HTTP::Post.stub!(:new).and_return(@http_request)
      end

      it "should post to /solr/update" do
        @doc = "<xml is the old tldr>"
        Net::HTTP::Post.should_receive(:new).with("/solr/update", "Content-Type" => "text/xml").and_return(@http_request)
        Chef::SolrQuery::SolrHTTPRequest.update(@doc)
      end

      it "should set the body of the request to the stringified doc" do
        @http_request.should_receive(:body=).with("foo")
        Chef::SolrQuery::SolrHTTPRequest.update(:foo)
      end

      it "should send the request to solr" do
        @http.should_receive(:request).with(@http_request).and_return(@http_response)
        Chef::SolrQuery::SolrHTTPRequest.update(:foo)
      end

    end

    describe "when the HTTP call is unsuccessful" do
      [Timeout::Error, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EINVAL].each do |exception|
        it "should rescue, log an error message, and raise a SolrConnectionError encountering exception #{exception}" do
          response = mock("Net:HTTPResponse test double", :code => 500, :message => "oops", :class => exception)
          @http.should_receive(:request).with(instance_of(Net::HTTP::Get)).and_return(response)
          response.should_receive(:error!).and_raise(exception)
          Chef::Log.should_receive(:fatal).with("Search Query to Solr failed (#{exception} 500 oops)")

          lambda {@request.run('Search Query to Solr')}.should raise_error(Chef::Exceptions::SolrConnectionError)
        end
      end

      it "should rescue, log an error message, and raise a SolrConnectionError when encountering exception NoMethodError and net/http closed? bug" do
        @no_method_error = NoMethodError.new("undefined method 'closed\?' for nil:NilClass")
        @http.should_receive(:request).with(instance_of(Net::HTTP::Get)).and_raise(@no_method_error)
        Chef::Log.should_receive(:fatal).with("HTTP Request to Solr failed.  Chef::Exceptions::SolrConnectionError exception: Errno::ECONNREFUSED (net/http undefined method closed?) attempting to contact http://example.com:8983")
        lambda {
          @request.run
        }.should raise_error(Chef::Exceptions::SolrConnectionError)
      end
    end

  end

  describe "when configured with the Solr URL with a path" do
    before do
      Chef::Config[:solr_url] = "http://example.com:8983/test"
      Chef::SolrQuery::SolrHTTPRequest.instance_variable_set(:@solr_url, nil)
      Chef::SolrQuery::SolrHTTPRequest.instance_variable_set(:@url_prefix, nil)

      @request = Chef::SolrQuery::SolrHTTPRequest.new(:GET, '/solr/select')

      @http_response = mock(
        "Net::HTTP::Response",
        :kind_of? => Net::HTTPSuccess,
        :body => "{ :some => :hash }"
      )
      @http_request = mock(
        "Net::HTTP::Request",
        :body= => true
      )
      @http = mock("Net::HTTP", :request => @http_response)
      Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
    end

    describe "when executing a select query" do
      before(:each) do
        @http_response = mock(
          "Net::HTTP::Response",
          :kind_of? => Net::HTTPSuccess,
          :body => '{"some": "hash" }'
        )
        @solr = Chef::SolrQuery.from_params(:type => 'node',
                                            :q => "hostname:latte")
        @params = @solr.to_hash
        @http = mock("Net::HTTP", :request => @http_response)
        Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
      end

      describe "when the HTTP call is successful" do
        it "should call get to /test/select with the escaped query" do
          txfm_query = "q=content%3Ahostname__%3D__latte"
          Net::HTTP::Get.should_receive(:new).with(%r(/test/select?.+#{txfm_query}))
          Chef::SolrQuery::SolrHTTPRequest.select(@params)
        end
      end
    end

    describe "when updating" do
      before do
        Net::HTTP::Post.stub!(:new).and_return(@http_request)
      end

      it "should post to /test/update" do
        @doc = "<xml is the old tldr>"
        Net::HTTP::Post.should_receive(:new).with("/test/update", "Content-Type" => "text/xml").and_return(@http_request)
        Chef::SolrQuery::SolrHTTPRequest.update(@doc)
      end
    end
  end
end
