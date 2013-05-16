#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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

describe Chef::Provider::RemoteFile::LocalFile do

  before(:each) do
    @uri = URI.parse("file:///nyan_cat.png")
  end

  describe "when constructing the object" do

    before do
      @new_resource = mock('Chef::Resource::RemoteFile (new_resource)')
      @current_resource = mock('Chef::Resource::RemoteFile (current_resource)')
    end

    describe "when the current resource has no source" do
      before do
        @current_resource.should_receive(:source).and_return(nil)
      end

      it "stores the uri it is passed" do
        fetcher = Chef::Provider::RemoteFile::LocalFile.new(@uri, @new_resource, @current_resource)
        fetcher.uri.should == @uri
      end

      it "stores the new_resource" do
        fetcher = Chef::Provider::RemoteFile::LocalFile.new(@uri, @new_resource, @current_resource)
        fetcher.new_resource.should == @new_resource
      end

      it "stores nil for the last_modified date" do
        fetcher = Chef::Provider::RemoteFile::LocalFile.new(@uri, @new_resource, @current_resource)
        fetcher.last_modified.should == nil
      end
    end

    describe "when the current resource has a source" do

      it "stores the last_modified string when the voodoo matches" do
        @current_resource.stub!(:source).and_return(["file:///nyan_cat.png"])
        @new_resource.should_receive(:use_last_modified).and_return(true)
        @current_resource.stub!(:last_modified).and_return(Time.new)
        Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(@uri, @current_resource.source[0]).and_return(true)
        fetcher = Chef::Provider::RemoteFile::LocalFile.new(@uri, @new_resource, @current_resource)
        fetcher.last_modified.should == @current_resource.last_modified
      end

    end

    describe "when use_last_modified is disabled in the new_resource" do

      it "stores nil for the last_modified date" do
        @current_resource.stub!(:source).and_return(["file:///nyan_cat.png"])
        @new_resource.should_receive(:use_last_modified).and_return(false)
        @current_resource.stub!(:last_modified).and_return(Time.new)
        Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(@uri, @current_resource.source[0]).and_return(true)
        fetcher = Chef::Provider::RemoteFile::LocalFile.new(@uri, @new_resource, @current_resource)
        fetcher.last_modified.should == nil
      end
    end

  end

  describe "when fetching the object" do
    before do
      @new_resource = mock('Chef::Resource::RemoteFile (new_resource)')
      @current_resource = mock('Chef::Resource::RemoteFile (current_resource)')
      @current_resource.stub!(:source).and_return(["file:///nyan_cat.png"])
      @new_resource.should_receive(:use_last_modified).and_return(true)
      @now = Time.now
      @current_resource.stub!(:last_modified).and_return(@now)
      Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(@uri, @current_resource.source[0]).and_return(true)
      @fetcher = Chef::Provider::RemoteFile::LocalFile.new(@uri, @new_resource, @current_resource)
    end

    it "returns nil tempfile when the source file has not been modified" do
      ::File.stub!(:mtime).and_return(@now)
      @result = mock("Chef::Provider::RemoteFile::Result")
      Chef::Provider::RemoteFile::Result.should_receive(:new).with(nil, nil, @now).and_return(@result)
      @fetcher.fetch.should == @result
    end

    it "calls Chef::FileContentManagement::Tempfile to get a tempfile" do
      ::File.stub!(:mtime).and_return(@now + 10)
      @tempfile = mock("Tempfile", "path" => "/tmp/nyan.png")
      @chef_tempfile = mock("Chef::FileContentManagement::Tempfile", :tempfile => @tempfile)
      Chef::FileContentManagement::Tempfile.should_receive(:new).with(@new_resource).and_return(@chef_tempfile)
      ::FileUtils.should_receive(:cp).with(@uri.path, @tempfile.path)
      @result = mock("Chef::Provider::RemoteFile::Result")
      Chef::Provider::RemoteFile::Result.should_receive(:new).with(@tempfile, nil, @now + 10).and_return(@result)
      @fetcher.fetch.should == @result
    end

  end

end
