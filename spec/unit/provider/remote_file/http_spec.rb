#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Lamont Granquist
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

describe Chef::Provider::RemoteFile::CacheControlData do
  context "when loading data for an unknown URI" do
    it "returns empty cache control data" do
      pending
    end
  end

  describe "when loading data for a known URI" do
    before do
      # setup or stub: cache file exists
    end

    context "and the cached checksum does not match the on-disk copy" do
      before do
        # setup or stub: cache data has a checksum that != checksum passed to constructor
      end

      it "either deletes or ignores the cached data" do
        pending
      end
    end

    context "and the cached checksum matches the on-disk copy" do
      before do
        # setup or stub: cache data has a checksum that != checksum passed to constructor
      end

      it "populates the cache control data" do
        pending
      end
    end
  end

  describe "when saving to disk" do
    it "writes data to the cache" do
      pending
    end
  end

end

describe Chef::Provider::RemoteFile::HTTP do

  let(:uri) { URI.parse("http://opscode.com/seattle.txt") }

  let(:existing_file_source) { nil }

  let(:current_resource_checksum) { "41e78735319af11327e9d2ca8535ea1c191e5ac1f76bb08d88fe6c3f93a8c8e5" }

  let(:current_resource) do
    current_resource = Chef::Resource::RemoteFile.new("/tmp/foo.txt")
    current_resource.source(existing_file_source) if existing_file_source
    current_resource.last_modified(Time.new)
    current_resource.etag(nil)
    current_resource.checksum(current_resource_checksum)
    current_resource
  end

  let(:new_resource) do
    new_resource = Chef::Resource::RemoteFile.new("/tmp/foo.txt")
    new_resource.headers({})
    new_resource
  end

  def use_last_modified!
    new_resource.use_last_modified(true)
    current_resource.last_modified(Time.new)
    current_resource.etag(nil)
  end

  def use_etags!
    new_resource.use_etag(true)
    new_resource.use_last_modified(false)
    current_resource.last_modified(Time.new)
    current_resource.etag("a_unique_identifier")
  end

  describe "when loading cache control data" do
    let(:cache_control_data) { Chef::Provider::RemoteFile::CacheControlData.new }

    subject(:fetcher) do
      Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
    end

    context "and there is no valid cache control data for this URI on disk" do

      before do
        Chef::Provider::RemoteFile::CacheControlData.should_receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
      end

      it "does not add conditional GET headers" do
        fetcher.conditional_get_headers.should == {}
      end
    end

    context "and the cache control data matches the existing file" do

      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.26
      let(:etag) { "\"a-strong-unique-identifier\"" }
      let(:mtime) { "Tue, 21 May 2013 19:19:23 GMT" }
      before do
        cache_control_data.etag = etag
        cache_control_data.mtime = mtime

        Chef::Provider::RemoteFile::CacheControlData.should_receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
      end

      context "and no conditional get features are enabled" do
        it "does not add headers to the request" do
          fetcher.conditional_get_headers.should == {}
        end
      end

      context "and conditional get is enabled" do
        before do
          new_resource.use_conditional_get(true)
        end

        it "adds If-None-Match and If-Modified-Since headers to the request" do
          headers = fetcher.conditional_get_headers
          headers["if-none-match"].should == etag
          headers["if-modified-since"].should == mtime
        end

      end

      context "and etag support is enabled" do
        before do
          new_resource.use_etags(true)
        end

        it "only adds If-None-Match headers to the request" do
          headers = fetcher.conditional_get_headers
          headers["if-none-match"].should == etag
          headers.should_not have_key("if-modified-since")
        end
      end

      context "and mtime support is enabled" do
        before do
          new_resource.use_last_modified(true)
        end

        it "only adds If-Modified-Since headers to the request" do
          headers = fetcher.conditional_get_headers
          headers["if-modified-since"].should == mtime
          headers.should_not have_key("if-none-match")
        end
      end
    end

  end

  describe "when contructing the object" do
    describe "when the current resource has no source" do

      it "stores the uri it is passed" do
        fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
        fetcher.uri.should == uri
      end

      it "stores any headers it is passed" do
        headers = { "foo" => "foo", "bar" => "bar", "baz" => "baz" }
        new_resource.headers(headers)
        fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
        fetcher.headers.should == headers
      end

    end

    context "when the existing file was fetched from a different URI" do
      let(:existing_file_source) { ["http://opscode.com/tukwila.txt"] }

      it "does not set a last modified header" do
        use_last_modified!
        fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
        fetcher.headers.should_not have_key('if-none-match')
        fetcher.headers.should_not have_key('if-modified-since')
      end

      it "does not set an etag header" do
        use_etags!
        fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
        fetcher.headers.should_not have_key('if-none-match')
        fetcher.headers.should_not have_key('if-modified-since')
      end
    end

    context "when the current file was fetched from the current URI" do
      let(:existing_file_source) { ["http://opscode.com/seattle.txt"] }

      context "and using If-Modified-Since" do
        before do
          use_last_modified!
        end

        it "stores the last_modified string in the headers" do
          fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
          fetcher.headers['if-modified-since'].should == current_resource.last_modified.strftime("%a, %d %b %Y %H:%M:%S %Z")
          fetcher.headers.should_not have_key('if-none-match')
          pending("http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.4")
        end
      end

      context "and using etags" do
        before do
          use_etags!
        end

        it "stores the etag string in the headers" do
          fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
          fetcher.headers['if-none-match'].should == "\"#{current_resource.etag}\""
          fetcher.headers.should_not have_key('if-modified-since')
          pending("http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.4")
        end
      end

    end

    describe "when use_last_modified is disabled in the new_resource" do

      it "stores nil for the last_modified date" do
        current_resource.stub!(:source).and_return(["http://opscode.com/seattle.txt"])
        new_resource.should_receive(:use_last_modified).and_return(false)
        current_resource.stub!(:last_modified).and_return(Time.new)
        current_resource.stub!(:etag).and_return(nil)
        Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(uri, current_resource.source[0]).and_return(true)
        fetcher = Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
        fetcher.headers.should_not have_key('if-modified-since')
        fetcher.headers.should_not have_key('if-none-match')
      end
    end

  end

  describe "when fetching the uri" do
    let(:fetcher) do
      Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(uri, current_resource.source[0]).and_return(true)
      Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
    end

    let(:expected_http_opts) { {} }
    let(:expected_http_args) { [uri, nil, nil, expected_http_opts] }

    let(:tempfile) { mock(Tempfile) }

    let(:last_response) { {} }

    let(:rest) do
      rest = mock(Chef::REST)
      rest.stub!(:streaming_request).and_return(tempfile)
      rest.stub!(:last_response).and_return(last_response)
      rest
    end

    before do
      new_resource.should_receive(:headers).and_return({})
      new_resource.should_receive(:use_last_modified).and_return(false)

      Chef::REST.should_receive(:new).with(*expected_http_args).and_return(rest)
    end

    it "should return a result" do
      result = fetcher.fetch
      result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
      result.raw_file.should == tempfile
    end

    it "should propagate non-304 exceptions to the caller" do
      r = Net::HTTPBadRequest.new("one", "two", "three")
      e = Net::HTTPServerException.new("fake exception", r)
      rest.stub!(:streaming_request).and_raise(e)
      lambda { fetcher.fetch }.should raise_error(Net::HTTPServerException)
    end

    it "should return HTTPRetriableError when Chef::REST returns a 301" do
      r = Net::HTTPMovedPermanently.new("one", "two", "three")
      e = Net::HTTPRetriableError.new("301", r)
      rest.stub!(:streaming_request).and_raise(e)
      lambda { fetcher.fetch }.should raise_error(Net::HTTPRetriableError)
    end

    it "should return a nil tempfile for a 304 HTTPNotModifed" do
      r = Net::HTTPNotModified.new("one", "two", "three")
      e = Net::HTTPRetriableError.new("304", r)
      rest.stub!(:streaming_request).and_raise(e)
      result = fetcher.fetch
      result.raw_file.should be_nil
    end

    context "and the response does not contain an etag" do
      let(:last_response) { {"etag" => nil} }
      it "does not include an etag in the result" do
        result = fetcher.fetch
        result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
        result.etag.should be_nil
      end
    end

    context "and the response has an etag header" do
      let(:last_response) { {"etag" => "abc123"} }

      it "includes the etag value in the response" do
        result = fetcher.fetch
        result.raw_file.should == tempfile
        result.etag.should == "abc123"
      end

    end

    context "and the response has no Date or Last-Modified header" do
      let(:last_response) { {"date" => nil, "last_modified" => nil} }
      it "does not set an mtime in the result" do
        # RFC 2616 suggests that servers that do not set a Date header do not
        # have a reliable clock, so no use in making them deal with dates.
        result = fetcher.fetch
        result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
        result.mtime.should be_nil
      end
    end

    context "and the response has a Last-Modified header" do
      let(:last_response) do
        # Last-Modified should be preferred to Date if both are set
        {"date" => "Fri, 17 May 2013 23:23:23 GMT", "last_modified" => "Fri, 17 May 2013 11:11:11 GMT"}
      end

      it "sets the mtime to the Last-Modified time in the response" do
        result = fetcher.fetch
        result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
        result.mtime.should  == Time.at(1368789071).utc
      end
    end

    context "and the response has a Date header but no Last-Modified header" do
      let(:last_response) do
        {"date" => "Fri, 17 May 2013 23:23:23 GMT", "last_modified" => nil}
      end

      it "sets the mtime to the Date in the response" do
        result = fetcher.fetch
        result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
        result.mtime.should  == Time.at(1368833003).utc
      end

    end

    context "and the target file is a tarball [CHEF-3140]" do

      let(:uri) { URI.parse("http://opscode.com/tarball.tgz") }
      let(:expected_http_opts) { {:disable_gzip => true} }

      # CHEF-3140
      # Some servers return tarballs as content type tar and encoding gzip, which
      # is totally wrong. When this happens and gzip isn't disabled, Chef::REST
      # will decompress the file for you, which is not at all what you expected
      # to happen (you end up with an uncomressed tar archive instead of the
      # gzipped tar archive you expected). To work around this behavior, we
      # detect when users are fetching gzipped files and turn off gzip in
      # Chef::REST.

      it "should disable gzip compression in the client" do
        # Before block in the parent context has set an expectation on
        # Chef::REST.new() being called with expected arguments. Here we fufil
        # that expectation, so that we can explicitly set it for this test.
        # This is intended to provide insurance that refactoring of the parent
        # context does not negate the value of this particular example.
        Chef::REST.new(*expected_http_args)
        Chef::REST.should_receive(:new).once.with(*expected_http_args).and_return(rest)
        fetcher.fetch
      end
    end
  end

end

