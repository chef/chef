#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

describe Chef::RunContext do
  before(:each) do
    Chef::Config.node_path(File.expand_path(File.join(CHEF_SPEC_DATA, "compile", "nodes")))
    Chef::Config.cookbook_path(File.expand_path(File.join(CHEF_SPEC_DATA, "compile", "cookbooks")))
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node)
    @run_context.go
  end
  
  it "should load a node by name" do
    node = Chef::Node.new
    Chef::Node.stub!(:load).and_return(node)
    lambda { 
      @run_context.load_node("compile")
    }.should_not raise_error
    @run_context.node.name.should == "compile"
  end
  
  it "should load all the definitions" do
    lambda { @run_context.load_definitions }.should_not raise_error
    @run_context.definitions.should have_key(:new_cat)
    @run_context.definitions.should have_key(:new_badger)
    @run_context.definitions.should have_key(:new_dog)
  end
  
  it "should load all the recipes specified for this node" do
    node = Chef::Node.new
    Chef::Node.stub!(:load).and_return(node)
    @run_context.load_node("compile")
    @run_context.load_definitions
    lambda { @run_context.load_recipes }.should_not raise_error
    @run_context.resource_collection[0].to_s.should == "cat[einstein]"  
    @run_context.resource_collection[1].to_s.should == "cat[loulou]"
    @run_context.resource_collection[2].to_s.should == "cat[birthday]"
    @run_context.resource_collection[3].to_s.should == "cat[peanut]"
    @run_context.resource_collection[4].to_s.should == "cat[fat peanut]"
  end

  it "should not clobber default and overrides at expansion" do
    @node.set[:monkey] = [ {}, {} ]
    @node[:monkey].each { |m| m[:name] = "food" }
    @run_context.expand_node
    @node[:monkey].should == [ { "name" => "food" }, { "name" => "food" } ]
  end

end
