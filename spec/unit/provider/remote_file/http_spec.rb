#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Lamont Granquist
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
        expect(Chef::Provider::RemoteFile::CacheControlData).to receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
      end

      it "does not add conditional GET headers" do
        expect(fetcher.conditional_get_headers).to eq({})
      end

      context "and the resource specifies custom headers" do
        before do
          new_resource.headers("x-myapp-header" => "custom-header-value")
        end

        it "has the user-specified custom headers" do
          expect(fetcher.headers).to eq({ "x-myapp-header" => "custom-header-value" })
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

        expect(Chef::Provider::RemoteFile::CacheControlData).to receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
      end

      context "and no conditional get features are enabled" do
        before do
          new_resource.use_conditional_get(false)
        end

        it "does not add headers to the request" do
          expect(fetcher.headers).to eq({})
        end
      end

      context "and conditional get is enabled" do
        before do
          new_resource.use_conditional_get(true)
        end

        it "adds If-None-Match and If-Modified-Since headers to the request" do
          headers = fetcher.headers
          expect(headers["if-none-match"]).to eq(etag)
          expect(headers["if-modified-since"]).to eq(mtime)
        end

        context "and custom headers are provided" do
          before do
            new_resource.headers("x-myapp-header" => "app-specific-header",
                                 "if-none-match" => "custom-etag",
                                 "if-modified-since" => "custom-last-modified")
          end

          it "preserves non-conflicting headers" do
            expect(fetcher.headers["x-myapp-header"]).to eq("app-specific-header")
          end

          it "prefers user-supplied cache control headers" do
            headers = fetcher.headers
            expect(headers["if-none-match"]).to eq("custom-etag")
            expect(headers["if-modified-since"]).to eq("custom-last-modified")
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
          expect(headers["if-none-match"]).to eq(etag)
          expect(headers).not_to have_key("if-modified-since")
        end
      end

      context "and mtime support is enabled" do
        before do
          new_resource.use_conditional_get(false)
          new_resource.use_last_modified(true)
        end

        it "only adds If-Modified-Since headers to the request" do
          headers = fetcher.headers
          expect(headers["if-modified-since"]).to eq(mtime)
          expect(headers).not_to have_key("if-none-match")
        end
      end
    end

  end

  describe "when fetching the uri" do

    let(:expected_http_opts) { {} }
    let(:expected_http_args) { [uri, expected_http_opts] }

    let(:tempfile_path) { "/tmp/chef-mock-tempfile-abc123" }

    let(:tempfile) { double(Tempfile, :path => tempfile_path, :close => nil) }

    let(:last_response) { {} }

    let(:event_dispatcher) do
      event_dispatcher = double(Chef::EventDispatch::Dispatcher)
      allow(event_dispatcher).to receive(:formatter?).and_return(false)
      event_dispatcher
    end

    let(:rest) do
      rest = double(Chef::HTTP::Simple)
      allow(rest).to receive(:streaming_request).and_return(tempfile)
      allow(rest).to receive(:last_response).and_return(last_response)
      rest
    end

    before do
      new_resource.headers({})
      new_resource.use_last_modified(false)
      allow(new_resource).to receive(:events).and_return(event_dispatcher)
      expect(Chef::Provider::RemoteFile::CacheControlData).to receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)

      expect(Chef::HTTP::Simple).to receive(:new).with(*expected_http_args).and_return(rest)
    end

    describe "and the request does not return new content" do

      it "should return a nil tempfile for a 304 HTTPNotModifed" do
        # Streaming request returns nil for 304 errors
        allow(rest).to receive(:streaming_request).and_return(nil)
        expect(fetcher.fetch).to be_nil
      end

    end

    describe "and the request returns new content" do

      let(:fetched_content_checksum) { "e2a8938cc31754f6c067b35aab1d0d4864272e9bf8504536ef3e79ebf8432305" }

      before do
        expect(cache_control_data).to receive(:save)
        expect(Chef::Digester).to receive(:checksum_for_file).with(tempfile_path).and_return(fetched_content_checksum)
      end

      it "should return a tempfile" do
        result = fetcher.fetch
        expect(result).to eq(tempfile)
        expect(cache_control_data.etag).to be_nil
        expect(cache_control_data.mtime).to be_nil
        expect(cache_control_data.checksum).to eq(fetched_content_checksum)
      end

      context "with progress reports" do
        before do
          Chef::Config[:show_download_progress] = true
        end

        it "should yield its progress" do
          allow(rest).to receive(:streaming_request_with_progress).and_yield(50, 100).and_yield(70, 100).and_return(tempfile)
          expect(event_dispatcher).to receive(:formatter?).and_return(true)
          expect(event_dispatcher).to receive(:resource_update_progress).with(new_resource, 50, 100, 10).ordered
          expect(event_dispatcher).to receive(:resource_update_progress).with(new_resource, 70, 100, 10).ordered
          fetcher.fetch
        end
      end

      context "and the response does not contain an etag" do
        let(:last_response) { { "etag" => nil } }
        it "does not include an etag in the result" do
          fetcher.fetch
          expect(cache_control_data.etag).to be_nil
          expect(cache_control_data.mtime).to be_nil
          expect(cache_control_data.checksum).to eq(fetched_content_checksum)
        end
      end

      context "and the response has an etag header" do
        let(:last_response) { { "etag" => "abc123" } }

        it "includes the etag value in the response" do
          fetcher.fetch
          expect(cache_control_data.etag).to eq("abc123")
          expect(cache_control_data.mtime).to be_nil
          expect(cache_control_data.checksum).to eq(fetched_content_checksum)
        end

      end

      context "and the response has no Date or Last-Modified header" do
        let(:last_response) { { "date" => nil, "last_modified" => nil } }
        it "does not set an mtime in the result" do
          # RFC 2616 suggests that servers that do not set a Date header do not
          # have a reliable clock, so no use in making them deal with dates.
          fetcher.fetch
          expect(cache_control_data.etag).to be_nil
          expect(cache_control_data.mtime).to be_nil
          expect(cache_control_data.checksum).to eq(fetched_content_checksum)
        end
      end

      context "and the response has a Last-Modified header" do
        let(:last_response) do
          # Last-Modified should be preferred to Date if both are set
          { "date" => "Fri, 17 May 2013 23:23:23 GMT", "last_modified" => "Fri, 17 May 2013 11:11:11 GMT" }
        end

        it "sets the mtime to the Last-Modified time in the response" do
          fetcher.fetch
          expect(cache_control_data.etag).to be_nil
          expect(cache_control_data.mtime).to eq(last_response["last_modified"])
        end
      end

      context "and the response has a Date header but no Last-Modified header" do
        let(:last_response) do
          { "date" => "Fri, 17 May 2013 23:23:23 GMT", "last_modified" => nil }
        end

        it "sets the mtime to the Date in the response" do
          fetcher.fetch
          expect(cache_control_data.etag).to be_nil
          expect(cache_control_data.mtime).to eq(last_response["date"])
          expect(cache_control_data.checksum).to eq(fetched_content_checksum)
        end

      end

      context "and the target file is a tarball [CHEF-3140]" do

        let(:uri) { URI.parse("http://opscode.com/tarball.tgz") }
        let(:expected_http_opts) { { :disable_gzip => true } }

        # CHEF-3140
        # Some servers return tarballs as content type tar and encoding gzip, which
        # is totally wrong. When this happens and gzip isn't disabled, Chef::HTTP::Simple
        # will decompress the file for you, which is not at all what you expected
        # to happen (you end up with an uncomressed tar archive instead of the
        # gzipped tar archive you expected). To work around this behavior, we
        # detect when users are fetching gzipped files and turn off gzip in
        # Chef::HTTP::Simple.

        it "should disable gzip compression in the client" do
          # Before block in the parent context has set an expectation on
          # Chef::HTTP::Simple.new() being called with expected arguments. Here we fufil
          # that expectation, so that we can explicitly set it for this test.
          # This is intended to provide insurance that refactoring of the parent
          # context does not negate the value of this particular example.
          Chef::HTTP::Simple.new(*expected_http_args)
          expect(Chef::HTTP::Simple).to receive(:new).once.with(*expected_http_args).and_return(rest)
          fetcher.fetch
          expect(cache_control_data.etag).to be_nil
          expect(cache_control_data.mtime).to be_nil
          expect(cache_control_data.checksum).to eq(fetched_content_checksum)
        end
      end
    end

  end

end
