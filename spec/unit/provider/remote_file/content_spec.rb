#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

  let(:run_context) { mock("Chef::RunContext") }

  #
  # subject
  #
  let(:content) do
    Chef::Provider::RemoteFile::Content.new(new_resource, current_resource, run_context)
  end

  describe "when the checksum of the current_resource matches the checksum set on the resource" do
    before do
      new_resource.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      current_resource.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end

    it "should return nil for the tempfile" do
      content.tempfile.should be_nil
    end

    it "should not call any fetcher" do
      Chef::Provider::RemoteFile::Fetcher.should_not_receive(:for_resource)
    end
  end

  describe "when the checksum of the current_resource is a partial match for the checksum set on the resource" do
    before do
      new_resource.stub!(:checksum).and_return("0fd012fd")
      current_resource.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end

    it "should return nil for the tempfile" do
      content.tempfile.should be_nil
    end

    it "should not call any fetcher" do
      Chef::Provider::RemoteFile::Fetcher.should_not_receive(:for_resource)
    end
  end

  shared_examples_for "the resource needs fetching" do
    before do
      # FIXME: test one or the other nil, test both not nil and not equal, abuse the regexp a little
      @uri = mock("URI")
      URI.should_receive(:parse).with(new_resource.source[0]).and_return(@uri)
    end

    describe "when the fetcher returns nil for the tempfile" do
      before do
        http_fetcher = mock("Chef::Provider::RemoteFile::HTTP", :fetch => nil)
        Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri, new_resource, current_resource).and_return(http_fetcher)
      end

      it "should return nil for the tempfile" do
        content.tempfile.should be_nil
      end
    end

    describe "when the fetcher returns a valid tempfile" do

      let(:mtime) { Time.now }
      let(:tempfile) { mock("Tempfile") }
      let(:http_fetcher) { mock("Chef::Provider::RemoteFile::HTTP", :fetch => tempfile) }

      before do
        Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri, new_resource, current_resource).and_return(http_fetcher)
      end

      it "should return the tempfile object to the caller" do
        content.tempfile.should == tempfile
      end

    end
  end
  describe "when the checksum are both nil" do
    before do
      new_resource.checksum.should be_nil
      current_resource.checksum.should be_nil
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the current_resource checksum is nil" do
    before do
      new_resource.stub!(:checksum).and_return("fd012fd")
      current_resource.stub!(:checksum).and_return(nil)
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the new_resource checksum is nil" do
    before do
      new_resource.stub!(:checksum).and_return(nil)
      current_resource.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end
    it_behaves_like "the resource needs fetching"
  end

  describe "when the checksums are a partial match, but not to the leading portion" do
    before do
      new_resource.stub!(:checksum).and_return("fd012fd")
      current_resource.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    end
    it_behaves_like "the resource needs fetching"
  end


  describe "when the fetcher throws an exception" do
    before do
      new_resource.stub!(:checksum).and_return(nil)
      current_resource.stub!(:checksum).and_return(nil)
      @uri = mock("URI")
      URI.should_receive(:parse).with(new_resource.source[0]).and_return(@uri)
      http_fetcher = mock("Chef::Provider::RemoteFile::HTTP")
      http_fetcher.should_receive(:fetch).and_raise(Errno::ECONNREFUSED)
      Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri, new_resource, current_resource).and_return(http_fetcher)
    end

    it "should propagate the error back to the caller" do
      lambda { content.tempfile }.should raise_error(Errno::ECONNREFUSED)
    end
  end

  describe "when there is an array of sources and the first fails" do

    let(:source) { [ "http://opscode.com/seattle.txt", "http://opscode.com/nyc.txt" ] }
    before do
      new_resource.stub!(:checksum).and_return(nil)
      current_resource.stub!(:checksum).and_return(nil)
      @uri0 = mock("URI0")
      @uri1 = mock("URI1")
      URI.should_receive(:parse).with(new_resource.source[0]).and_return(@uri0)
      URI.should_receive(:parse).with(new_resource.source[1]).and_return(@uri1)
      @http_fetcher_throws_exception = mock("Chef::Provider::RemoteFile::HTTP")
      @http_fetcher_throws_exception.should_receive(:fetch).at_least(:once).and_raise(Errno::ECONNREFUSED)
      Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri0, new_resource, current_resource).and_return(@http_fetcher_throws_exception)
    end

    describe "when the second url succeeds" do
      before do
        @tempfile = mock("Tempfile")
        mtime = Time.now
        http_fetcher_works = mock("Chef::Provider::RemoteFile::HTTP", :fetch => @tempfile)
        Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri1, new_resource, current_resource).and_return(http_fetcher_works)
      end

      it "should return a valid tempfile" do
        content.tempfile.should == @tempfile
      end

      it "should not mutate the new_resource" do
        content.tempfile
        new_resource.source.length.should == 2
      end
    end

    describe "when both urls fail" do
      before do
        Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri1, new_resource, current_resource).and_return(@http_fetcher_throws_exception)
      end

      it "should propagate the error back to the caller" do
        lambda { content.tempfile }.should raise_error(Errno::ECONNREFUSED)
      end
    end
  end

  describe "when there is an array of sources and the first succeeds" do
    let(:source) { [ "http://opscode.com/seattle.txt", "http://opscode.com/nyc.txt" ] }
    before do
      new_resource.stub!(:checksum).and_return(nil)
      current_resource.stub!(:checksum).and_return(nil)
      @uri0 = mock("URI0")
      URI.should_receive(:parse).with(new_resource.source[0]).and_return(@uri0)
      URI.should_not_receive(:parse).with(new_resource.source[1])
      @tempfile = mock("Tempfile")
      mtime = Time.now
      http_fetcher_works = mock("Chef::Provider::RemoteFile::HTTP", :fetch => @tempfile)
      Chef::Provider::RemoteFile::Fetcher.should_receive(:for_resource).with(@uri0, new_resource, current_resource).and_return(http_fetcher_works)
    end

    it "should return a valid tempfile" do
      content.tempfile.should == @tempfile
    end

    it "should not mutate the new_resource" do
      content.tempfile
      new_resource.source.length.should == 2
    end
  end

end

