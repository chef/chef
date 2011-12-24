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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::RemoteFile, "action_create" do
  before(:each) do
    @resource = Chef::Resource::RemoteFile.new("seattle")
    @resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "seattle.txt")))
    @resource.source("http://foo")
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::RemoteFile.new(@resource, @run_context)
  end

  describe "when checking if the file is at the target version" do
    it "considers the current file to be at the target version if it exists and matches the user-provided checksum" do
      @provider.current_resource = @resource.dup
      @resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.current_resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.current_resource_matches_target_checksum?.should be_true
    end
  end

  describe "when fetching the file from the remote" do
    before(:each) do
      @tempfile = Tempfile.new("chef-rspec-remote_file_spec-line#{__LINE__}--")

      @rest = mock(Chef::REST, { })
      Chef::REST.stub!(:new).and_return(@rest)
      @rest.stub!(:fetch).and_yield(@tempfile)

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
        lambda {@provider.action_create}.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
      end
    end

    describe "and the resource specifies a checksum" do

      describe "and the existing file matches the checksum exactly" do
        before do
          @resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
        end

        it "does not download the file" do
          @rest.should_not_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
          @provider.action_create
        end

        it "does not update the resource" do
          @provider.action_create
          @provider.new_resource.should_not be_updated
        end

      end

      describe "and the existing file matches the given partial checksum" do
        before do
          @resource.checksum("0fd012fd")
        end

        it "should not download the file if the checksum is a partial match from the beginning" do
          @rest.should_not_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
          @provider.action_create
        end

        it "does not update the resource" do
          @provider.action_create
          @provider.new_resource.should_not be_updated
        end

      end

      describe "and the existing file doesn't match the given checksum" do
        it "downloads the file" do
          @resource.checksum("this hash doesn't match")
          @rest.should_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
          @provider.action_create
        end

        it "does not consider the checksum a match if the matching string is offset" do
          # i.e., the existing file is      "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa"
          @resource.checksum("fd012fd")
          @rest.should_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
          @provider.action_create
        end
      end

    end

    describe "and the resource doesn't specify a checksum" do
      it "should download the file from the remote URL" do
        @resource.checksum(nil)
        @rest.should_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
        @provider.action_create
      end
    end

    it "should raise an exception if it's any other kind of retriable response than 304" do
      r = Net::HTTPMovedPermanently.new("one", "two", "three")
      e = Net::HTTPRetriableError.new("301", r)
      @rest.stub!(:fetch).and_raise(e)
      lambda { @provider.action_create }.should raise_error(Net::HTTPRetriableError)
    end

    it "should raise an exception if anything else happens" do
      r = Net::HTTPBadRequest.new("one", "two", "three")
      e = Net::HTTPServerException.new("fake exception", r)
      @rest.stub!(:fetch).and_raise(e)
      lambda { @provider.action_create }.should raise_error(Net::HTTPServerException)
    end

    it "should checksum the raw file" do
      @provider.should_receive(:checksum).with(@tempfile.path).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.action_create
    end

    describe "when the target file does not exist" do
      before do
        ::File.stub!(:exists?).with(@resource.path).and_return(false)
        @provider.stub!(:get_from_server).and_return(@tempfile)
      end

      it "should copy the raw file to the new resource" do
        FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)
        @provider.action_create
      end

      it "should set the new resource to updated" do
        @provider.action_create
        @resource.should be_updated
      end
    end

    describe "when the target file already exists" do
      before do
        ::File.stub!(:exists?).with(@resource.path).and_return(true)
        @provider.stub!(:get_from_server).and_return(@tempfile)
      end

      describe "and the file downloaded from the remote is identical to the current" do
        it "shouldn't backup the original file" do
          @provider.should_not_receive(:backup).with(@resource.path)
          @provider.action_create
        end

        it "doesn't mark the resource as updated" do
          @provider.action_create
          @provider.new_resource.should_not be_updated
        end
      end

      describe "and the checksum doesn't match" do
        before do
          sha2_256 = "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa-NO_MATCHY"
          @provider.current_resource.checksum(sha2_256)
        end

        it "should backup the original file" do
          @provider.should_receive(:backup).with(@resource.path).and_return(true)
          @provider.action_create
        end

        it "should copy the raw file to the new resource" do
          FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)
          @provider.action_create
        end

        it "should set the new resource to updated" do
          @provider.action_create
          @resource.should be_updated
        end
      end

      it "should set permissions" do
        @provider.should_receive(:enforce_ownership_and_permissions).and_return(true)
        @provider.action_create
      end


    end

  end
end
