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

describe Chef::Compile do
  before(:each) do
    Chef::Config.node_path(File.join(File.dirname(__FILE__), "..", "data", "compile", "nodes"))
    Chef::Config.cookbook_path(File.join(File.dirname(__FILE__), "..", "data", "compile", "cookbooks"))
    @compile = Chef::Compile.new
  end
  
  it "should create a new Chef::Compile" do
    @compile.should be_a_kind_of(Chef::Compile)
  end
  
  it "should have a Chef::CookbookLoader" do
    @compile.cookbook_loader.should be_a_kind_of(Chef::CookbookLoader)
  end
  
  it "should have a Chef::ResourceCollection" do
    @compile.collection.should be_a_kind_of(Chef::ResourceCollection)
  end
  
  it "should have a hash of Definitions" do
    @compile.definitions.should be_a_kind_of(Hash)
  end

  it "should load a node by name" do
    node = Chef::Node.new
    Chef::Node.stub!(:load).and_return(node)
    lambda { 
      @compile.load_node("compile")
    }.should_not raise_error
    @compile.node.name.should == "compile"
  end
  
  it "should load all the definitions" do
    lambda { @compile.load_definitions }.should_not raise_error
    @compile.definitions.should have_key(:new_cat)
  end
  
  it "should load all the recipes specified for this node" do
    node = Chef::Node.new
    Chef::Node.stub!(:load).and_return(node)
    @compile.load_node("compile")
    @compile.load_definitions
    lambda { @compile.load_recipes }.should_not raise_error
    @compile.collection[0].to_s.should == "cat[einstein]"  
    @compile.collection[1].to_s.should == "cat[loulou]"
    @compile.collection[2].to_s.should == "cat[birthday]"
    @compile.collection[3].to_s.should == "cat[peanut]"
    @compile.collection[4].to_s.should == "cat[fat peanut]"
  end

end
