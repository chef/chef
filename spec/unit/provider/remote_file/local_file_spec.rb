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

  let(:uri) { URI.parse("file:///nyan_cat.png") }

  let(:new_resource) { Chef::Resource::RemoteFile.new("local file backend test (new_resource)") }
  let(:current_resource) { Chef::Resource::RemoteFile.new("local file backend test (current_resource)") }
  subject(:fetcher) { Chef::Provider::RemoteFile::LocalFile.new(uri, new_resource, current_resource) }

  context "when first created" do

    context "and the current resource has no source" do

      it "stores the uri it is passed" do
        fetcher.uri.should == uri
      end

      it "stores the new_resource" do
        fetcher.new_resource.should == new_resource
      end

      it "stores nil for the last_modified date" do
        fetcher.last_modified.should == nil
      end
    end

    context "and the current resource has a source" do

      before do
        current_resource.source("file:///nyan_cat.png")
      end

      context "and use_last_modified is enabled" do
        before do
          new_resource.use_last_modified(true)
        end

        it "stores the last_modified string when the voodoo matches" do
          Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(uri, current_resource.source[0]).and_return(true)
          current_resource.stub!(:last_modified).and_return(Time.new)
          fetcher.last_modified.should == current_resource.last_modified
        end
      end

      describe "and use_last_modified is disabled in the new_resource" do
        before do
          new_resource.use_last_modified(false)
        end

        it "stores nil for the last_modified date" do
          current_resource.stub!(:last_modified).and_return(Time.new)
          fetcher.last_modified.should == nil
        end
      end

    end

  end

  describe "when fetching the object" do

    let(:now) { Time.now }

    before do
      current_resource.source("file:///nyan_cat.png")
      new_resource.use_last_modified(true)
      current_resource.stub!(:last_modified).and_return(now)
      Chef::Provider::RemoteFile::Util.should_receive(:uri_matches_string?).with(uri, current_resource.source[0]).and_return(true)
    end

    context "and the source has not been modified" do
      before do
        ::File.stub!(:mtime).and_return(now)
      end

      it "returns nil tempfile when the source file has not been modified" do
        result = fetcher.fetch
        result.raw_file.should be_nil
        result.etag.should be_nil
        result.mtime.should == now
      end
    end

    context "and the source has been modified" do
      let(:tempfile) { mock("Tempfile", :path => "/tmp/nyan.png") }
      let(:chef_tempfile) { mock("Chef::FileContentManagement::Tempfile", :tempfile => tempfile) }

      before do
        ::File.stub!(:mtime).and_return(now + 10)
      end

      it "calls Chef::FileContentManagement::Tempfile to get a tempfile" do
        Chef::FileContentManagement::Tempfile.should_receive(:new).with(new_resource).and_return(chef_tempfile)
        ::FileUtils.should_receive(:cp).with(uri.path, tempfile.path)

        result = fetcher.fetch
        result.raw_file.should == tempfile
        result.etag.should be_nil
        result.mtime.should == (now + 10)
      end
    end

  end

end
