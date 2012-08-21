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

  it "says its provider is CookbookFile when the source is a relative URI" do
    @resource.source('seattle.txt')
    @resource.provider.should == Chef::Provider::CookbookFile
    Chef::Platform.find_provider(:noplatform, 'noversion', @resource).should == Chef::Provider::CookbookFile
  end
  
  it "says its provider is RemoteFile when the source is an array of URIs" do
    @resource.source([ 'http://www.google.com/robots.txt', 'http://stackoverflow.com/robots.txt' ])
    @resource.provider.should == Chef::Provider::RemoteFile
    Chef::Platform.find_provider(:noplatform, 'noversion', @resource).should == Chef::Provider::RemoteFile
  end
  
  it "should ignore cookbook files (local files) when using an array of URIs" do
    @resource.source([ 'http://www.google.com/robots.txt', 'seattle.txt', 'http://stackoverflow.com/robots.txt' ])
    @resource.provider.should == Chef::Provider::RemoteFile
    @resource.source.should eql([ 'http://www.google.com/robots.txt', 'http://stackoverflow.com/robots.txt' ])
  end

  describe "source" do
    it "should accept a string for the remote file source" do
      @resource.source "something"
      @resource.source.should eql("something")
    end

    it "should have a default based on the param name" do
      @resource.source.should eql("fakey_fakerton")
    end

    it "should use only the basename of the file as the default" do
      r = Chef::Resource::RemoteFile.new("/tmp/obit/fakey_fakerton")
      r.source.should eql("fakey_fakerton")
    end
  end
  
  describe "cookbook" do
    it "should accept a string for the cookbook name" do
      @resource.cookbook "something"
      @resource.cookbook.should eql("something")
    end
    
    it "should default to nil" do
      @resource.cookbook.should == nil
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
