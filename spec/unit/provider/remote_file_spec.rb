#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

require 'support/shared/unit/provider/file'


describe Chef::Provider::RemoteFile do
  let(:resource) do
    resource = Chef::Resource::RemoteFile.new("seattle", @run_context)
    resource.path(resource_path)
    resource.source("http://foo")
    resource
  end

  before(:each) do
    ::File.stub!(:exists?).with("#{Chef::Config[:file_cache_path]}/remote_file/#{resource.name}").and_return(false)
  end

  let(:content) do
    content = mock('Chef::Provider::File::Content::RemoteFile')
  end

  let(:node) { double('Chef::Node') }
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:enclosing_directory) { File.expand_path(File.join(CHEF_SPEC_DATA, "templates")) }
  let(:resource_path) { File.expand_path(File.join(enclosing_directory, "seattle.txt")) }

  # Subject

  let(:provider) do
    provider = described_class.new(resource, run_context)
    provider.stub!(:content).and_return(content)
    provider.stub!(:update_new_resource_checksum).and_return(nil) # XXX: otherwise it doesn't behave like a File provider
    provider
  end

  it_behaves_like Chef::Provider::File

  describe "when fetching the file from the remote" do
    before(:each) do
      @tempfile = Tempfile.new("chef-rspec-remote_file_spec-line#{__LINE__}--")

      @rest = mock(Chef::REST, { })
      Chef::REST.stub!(:new).and_return(@rest)
      @rest.stub!(:streaming_request).and_return(@tempfile)
      @rest.stub!(:create_url) { |url| url } 
      @resource.cookbook_name = "monkey"

      @provider.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.current_resource = @resource.clone
      @provider.current_resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      File.stub!(:exists?).and_return(true)
      FileUtils.stub!(:cp).and_return(true)
      Chef::Platform.stub!(:find_platform_and_version).and_return([ :mac_os_x, "10.5.1" ])
    end

    after do
      @tempfile.close!
    end

    before do
      @resource.source("http://opscode.com/seattle.txt")
    end

    describe "and the target location's enclosing directory does not exist" do
      before do
        @resource.path("/tmp/this/path/does/not/exist/file.txt")
      end

      it "raises a specific error describing the problem" do
        lambda {@provider.run_action(:create)}.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
      end
    end

    shared_examples_for "source specified with multiple URIs" do
      it "should try to download the next URI when the first one fails" do
        @rest.should_receive(:streaming_request).with("http://foo", {}).once.and_raise(SocketError)
        @rest.should_receive(:streaming_request).with("http://bar", {}).once.and_return(@tempfile)
        @provider.run_action(:create)
      end

      it "should raise an exception when all the URIs fail" do
        @rest.should_receive(:streaming_request).with("http://foo", {}).once.and_raise(SocketError)
        @rest.should_receive(:streaming_request).with("http://bar", {}).once.and_raise(SocketError)
        lambda { @provider.run_action(:create) }.should raise_error(SocketError)
      end

      it "should download from only one URI when the first one works" do
        @rest.should_receive(:streaming_request).once.and_return(@tempfile)
        @provider.run_action(:create)
      end

    end

    describe "and the source specifies multiple URIs using multiple arguments" do
      it_should_behave_like "source specified with multiple URIs"

      before(:each) do
        @resource.source("http://foo", "http://bar")
      end
    end

    describe "and the source specifies multiple URIs using an array" do
      it_should_behave_like "source specified with multiple URIs"

      before(:each) do
        @resource.source([ "http://foo", "http://bar" ])
      end
    end

    describe "and the resource specifies a checksum" do

      describe "and the existing file matches the checksum exactly" do
        before do
          @resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
        end

        it "does not download the file" do
          @rest.should_not_receive(:fetch).with("http://opscode.com/seattle.txt")
          @provider.run_action(:create)
        end

        it "does not update the resource" do
          @provider.run_action(:create)
          @provider.new_resource.should_not be_updated
        end

      end

      describe "and the existing file matches the given partial checksum" do
        before do
          @resource.checksum("0fd012fd")
        end

        it "should not download the file if the checksum is a partial match from the beginning" do
          @rest.should_not_receive(:fetch).with("http://opscode.com/seattle.txt")
          @provider.run_action(:create)
        end

        it "does not update the resource" do
          @provider.run_action(:create)
          @provider.new_resource.should_not be_updated
        end

      end

      describe "and the existing file doesn't match the given checksum" do
        it "downloads the file" do
          @resource.checksum("this hash doesn't match")
          @rest.should_receive(:streaming_request).with("http://opscode.com/seattle.txt", {}).and_return(@tempfile)
          @provider.stub!(:update_new_file_state)
          @provider.run_action(:create)
        end

        it "does not consider the checksum a match if the matching string is offset" do
          # i.e., the existing file is      "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa"
          @resource.checksum("fd012fd")
          @rest.should_receive(:streaming_request).with("http://opscode.com/seattle.txt", {}).and_return(@tempfile)
          @provider.stub!(:update_new_file_state)
          @provider.run_action(:create)
        end
      end

    end

    describe "and the resource doesn't specify a checksum" do
      it "should download the file from the remote URL" do
        @resource.checksum(nil)
        @rest.should_receive(:streaming_request).with("http://opscode.com/seattle.txt", {}).and_return(@tempfile)
        @provider.run_action(:create)
      end
    end

    # CHEF-3140
    # Some servers return tarballs as content type tar and encoding gzip, which
    # is totally wrong. When this happens and gzip isn't disabled, Chef::REST
    # will decompress the file for you, which is not at all what you expected
    # to happen (you end up with an uncomressed tar archive instead of the
    # gzipped tar archive you expected). To work around this behavior, we
    # detect when users are fetching gzipped files and turn off gzip in
    # Chef::REST.

    context "and the target file is a tarball" do
      before do
        @resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "seattle.tar.gz")))
        Chef::REST.should_receive(:new).with("http://opscode.com/seattle.txt", nil, nil, :disable_gzip => true).and_return(@rest)
      end

      it "disables gzip in the http client" do
        @provider.action_create
      end

    end

    context "and the source appears to be a tarball" do
      before do
        @resource.source("http://example.com/tarball.tgz")
        Chef::REST.should_receive(:new).with("http://example.com/tarball.tgz", nil, nil, :disable_gzip => true).and_return(@rest)
      end

      it "disables gzip in the http client" do
        @provider.action_create
      end
    end

    it "should raise an exception if it's any other kind of retriable response than 304" do
      r = Net::HTTPMovedPermanently.new("one", "two", "three")
      e = Net::HTTPRetriableError.new("301", r)
      @rest.stub!(:streaming_request).and_raise(e)
      lambda { @provider.run_action(:create) }.should raise_error(Net::HTTPRetriableError)
    end

    it "should raise an exception if anything else happens" do
      r = Net::HTTPBadRequest.new("one", "two", "three")
      e = Net::HTTPServerException.new("fake exception", r)
      @rest.stub!(:streaming_request).and_raise(e)
      lambda { @provider.run_action(:create) }.should raise_error(Net::HTTPServerException)
    end

    it "should checksum the raw file" do
      @provider.should_receive(:checksum).with(@tempfile.path).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.run_action(:create)
    end

    describe "when the target file does not exist" do
      before do
        ::File.stub!(:exists?).with(@resource.path).and_return(false)
        @provider.stub!(:get_from_server).and_return(@tempfile)
      end

      it "should copy the raw file to the new resource" do
        FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)
        @provider.stub!(:update_new_file_state)
        @provider.run_action(:create)
      end

      it "should set the new resource to updated" do
        @provider.stub!(:update_new_file_state)
        @provider.run_action(:create)
        @resource.should be_updated
      end

      describe "and create_if_missing is invoked" do
        it "should invoke action_create" do
          @provider.should_receive(:action_create)
          @provider.run_action(:create_if_missing)
        end
      end
    end

    describe "when the target file already exists" do
      before do
        ::File.stub!(:exists?).with(@resource.path).and_return(true)
        @provider.stub!(:diff_current).and_return([
         "--- /tmp/foo  2012-08-30 21:28:17.632782551 +0000",
         "+++ /tmp/bar 2012-08-30 21:28:20.816975437 +0000",
         "@@ -1 +1 @@",
         "-foo bar",
         "+bar foo"
        ])
        @provider.stub!(:get_from_server).and_return(@tempfile)
      end

      describe "and create_if_missing is invoked" do
        it "should take no action" do
          @provider.should_not_receive(:action_create) 
          @provider.run_action(:create_if_missing)
        end
      end

      describe "and the file downloaded from the remote is identical to the current" do
        it "shouldn't backup the original file" do
          @provider.should_not_receive(:do_backup).with(@resource.path)
          @provider.run_action(:create)
        end

        it "doesn't mark the resource as updated" do
          @provider.run_action(:create)
          @provider.new_resource.should_not be_updated
        end
      end

      describe "and the checksum doesn't match" do
        before do
          sha2_256 = "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa-NO_MATCHY"
          @provider.current_resource.checksum(sha2_256)
        end

        it "should backup the original file" do
          @provider.stub!(:update_new_file_state)
          @provider.should_receive(:do_backup).with(@resource.path).and_return(true)
          @provider.run_action(:create)
        end

        it "should copy the raw file to the new resource" do
          @provider.stub!(:update_new_file_state)
          FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)
          @provider.run_action(:create)
        end
      end

    end
  end

end
