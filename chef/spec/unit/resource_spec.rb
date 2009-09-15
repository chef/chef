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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Resource do
  before(:each) do
    @resource = Chef::Resource.new("funk")
  end
  
  describe "initialize" do
    it "should create a new Chef::Resource" do
      @resource.should be_a_kind_of(Chef::Resource)
    end
  end
  
  describe "load_prior_resource" do
    before(:each) do
      @prior_resource = Chef::Resource.new("funk")
      @prior_resource.supports(:funky => true)
      @prior_resource.source_line
      @prior_resource.allowed_actions << :funkytown
      @prior_resource.action(:funkytown)
      @resource.allowed_actions << :funkytown
      @resource.collection << @prior_resource
    end
    
    it "should load the attributes of a prior resource" do
      @resource.load_prior_resource
      @resource.supports.should == { :funky => true }
    end
    
    it "should not inherit the action from the prior resource" do
      @resource.load_prior_resource
      @resource.action.should_not == @prior_resource.action
    end
  end

  describe "name" do
    it "should have a name" do
      @resource.name.should eql("funk")
    end
  
    it "should let you set a new name" do
      @resource.name "monkey"
      @resource.name.should eql("monkey")
    end
  
    it "should not be valid without a name" do
      lambda { @resource.name false }.should raise_error(ArgumentError)
    end
  
    it "should always have a string for name" do
      lambda { @resource.name Hash.new }.should raise_error(ArgumentError)
    end
  end
  
  describe "noop" do
    it "should accept true or false for noop" do
      lambda { @resource.noop true }.should_not raise_error(ArgumentError)
      lambda { @resource.noop false }.should_not raise_error(ArgumentError)
      lambda { @resource.noop "eat it" }.should raise_error(ArgumentError)
    end
  end
  
  describe "notifies" do
    it "should make notified resources appear in the actions hash" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @resource.resources(:zen_master => "coffee")
      @resource.actions[:reload][:delayed][0].name.should eql("coffee")
    end
  
    it "should make notified resources be capable of acting immediately" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @resource.resources(:zen_master => "coffee"), :immediate
      @resource.actions[:reload][:immediate][0].name.should eql("coffee")
    end
  
    it "should raise an exception if told to act in other than :delay or :immediate(ly)" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      lambda { 
        @resource.notifies :reload, @resource.resources(:zen_master => "coffee"), :someday
      }.should raise_error(ArgumentError)
    end
  
    it "should allow multiple notified resources appear in the actions hash" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @resource.resources(:zen_master => "coffee")
      @resource.actions[:reload][:delayed][0].name.should eql("coffee")
      @resource.collection << Chef::Resource::ZenMaster.new("beans")
      @resource.notifies :reload, @resource.resources(:zen_master => "beans")
      @resource.actions[:reload][:delayed][1].name.should eql("beans")
    end
  end
  
  describe "subscribes" do  
    it "should make resources appear in the actions hash of subscribed nodes" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @resource.resources(:zen_master => "coffee")
      @resource.subscribes :reload, zr
      zr.actions[:reload][:delayed][0].name.should eql("funk")
    end
  
    it "should make resources appear in the actions hash of subscribed nodes" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @resource.resources(:zen_master => "coffee")
      @resource.subscribes :reload, zr
      zr.actions[:reload][:delayed][0].name.should eql("funk")
    
      @resource.collection << Chef::Resource::ZenMaster.new("bean")
      zrb = @resource.resources(:zen_master => "bean")
      zrb.subscribes :reload, zr
      zr.actions[:reload][:delayed][1].name.should eql("bean")
    end
  
    it "should make subscribed resources be capable of acting immediately" do
      @resource.collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @resource.resources(:zen_master => "coffee")
      @resource.subscribes :reload, zr, :immediately
      zr.actions[:reload][:immediate][0].name.should eql("funk")
    end
  end
  
  describe "to_s" do 
    it "should become a string like resource_name[name]" do
      zm = Chef::Resource::ZenMaster.new("coffee")
      zm.to_s.should eql("zen_master[coffee]")
    end
  end
  
  describe "is" do
    it "should return the arguments passed with 'is'" do
      zm = Chef::Resource::ZenMaster.new("coffee")
      res = zm.is("one", "two", "three")
      res.should eql([ "one", "two", "three" ])
    end
  
    it "should allow arguments preceeded by is to methods" do
      @resource.noop(@resource.is(true))
      @resource.noop.should eql(true)
    end
  end

  describe "to_json" do
    it "should serialize to json" do
      json = @resource.to_json
      json.should =~ /json_class/
      json.should =~ /instance_vars/
    end
  end
  
  describe "to_hash" do
    it "should convert to a hash" do
      hash = @resource.to_hash
      hash.keys.should include( :only_if, :allowed_actions, :params, :provider, 
                                :updated, :before, :not_if, :supports, :node, 
                                :actions, :noop, :ignore_failure, :name, :source_line, :action)
      hash[:name].should eql("funk")
    end
  end
  
  describe "self.json_create" do
    it "should deserialize itself from json" do
      json = @resource.to_json
      serialized_node = JSON.parse(json)
      serialized_node.should be_a_kind_of(Chef::Resource)
      serialized_node.name.should eql(@resource.name)
    end
  end
  
  describe "supports" do
    it "should allow you to set what features this resource supports" do
      support_hash = { :one => :two }
      @resource.supports(support_hash)
      @resource.supports.should eql(support_hash)
    end
  
    it "should return the current value of supports" do
      @resource.supports.should == {}
    end
  end
  
  describe "ignore_failure" do  
    it "should default to throwing an error if a provider fails for a resource" do
      @resource.ignore_failure.should == false
    end
  
    it "should allow you to set whether a provider should throw exceptions with ignore_failure" do
      @resource.ignore_failure(true)
      @resource.ignore_failure.should == true
    end
  
    it "should allow you to epic_fail" do
      @resource.epic_fail(true)
      @resource.epic_fail.should == true
    end
  end
  
end