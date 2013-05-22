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

  let(:uri) { URI.parse("http://www.google.com/robots.txt") }


  subject(:cache_control_data) do
    Chef::Provider::RemoteFile::CacheControlData.load_and_validate(uri, current_file_checksum)
  end

  let(:cache_path) { "remote_file/http___www_google_com_robots_txt-9839677abeeadf0691026e0cabca2339.json" }

  # the checksum of the file we have on disk already
  let(:current_file_checksum) { "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" }

  context "when loading data for an unknown URI" do

    before do
      Chef::FileCache.should_receive(:load).with(cache_path).and_raise(Chef::Exceptions::FileNotFound, "nope")
    end

    context "and there is no current copy of the file" do
      let(:current_file_checksum) { nil }

      it "returns empty cache control data" do
        cache_control_data.etag.should be_nil
        cache_control_data.mtime.should be_nil
      end
    end

    it "returns empty cache control data" do
      cache_control_data.etag.should be_nil
      cache_control_data.mtime.should be_nil
    end
  end

  describe "when loading data for a known URI" do

    # the checksum of the file last we fetched it.
    let(:last_fetched_checksum) { "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" }

    let(:etag) { "\"a-strong-identifier\"" }
    let(:mtime) { "Tue, 21 May 2013 19:19:23 GMT" }

    let(:cache_json_data) do
      cache = {}
      cache["etag"] = etag
      cache["mtime"] = mtime
      cache["checksum"] = last_fetched_checksum
      cache.to_json
    end

    before do
      Chef::FileCache.should_receive(:load).with(cache_path).and_return(cache_json_data)
    end

    context "and there is no on-disk copy of the file" do
      let(:current_file_checksum) { nil }

      it "returns empty cache control data" do
        cache_control_data.etag.should be_nil
        cache_control_data.mtime.should be_nil
      end
    end

    context "and the cached checksum does not match the on-disk copy" do
      let(:current_file_checksum) { "e2a8938cc31754f6c067b35aab1d0d4864272e9bf8504536ef3e79ebf8432305" }

      it "returns empty cache control data" do
        cache_control_data.etag.should be_nil
        cache_control_data.mtime.should be_nil
      end
    end

    context "and the cached checksum matches the on-disk copy" do

      it "populates the cache control data" do
        cache_control_data.etag.should == etag
        cache_control_data.mtime.should == mtime
      end
    end
  end

  describe "when saving to disk" do

    let(:etag) { "\"a-strong-identifier\"" }
    let(:mtime) { "Tue, 21 May 2013 19:19:23 GMT" }
    let(:fetched_file_checksum) { "e2a8938cc31754f6c067b35aab1d0d4864272e9bf8504536ef3e79ebf8432305" }

    let(:expected_serialization_data) do
      data = {}
      data["etag"] = etag
      data["mtime"] = mtime
      data["checksum"] = fetched_file_checksum
      data
    end

    before do
      cache_control_data.etag = etag
      cache_control_data.mtime = mtime
      cache_control_data.checksum = fetched_file_checksum
    end

    it "serializes its attributes to JSON" do
      # we have to test this separately because ruby 1.8 hash order is unstable
      # so we can't count on the order of the keys in the json format.

      json_data = cache_control_data.json_data
      Chef::JSONCompat.from_json(json_data).should == expected_serialization_data
    end

    it "writes data to the cache" do
      json_data = cache_control_data.json_data
      Chef::FileCache.should_receive(:store).with(cache_path, json_data)
      cache_control_data.save
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
    current_resource.checksum(current_resource_checksum)
    current_resource
  end

  let(:new_resource) do
    Chef::Resource::RemoteFile.new("/tmp/foo.txt")
  end

  subject(:fetcher) do
    Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
  end

  let(:cache_control_data) { Chef::Provider::RemoteFile::CacheControlData.new(uri) }

  describe "generating cache control headers" do

    context "and there is no valid cache control data for this URI on disk" do

      before do
        Chef::Provider::RemoteFile::CacheControlData.should_receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
      end

      it "does not add conditional GET headers" do
        fetcher.conditional_get_headers.should == {}
      end

      context "and the resource specifies custom headers" do
        before do
          new_resource.headers("x-myapp-header" => "custom-header-value")
        end

        it "has the user-specified custom headers" do
          fetcher.headers.should == {"x-myapp-header" => "custom-header-value"}
        end
      end

    end

    context "and the cache control data matches the existing file" do

      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.26
      let(:etag) { "\"a-strong-unique-identifier\"" }

      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3
      let(:mtime) { "Tue, 21 May 2013 19:19:23 GMT" }

      before do
        cache_control_data.etag = etag
        cache_control_data.mtime = mtime

        Chef::Provider::RemoteFile::CacheControlData.should_receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
      end

      context "and no conditional get features are enabled" do
        before do
          new_resource.use_conditional_get(false)
        end

        it "does not add headers to the request" do
          fetcher.headers.should == {}
        end
      end

      context "and conditional get is enabled" do
        before do
          new_resource.use_conditional_get(true)
        end

        it "adds If-None-Match and If-Modified-Since headers to the request" do
          headers = fetcher.headers
          headers["if-none-match"].should == etag
          headers["if-modified-since"].should == mtime
        end

        context "and custom headers are provided" do
          before do
            new_resource.headers("x-myapp-header" => "app-specific-header",
                                 "if-none-match" => "custom-etag",
                                 "if-modified-since" => "custom-last-modified")
          end

          it "preserves non-conflicting headers" do
            fetcher.headers["x-myapp-header"].should == "app-specific-header"
          end

          it "prefers user-supplied cache control headers" do
            headers = fetcher.headers
            headers["if-none-match"].should == "custom-etag"
            headers["if-modified-since"].should == "custom-last-modified"
          end
        end

      end

      context "and etag support is enabled" do
        before do
          new_resource.use_conditional_get(false)
          new_resource.use_etags(true)
        end

        it "only adds If-None-Match headers to the request" do
          headers = fetcher.headers
          headers["if-none-match"].should == etag
          headers.should_not have_key("if-modified-since")
        end
      end

      context "and mtime support is enabled" do
        before do
          new_resource.use_conditional_get(false)
          new_resource.use_last_modified(true)
        end

        it "only adds If-Modified-Since headers to the request" do
          headers = fetcher.headers
          headers["if-modified-since"].should == mtime
          headers.should_not have_key("if-none-match")
        end
      end
    end

  end

  describe "when fetching the uri" do

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
      new_resource.headers({})
      new_resource.use_last_modified(false)
      Chef::Provider::RemoteFile::CacheControlData.should_receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)

      Chef::REST.should_receive(:new).with(*expected_http_args).and_return(rest)
    end


    describe "and the request does not return new content" do

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

    end

    describe "and the request returns new content" do
      before do
        cache_control_data.should_receive(:save)
      end

      it "should return a result" do
        result = fetcher.fetch
        result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
        result.raw_file.should == tempfile
        cache_control_data.etag.should be_nil
        cache_control_data.mtime.should be_nil
      end

      context "and the response does not contain an etag" do
        let(:last_response) { {"etag" => nil} }
        it "does not include an etag in the result" do
          result = fetcher.fetch
          result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
          result.etag.should be_nil
          cache_control_data.etag.should be_nil
          cache_control_data.mtime.should be_nil
        end
      end

      context "and the response has an etag header" do
        let(:last_response) { {"etag" => "abc123"} }

        it "includes the etag value in the response" do
          result = fetcher.fetch
          result.raw_file.should == tempfile
          result.etag.should == "abc123"
          cache_control_data.etag.should == "abc123"
          cache_control_data.mtime.should be_nil
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
          cache_control_data.etag.should be_nil
          cache_control_data.mtime.should be_nil
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
          result.mtime.should  == last_response["last_modified"]
          cache_control_data.etag.should be_nil
          cache_control_data.mtime.should == last_response["last_modified"]
        end
      end

      context "and the response has a Date header but no Last-Modified header" do
        let(:last_response) do
          {"date" => "Fri, 17 May 2013 23:23:23 GMT", "last_modified" => nil}
        end

        it "sets the mtime to the Date in the response" do
          result = fetcher.fetch
          result.should be_a_kind_of(Chef::Provider::RemoteFile::Result)
          result.mtime.should  == last_response["date"]
          cache_control_data.etag.should be_nil
          cache_control_data.mtime.should == last_response["date"]
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
          cache_control_data.etag.should be_nil
          cache_control_data.mtime.should be_nil
        end
      end
    end

  end

end

