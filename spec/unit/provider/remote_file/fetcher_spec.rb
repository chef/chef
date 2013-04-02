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

describe Chef::Provider::RemoteFile::Fetcher do

  let(:current_resource) { mock("current resource") }
  let(:new_resource) { mock("new resource") }
  let(:fetcher_instance) { mock("fetcher") }

  describe "when passed an http url" do
    let(:uri) { mock("uri", :scheme => "http" ) }
    before do
      Chef::Provider::RemoteFile::HTTP.should_receive(:new).and_return(fetcher_instance)
    end
    it "returns an http fetcher" do
      described_class.for_resource(uri, new_resource, current_resource).should == fetcher_instance
    end
  end

  describe "when passed an https url" do
    let(:uri) { mock("uri", :scheme => "https" ) }
    before do
      Chef::Provider::RemoteFile::HTTP.should_receive(:new).and_return(fetcher_instance)
    end
    it "returns an http fetcher" do
      described_class.for_resource(uri, new_resource, current_resource).should == fetcher_instance
    end
  end

  describe "when passed an ftp url" do
    let(:uri) { mock("uri", :scheme => "ftp" ) }
    before do
      Chef::Provider::RemoteFile::FTP.should_receive(:new).and_return(fetcher_instance)
    end
    it "returns an ftp fetcher" do
      described_class.for_resource(uri, new_resource, current_resource).should == fetcher_instance
    end
  end

  describe "when passed a file url" do
    let(:uri) { mock("uri", :scheme => "file" ) }
    before do
      Chef::Provider::RemoteFile::LocalFile.should_receive(:new).and_return(fetcher_instance)
    end
    it "returns a localfile fetcher" do
      described_class.for_resource(uri, new_resource, current_resource).should == fetcher_instance
    end
  end

  describe "when passed a url we do not recognize" do
    let(:uri) { mock("uri", :scheme => "xyzzy" ) }
    it "throws an ArgumentError exception" do
      lambda { described_class.for_resource(uri, new_resource, current_resource) }.should raise_error(ArgumentError)
    end
  end

end

