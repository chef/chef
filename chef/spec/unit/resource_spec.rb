#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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
  
  it "should create a new Chef::Resource" do
    @resource.should be_a_kind_of(Chef::Resource)
  end

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
  
  it "should accept true or false for noop" do
    lambda { @resource.noop true }.should_not raise_error(ArgumentError)
    lambda { @resource.noop false }.should_not raise_error(ArgumentError)
    lambda { @resource.noop "eat it" }.should raise_error(ArgumentError)
  end
  
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
  
  it "should return a value if not defined" do
    zm = Chef::Resource::ZenMaster.new("coffee")
    zm.something(true).should eql(true)
    zm.something.should eql(true)
    zm.something(false).should eql(false)
    zm.something.should eql(false)
  end
  
  it "should become a string like resource_name[name]" do
    zm = Chef::Resource::ZenMaster.new("coffee")
    zm.to_s.should eql("zen_master[coffee]")
  end
  
  it "should return the arguments passed with 'is'" do
    zm = Chef::Resource::ZenMaster.new("coffee")
    res = zm.is("one", "two", "three")
    res.should eql([ "one", "two", "three" ])
  end
  
  it "should allow arguments preceeded by is to methods" do
    @resource.noop(@resource.is(true))
    @resource.noop.should eql(true)
  end

  it "should serialize to json" do
    json = @resource.to_json
    json.should =~ /json_class/
    json.should =~ /instance_vars/
  end
  
  it "should deserialize itself from json" do
    json = @resource.to_json
    serialized_node = JSON.parse(json)
    serialized_node.should be_a_kind_of(Chef::Resource)
    serialized_node.name.should eql(@resource.name)
  end
  
end