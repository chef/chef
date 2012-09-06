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

require 'spec_helper'

describe Chef::Resource::RemoteFile do

  before(:each) do
    @resource = Chef::Resource::RemoteFile.new("fakey_fakerton")
  end

  describe "initialize" do
    it "should create a new Chef::Resource::RemoteFile" do
      @resource.should be_a_kind_of(Chef::Resource)
      @resource.should be_a_kind_of(Chef::Resource::File)
      @resource.should be_a_kind_of(Chef::Resource::RemoteFile)
    end
  end

  it "says its provider is RemoteFile when the source is an absolute URI" do
    @resource.source("http://www.google.com/robots.txt")
    @resource.provider.should == Chef::Provider::RemoteFile
    Chef::Platform.find_provider(:noplatform, 'noversion', @resource).should == Chef::Provider::RemoteFile
  end


  describe "source" do
    it "does not have a default value for 'source'" do
      @resource.source.should be_nil
    end

    it "should accept a URI for the remote file source" do
      @resource.source "http://opscode.com/"
      @resource.source.should eql("http://opscode.com/")
    end

    it "does not accept a non-URI as the source" do
      lambda { @resource.source("not-a-uri") }.should raise_error(Chef::Exceptions::InvalidRemoteFileURI)
    end

  end

  describe "checksum" do
    it "should accept a string for the checksum object" do
      @resource.checksum "asdf"
      @resource.checksum.should eql("asdf")
    end

    it "should default to nil" do
      @resource.checksum.should == nil
    end
  end
  
end
