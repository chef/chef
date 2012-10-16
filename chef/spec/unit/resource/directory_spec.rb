#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

describe Chef::Resource::Directory do

  before(:each) do
    @resource = Chef::Resource::Directory.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::Directory" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Directory)
  end

  it "should have a name" do
    @resource.name.should eql("fakey_fakerton")
  end

  it "should have a default action of 'create'" do
    @resource.action.should eql(:create)
  end

  it "should accept create or delete for action" do
    lambda { @resource.action :create }.should_not raise_error(ArgumentError)
    lambda { @resource.action :delete }.should_not raise_error(ArgumentError)
    lambda { @resource.action :blues }.should raise_error(ArgumentError)
  end

  it "should use the object name as the path by default" do
    @resource.path.should eql("fakey_fakerton")
  end

  it "should accept a string as the path" do
    lambda { @resource.path "/tmp" }.should_not raise_error(ArgumentError)
    @resource.path.should eql("/tmp")
    lambda { @resource.path Hash.new }.should raise_error(ArgumentError)
  end

  it "should allow you to have specify whether the action is recursive with true/false" do
    lambda { @resource.recursive true }.should_not raise_error(ArgumentError)
    lambda { @resource.recursive false }.should_not raise_error(ArgumentError)
    lambda { @resource.recursive "monkey" }.should raise_error(ArgumentError)
  end

  describe "when it has group, mode, and owner" do
    before do 
      @resource.path("/tmp/foo/bar/")
      @resource.group("wheel")
      @resource.mode("0664")
      @resource.owner("root")
    end

    it "describes its state" do
      state = @resource.state
      state[:group].should == "wheel"
      state[:mode].should == "0664"
      state[:owner].should == "root"
    end

    it "returns the directory path as its identity" do
      @resource.identity.should == "/tmp/foo/bar/"
    end
  end
end
