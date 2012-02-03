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

describe Chef::Resource::File do

  before(:each) do
    @resource = Chef::Resource::File.new("fakey_fakerton")
  end

  it "should have a name" do
    @resource.name.should eql("fakey_fakerton")
  end

  it "should have a default action of 'create'" do
    @resource.action.should eql("create")
  end

  it "should have a default content of nil" do
    @resource.content.should be_nil
  end

  it "should be set to back up 5 files by default" do
    @resource.backup.should eql(5)
  end

  it "should only accept strings for content" do
    lambda { @resource.content 5 }.should raise_error(ArgumentError)
    lambda { @resource.content :foo }.should raise_error(ArgumentError)
    lambda { @resource.content "hello" => "there" }.should raise_error(ArgumentError)
    lambda { @resource.content "hi" }.should_not raise_error(ArgumentError)
  end

  it "should only accept false or a number for backup" do
    lambda { @resource.backup true }.should raise_error(ArgumentError)
    lambda { @resource.backup false }.should_not raise_error(ArgumentError)
    lambda { @resource.backup 10 }.should_not raise_error(ArgumentError)
    lambda { @resource.backup "blues" }.should raise_error(ArgumentError)
  end

  it "should accept a sha256 for checksum" do
    lambda { @resource.checksum "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa" }.should_not raise_error(ArgumentError)
    lambda { @resource.checksum "monkey!" }.should raise_error(ArgumentError)
  end

  it "should accept create, delete or touch for action" do
    lambda { @resource.action :create }.should_not raise_error(ArgumentError)
    lambda { @resource.action :delete }.should_not raise_error(ArgumentError)
    lambda { @resource.action :touch }.should_not raise_error(ArgumentError)
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

  describe "when it has a path, owner, group, mode, and checksum" do
    before do
      @resource.path("/tmp/foo.txt")
      @resource.owner("root")
      @resource.group("wheel")
      @resource.mode("0644")
      @resource.checksum("1" * 64)
    end

    it "describes its state" do
      state = @resource.state
      state[:owner].should == "root"
      state[:group].should == "wheel"
      state[:mode].should == "0644"
      state[:checksum].should == "1" * 64
    end

    it "returns the file path as its identity" do
      @resource.identity.should == "/tmp/foo.txt"
    end

  end


end
