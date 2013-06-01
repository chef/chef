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

describe Chef::Resource::User, "initialize" do
  before(:each) do
    @resource = Chef::Resource::User.new("adam")
  end  

  it "should create a new Chef::Resource::User" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::User)
  end

  it "should set the resource_name to :user" do
    @resource.resource_name.should eql(:user)
  end
  
  it "should set the username equal to the argument to initialize" do
    @resource.username.should eql("adam")
  end
  
  %w{comment uid gid home shell password}.each do |attrib|
    it "should set #{attrib} to nil" do
      @resource.send(attrib).should eql(nil)
    end
  end
  
  it "should set action to :create" do
    @resource.action.should eql(:create)
  end
  
  it "should set supports[:manage_home] to false" do
    @resource.supports[:manage_home].should eql(false)
  end
  
  it "should set supports[:non_unique] to false" do
    @resource.supports[:non_unique].should eql(false)
  end
  
  %w{create remove modify manage lock unlock}.each do |action|
    it "should allow action #{action}" do
      @resource.allowed_actions.detect { |a| a == action.to_sym }.should eql(action.to_sym)
    end
  end

  it "should accept domain users (@ or \ separator) on non-windows" do
    lambda { @resource.username "domain\@user" }.should_not raise_error(ArgumentError)
    @resource.username.should == "domain\@user"
    lambda { @resource.username "domain\\user" }.should_not raise_error(ArgumentError)
    @resource.username.should  == "domain\\user"
  end
end

%w{username comment home shell password}.each do |attrib|
  describe Chef::Resource::User, attrib do
    before(:each) do
      @resource = Chef::Resource::User.new("adam")
    end  

    it "should allow a string" do
      @resource.send(attrib, "adam")
      @resource.send(attrib).should eql("adam")
    end

    it "should not allow a hash" do
      lambda { @resource.send(attrib, { :woot => "i found it" }) }.should raise_error(ArgumentError)
    end
  end
end

%w{uid gid}.each do |attrib|
  describe Chef::Resource::User, attrib do
    before(:each) do
      @resource = Chef::Resource::User.new("adam")
    end  

    it "should allow a string" do
      @resource.send(attrib, "100")
      @resource.send(attrib).should eql("100")
    end
    
    it "should allow an integer" do
      @resource.send(attrib, 100)
      @resource.send(attrib).should eql(100)
    end

    it "should not allow a hash" do
      lambda { @resource.send(attrib, { :woot => "i found it" }) }.should raise_error(ArgumentError)
    end
  end
  
  describe "when it has uid, gid, and home" do
    before do
      @resource = Chef::Resource::User.new("root")
      @resource.uid(123)
      @resource.gid(456)
      @resource.home("/usr/local/root/")
    end

    it "describes its state" do
      state = @resource.state
      state[:uid].should == 123
      state[:gid].should == 456
      state[:home].should == "/usr/local/root/"
    end

    it "returns the username as its identity" do
      @resource.identity.should == "root"
    end
  end

end
