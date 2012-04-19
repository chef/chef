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

describe Chef::ResourceDefinition do
  before(:each) do
    @def = Chef::ResourceDefinition.new()
  end
  
  describe "initialize" do
    it "should be a Chef::ResourceDefinition" do
      @def.should be_a_kind_of(Chef::ResourceDefinition)
    end
    
    it "should not initialize a new node if one is not provided" do
      @def.node.should eql(nil)
    end
    
    it "should accept a node as an argument" do
      node = Chef::Node.new
      node.name("bobo")
      @def = Chef::ResourceDefinition.new(node)
      @def.node.name.should == "bobo"
    end
  end
  
  describe "node" do
    it "should set the node with node=" do
      node = Chef::Node.new
      node.name("bobo")
      @def.node = node
      @def.node.name.should == "bobo"
    end
    
    it "should return the node" do
      @def.node = Chef::Node.new
      @def.node.should be_a_kind_of(Chef::Node)
    end
  end
  
  it "should accept a new definition with a symbol for a name" do
    lambda { 
      @def.define :smoke do 
      end
    }.should_not raise_error(ArgumentError)
    lambda { 
      @def.define "george washington" do
      end 
    }.should raise_error(ArgumentError)
    @def.name.should eql(:smoke)
  end
  
  it "should accept a new definition with a hash" do
    lambda { 
      @def.define :smoke, :cigar => "cuban", :cigarette => "marlboro" do
      end
    }.should_not raise_error(ArgumentError)
  end
  
  it "should expose the prototype hash params in the params hash" do
    @def.define :smoke, :cigar => "cuban", :cigarette => "marlboro" do; end
    @def.params[:cigar].should eql("cuban")
    @def.params[:cigarette].should eql("marlboro")
  end

  it "should store the block passed to define as a proc under recipe" do
    @def.define :smoke do
      "I am what I am"
    end
    @def.recipe.should be_a_kind_of(Proc)
    @def.recipe.call.should eql("I am what I am")
  end
  
  it "should set paramaters based on method_missing" do
    @def.mind "to fly"
    @def.params[:mind].should eql("to fly")
  end
  
  it "should raise an exception if prototype_params is not a hash" do
    lambda {
      @def.define :monkey, Array.new do
      end
    }.should raise_error(ArgumentError)
  end
  
  it "should raise an exception if define is called without a block" do
    lambda { 
      @def.define :monkey
    }.should raise_error(ArgumentError)
  end
  
  it "should load a description from a file" do
    @def.from_file(File.join(CHEF_SPEC_DATA, "definitions", "test.rb"))
    @def.name.should eql(:rico_suave)
    @def.params[:rich].should eql("smooth")
  end  
  
  it "should turn itself into a string based on the name with to_s" do
    @def.name = :woot
    @def.to_s.should eql("woot")
  end
  
end
