#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

class ResourceTestHarness < Chef::Resource
  provider_base Chef::Provider::Package
end

describe Chef::Resource do
  before(:each) do
    @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new)
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection)
    @resource = Chef::Resource.new("funk", @run_context)
  end
  
  describe "load_prior_resource" do
    before(:each) do
      @prior_resource = Chef::Resource.new("funk")
      @prior_resource.supports(:funky => true)
      @prior_resource.source_line
      @prior_resource.allowed_actions << :funkytown
      @prior_resource.action(:funkytown)
      @resource.allowed_actions << :funkytown
      @run_context.resource_collection << @prior_resource
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
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.notifies_delayed.detect{|e| e.resource.name == "coffee" && e.action == :reload}.should_not be_nil
    end
  
    it "should make notified resources be capable of acting immediately" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee"), :immediate
      @resource.notifies_immediate.detect{|e| e.resource.name == "coffee" && e.action == :reload}.should_not be_nil
    end
  
    it "should raise an exception if told to act in other than :delay or :immediate(ly)" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      lambda { 
        @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee"), :someday
      }.should raise_error(ArgumentError)
    end
  
    it "should allow multiple notified resources appear in the actions hash" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.notifies_delayed.detect{|e| e.resource.name == "coffee" && e.action == :reload}.should_not be_nil
      
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("beans")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "beans")
      @resource.notifies_delayed.detect{|e| e.resource.name == "beans" && e.action == :reload}.should_not be_nil
    end
  end
  
  describe "subscribes" do  
    it "should make resources appear in the actions hash of subscribed nodes" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.subscribes :reload, zr
      zr.notifies_delayed.detect{|e| e.resource.name == "funk" && e.action == :reload}.should_not be_nil
    end
  
    it "should make resources appear in the actions hash of subscribed nodes" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.subscribes :reload, zr
      zr.notifies_delayed.detect{|e| e.resource.name == @resource.name && e.action == :reload}.should_not be_nil
    
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("bean")
      zrb = @run_context.resource_collection.find(:zen_master => "bean")
      zrb.subscribes :reload, zr
      zr.notifies_delayed.detect{|e| e.resource.name == @resource.name && e.action == :reload}.should_not be_nil
    end
  
    it "should make subscribed resources be capable of acting immediately" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.subscribes :reload, zr, :immediately
      zr.notifies_immediate.detect{|e| e.resource.name == @resource.name && e.action == :reload}.should_not be_nil
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
      expected_keys = [ :only_if, :allowed_actions, :params, :provider, 
                        :updated, :before, :not_if, :supports, 
                        :notifies_delayed, :notifies_immediate, :noop,
                        :ignore_failure, :name, :source_line, :action,
                        :not_if_args, :only_if_args
                      ]
      (hash.keys - expected_keys).should == []
      (expected_keys - hash.keys).should == []
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
  
  describe "setting the base provider class for the resource" do
    
    it "defaults to Chef::Provider for the base class" do
      Chef::Resource.provider_base.should == Chef::Provider
    end
    
    it "allows the base provider to be overriden by a " do
      ResourceTestHarness.provider_base.should == Chef::Provider::Package
    end
    
  end

  it "supports accessing the node via the @node instance variable [DEPRECATED]" do
    @resource.instance_variable_get(:@node).should == @node
  end

  it "runs an action by finding its provider, loading the current resource and then running the action" do
    pending
  end

end
