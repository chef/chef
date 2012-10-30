#
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>);
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

describe Chef::Resource::Group, "initialize" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end  

  it "should create a new Chef::Resource::Group" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Group)
  end

  it "should set the resource_name to :group" do
    @resource.resource_name.should eql(:group)
  end
  
  it "should set the group_name equal to the argument to initialize" do
    @resource.group_name.should eql("admin")
  end

  it "should default gid to nil" do
    @resource.gid.should eql(nil)
  end
  
  it "should default members to an empty array" do
    @resource.members.should eql([])
  end

  it "should alias users to members, also an empty array" do
    @resource.users.should eql([])
  end
  
  it "should set action to :create" do
    @resource.action.should eql(:create)
  end
  
  %w{create remove modify manage}.each do |action|
    it "should allow action #{action}" do
      @resource.allowed_actions.detect { |a| a == action.to_sym }.should eql(action.to_sym)
    end
  end
end

describe Chef::Resource::Group, "group_name" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow a string" do
    @resource.group_name "pirates"
    @resource.group_name.should eql("pirates")
  end

  it "should not allow a hash" do
    lambda { @resource.send(:group_name, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "gid" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow an integer" do
    @resource.gid 100
    @resource.gid.should eql(100)
  end

  it "should not allow a hash" do
    lambda { @resource.send(:gid, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "members" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  [ :users, :members].each do |method|
    it "(#{method}) should allow and convert a string" do
      @resource.send(method, "aj")
      @resource.send(method).should eql(["aj"])
    end

    it "(#{method}) should allow an array" do
      @resource.send(method, [ "aj", "adam" ])
      @resource.send(method).should eql( ["aj", "adam"] )
    end

    it "(#{method}) should not allow a hash" do
      lambda { @resource.send(method, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
    end
  end
end

describe Chef::Resource::Group, "append" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end
  
  it "should default to false" do
    @resource.append.should eql(false)
  end
  
  it "should allow a boolean" do
    @resource.append true
    @resource.append.should eql(true)
  end

  it "should not allow a hash" do
    lambda { @resource.send(:gid, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
  end
 
  describe "when it has members" do
    before do 
      @resource.group_name("pokemon")
      @resource.members(["blastoise", "pikachu"])
    end

    it "describes its state" do
      state = @resource.state
      state[:members].should eql(["blastoise", "pikachu"])
    end

    it "returns the group name as its identity" do
      @resource.identity.should == "pokemon"
    end
  end
end
