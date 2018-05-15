#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

describe Chef::Provider::RemoteFile::Content do

  #
  # mock setup
  #

  let(:current_resource) do
    Chef::Resource::RemoteFile.new("remote-file-content-spec (current resource)")
  end

  let(:source) { [ "http://opscode.com/seattle.txt" ] }

  let(:new_resource) do
    r = Chef::Resource::RemoteFile.new("remote-file-content-spec (current resource)")
    r.source(source)
    r
  end

  let(:run_context) { double("Chef::RunContext") }

  #
  # subject
  #
  let(:content) do
    Chef::Provider::RemoteFile::Content.new(new_resource, current_resource, run_context)
  end

  describe "when the checksum of the current_resource matches the checksum set on the resource" do
    before do
      allow(new_resource).to receive(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      allow(current_resource).to receive(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end

    it "should return nil for the tempfile" do
      expect(content.tempfile).to be_nil
    end

    it "should not call any fetcher" do
      expect(Chef::Provider::RemoteFile::Fetcher).not_to receive(:for_resource)
    end
  end

  describe "when the checksum of the current_resource is a partial match for the checksum set on the resource" do
    before do
      allow(new_resource).to receive(:checksum).and_return("0fd012fd")
      allow(current_resource).to receive(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end

    it "should return nil for the tempfile" do
      expect(content.tempfile).to be_nil
    end

    it "should not call any fetcher" do
      expect(Chef::Provider::RemoteFile::Fetcher).not_to receive(:for_resource)
    end
  end

  shared_examples_for "the resource needs fetching" do
    before do
      # FIXME: test one or the other nil, test both not nil and not equal, abuse the regexp a little
      @uri = double("URI")
      expect(URI).to receive(:parse).with(new_resource.source[0]).and_return(@uri)
    end

    describe "when the fetcher returns nil for the tempfile" do
      before do
        http_fetcher = double("Chef::Provider::RemoteFile::HTTP", :fetch => nil)
        expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri, new_resource, current_resource).and_return(http_fetcher)
      end

      it "should return nil for the tempfile" do
        expect(content.tempfile).to be_nil
      end
    end

    describe "when the fetcher returns a valid tempfile" do

      let(:mtime) { Time.now }
      let(:tempfile) { double("Tempfile") }
      let(:http_fetcher) { double("Chef::Provider::RemoteFile::HTTP", :fetch => tempfile) }

      before do
        expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri, new_resource, current_resource).and_return(http_fetcher)
      end

      it "should return the tempfile object to the caller" do
        expect(content.tempfile).to eq(tempfile)
      end

    end
  end
  describe "when the checksum are both nil" do
    before do
      expect(new_resource.checksum).to be_nil
      expect(current_resource.checksum).to be_nil
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the current_resource checksum is nil" do
    before do
      allow(new_resource).to receive(:checksum).and_return("fd012fd")
      allow(current_resource).to receive(:checksum).and_return(nil)
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the new_resource checksum is nil" do
    before do
      allow(new_resource).to receive(:checksum).and_return(nil)
      allow(current_resource).to receive(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the checksums are a partial match, but not to the leading portion" do
    before do
      allow(new_resource).to receive(:checksum).and_return("fd012fd")
      allow(current_resource).to receive(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the fetcher throws an exception" do
    before do
      allow(new_resource).to receive(:checksum).and_return(nil)
      allow(current_resource).to receive(:checksum).and_return(nil)
      @uri = double("URI")
      expect(URI).to receive(:parse).with(new_resource.source[0]).and_return(@uri)
      http_fetcher = double("Chef::Provider::RemoteFile::HTTP")
      expect(http_fetcher).to receive(:fetch).and_raise(Errno::ECONNREFUSED)
      expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri, new_resource, current_resource).and_return(http_fetcher)
    end

    it "should propagate the error back to the caller" do
      expect { content.tempfile }.to raise_error(Errno::ECONNREFUSED)
    end
  end

  describe "when there is an array of sources and the first fails" do

    # https://github.com/chef/chef/pull/1358#issuecomment-40853299
    def create_exception(exception_class)
      if [ Net::HTTPServerException, Net::HTTPFatalError ].include? exception_class
        exception_class.new("message", { "something" => 1 })
      else
        exception_class.new
      end
    end

    let(:source) { [ "http://opscode.com/seattle.txt", "http://opscode.com/nyc.txt" ] }

    ### Test each exception we care about and make sure they all behave properly
    [
      SocketError,
      Errno::ECONNREFUSED,
      Errno::ENOENT,
      Errno::EACCES,
      Timeout::Error,
      Net::HTTPServerException,
      Net::HTTPFatalError,
      Net::FTPError,
      Errno::ETIMEDOUT,
    ].each do |exception|
      describe "with an exception of #{exception}" do
        before do
          allow(new_resource).to receive(:checksum).and_return(nil)
          allow(current_resource).to receive(:checksum).and_return(nil)
          @uri0 = double("URI0")
          @uri1 = double("URI1")
          expect(URI).to receive(:parse).with(new_resource.source[0]).and_return(@uri0)
          expect(URI).to receive(:parse).with(new_resource.source[1]).and_return(@uri1)
          @http_fetcher_throws_exception = double("Chef::Provider::RemoteFile::HTTP")
          expect(@http_fetcher_throws_exception).to receive(:fetch).at_least(:once).and_raise(create_exception(exception))
          expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri0, new_resource, current_resource).and_return(@http_fetcher_throws_exception)
        end

        describe "the second url should succeed" do
          before do
            @tempfile = double("Tempfile")
            mtime = Time.now
            http_fetcher_works = double("Chef::Provider::RemoteFile::HTTP", :fetch => @tempfile)
            expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri1, new_resource, current_resource).and_return(http_fetcher_works)
          end

          it "should return a valid tempfile" do
            expect(content.tempfile).to eq(@tempfile)
          end

          it "should not mutate the new_resource" do
            content.tempfile
            expect(new_resource.source.length).to eq(2)
          end
        end

        describe "when both urls fail" do
          before do
            expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri1, new_resource, current_resource).and_return(@http_fetcher_throws_exception)
          end

          it "should propagate the error back to the caller" do
            expect { content.tempfile }.to raise_error(exception)
          end
        end
      end
    end
  end

  describe "when there is an array of sources and the first succeeds" do
    let(:source) { [ "http://opscode.com/seattle.txt", "http://opscode.com/nyc.txt" ] }
    before do
      allow(new_resource).to receive(:checksum).and_return(nil)
      allow(current_resource).to receive(:checksum).and_return(nil)
      @uri0 = double("URI0")
      expect(URI).to receive(:parse).with(new_resource.source[0]).and_return(@uri0)
      expect(URI).not_to receive(:parse).with(new_resource.source[1])
      @tempfile = double("Tempfile")
      mtime = Time.now
      http_fetcher_works = double("Chef::Provider::RemoteFile::HTTP", :fetch => @tempfile)
      expect(Chef::Provider::RemoteFile::Fetcher).to receive(:for_resource).with(@uri0, new_resource, current_resource).and_return(http_fetcher_works)
    end

    it "should return a valid tempfile" do
      expect(content.tempfile).to eq(@tempfile)
    end

    it "should not mutate the new_resource" do
      content.tempfile
      expect(new_resource.source.length).to eq(2)
    end
  end

end
