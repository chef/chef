#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

describe Chef::ResourceCollection do
  
  before(:each) do
    @rc = Chef::ResourceCollection.new()
    @resource = Chef::Resource::ZenMaster.new("makoto")
  end
  
  describe "initialize" do
    it "should return a Chef::ResourceCollection" do
      @rc.should be_kind_of(Chef::ResourceCollection)
    end
  end
  
  describe "[]" do
    it "should accept Chef::Resources through [index]" do
      lambda { @rc[0] = @resource }.should_not raise_error
      lambda { @rc[0] = "string" }.should raise_error
    end
    
    it "should allow you to fetch Chef::Resources by position" do
      @rc[0] = @resource
      @rc[0].should eql(@resource)
    end
  end
  
  describe "push" do
    it "should accept Chef::Resources through pushing" do
      lambda { @rc.push(@resource) }.should_not raise_error
      lambda { @rc.push("string") }.should raise_error
    end
  end
  
  describe "<<" do
    it "should accept the << operator" do
      lambda { @rc << @resource }.should_not raise_error
    end
  end
  
  describe "insert" do 
    it "should accept only Chef::Resources" do
      lambda { @rc.insert(@resource) }.should_not raise_error
      lambda { @rc.insert("string") }.should raise_error
    end
    
    it "should append resources to the end of the collection when not executing a run" do
      zmr = Chef::Resource::ZenMaster.new("there is no spoon")
      @rc.insert(@resource)
      @rc.insert(zmr)
      @rc[0].should eql(@resource)
      @rc[1].should eql(zmr)
    end
    
    it "should insert resources to the middle of the collection if called while executing a run" do
      resource_to_inject = Chef::Resource::ZenMaster.new("there is no spoon")
      zmr = Chef::Resource::ZenMaster.new("morpheus")
      dummy = Chef::Resource::ZenMaster.new("keanu reeves")
      @rc.insert(zmr)
      @rc.insert(dummy)
      
      @rc.execute_each_resource do |resource|
        @rc.insert(resource_to_inject) if resource == zmr
      end
      
      @rc[0].should eql(zmr)
      @rc[1].should eql(resource_to_inject)
      @rc[2].should eql(dummy)
    end
  end

  describe "each" do
    it "should allow you to iterate over every resource in the collection" do
      load_up_resources
      results = Array.new
      lambda { 
        @rc.each do |r|
          results << r.name
        end
      }.should_not raise_error
      results.each_index do |i|
        case i
        when 0
          results[i].should eql("dog")
        when 1
          results[i].should eql("cat")
        when 2
          results[i].should eql("monkey")
        end
      end
    end
  end
  
  describe "each_index" do
    it "should allow you to iterate over every resource by index" do
      load_up_resources
      results = Array.new
      lambda { 
        @rc.each_index do |i|
          results << @rc[i].name
        end 
      }.should_not raise_error()
      results.each_index do |i|
        case i
        when 0
          results[i].should eql("dog")
        when 1
          results[i].should eql("cat")
        when 2
          results[i].should eql("monkey")
        end
      end
    end
  end
  
  describe "lookup" do
    it "should allow you to find resources by name via lookup" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      @rc << zmr
      @rc.lookup(zmr.to_s).should eql(zmr)

      zmr = Chef::Resource::ZenMaster.new("cat")
      @rc[0] = zmr
      @rc.lookup(zmr).should eql(zmr)
    
      zmr = Chef::Resource::ZenMaster.new("monkey")
      @rc.push(zmr)
      @rc.lookup(zmr).should eql(zmr)
    end
  
    it "should raise an exception if you send something strange to lookup" do
      lambda { @rc.lookup(:symbol) }.should raise_error(ArgumentError)
    end
  
    it "should raise an exception if it cannot find a resource with lookup" do
      lambda { @rc.lookup("zen_master[dog]") }.should raise_error(Chef::Exceptions::ResourceNotFound)
    end
  end
  
  describe "resources" do

    it "should find a resource by symbol and name (:zen_master => monkey)" do
      load_up_resources
      @rc.resources(:zen_master => "monkey").name.should eql("monkey")
    end

    it "should find a resource by symbol and array of names (:zen_master => [a,b])" do
      load_up_resources
      results = @rc.resources(:zen_master => [ "monkey", "dog" ])
      results.length.should eql(2)
      check_by_names(results, "monkey", "dog")
    end

    it "should find resources of multiple kinds (:zen_master => a, :file => b)" do
      load_up_resources
      results = @rc.resources(:zen_master => "monkey", :file => "something")
      results.length.should eql(2)
      check_by_names(results, "monkey", "something")
    end

    it "should find a resource by string zen_master[a]" do
      load_up_resources
      @rc.resources("zen_master[monkey]").name.should eql("monkey")
    end

    it "should find resources by strings of zen_master[a,b]" do
      load_up_resources
      results = @rc.resources("zen_master[monkey,dog]")
      results.length.should eql(2)
      check_by_names(results, "monkey", "dog")
    end

    it "should find resources of multiple types by strings of zen_master[a]" do
      load_up_resources
      results = @rc.resources("zen_master[monkey]", "file[something]")
      results.length.should eql(2)
      check_by_names(results, "monkey", "something")
    end
  
    it "should raise an exception if you pass a bad name to resources" do
      lambda { @rc.resources("michael jackson") }.should raise_error(ArgumentError)    
    end
  
    it "should raise an exception if you pass something other than a string or hash to resource" do
      lambda { @rc.resources([Array.new]) }.should raise_error(ArgumentError)
    end

    it "raises an error when attempting to find a resource that does not exist" do
      lambda {@rc.find("script[nonesuch]")}.should raise_error(Chef::Exceptions::ResourceNotFound)
    end

  end
  
  describe "to_json" do
    it "should serialize to json" do
      json = @rc.to_json
      json.should =~ /json_class/
      json.should =~ /instance_vars/
    end
  end
  
  describe "self.from_json" do
    it "should deserialize itself from json" do
      @rc << @resource
      json = @rc.to_json
      s_rc = Chef::JSONCompat.from_json(json)
      s_rc.should be_a_kind_of(Chef::ResourceCollection)
      s_rc[0].name.should eql(@resource.name)
    end
  end
  
  describe "provides access to the raw resources array" do
    it "returns the resources via the all_resources method" do
      @rc.all_resources.should equal(@rc.instance_variable_get(:@resources))
    end
  end
  
  describe "provides access to stepable iterator" do
    it "returns the iterator object" do
      @rc.instance_variable_set(:@iterator, :fooboar)
      @rc.iterator.should == :fooboar
    end
  end

  def check_by_names(results, *names)
    names.each do |res_name|
      results.detect{ |res| res.name == res_name }.should_not eql(nil)
    end
  end
  
  def load_up_resources
    %w{dog cat monkey}.each do |n|
       @rc << Chef::Resource::ZenMaster.new(n)
    end
    @rc << Chef::Resource::File.new("something")
  end
    
end
