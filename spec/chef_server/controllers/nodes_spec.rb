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

require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe Nodes, "index action" do  
  it "should get a list of all the nodes" do
    Chef::Node.should_receive(:list).and_return(["one"])
    dispatch_to(Nodes, :index) do |c|
      c.stub!(:display)
    end
  end
  
  it "should send a list of nodes to display" do
    Chef::Node.stub!(:list).and_return(["one"])
    dispatch_to(Nodes, :index) do |c|
      c.should_receive(:display).with(["one"])
    end
  end
end

describe Nodes, "show action" do  
  it "should load a node from the filestore based on the id" do
    node = stub("Node", :null_object => true)
    Chef::Node.should_receive(:load).with("bond").once.and_return(node)
    dispatch_to(Nodes, :show, { :id => "bond" }) do |c|
      c.should_receive(:display).with(node).once.and_return(true)
    end
  end
  
  it "should return 200 on a well formed request" do
    node = stub("Node", :null_object => true)
     Chef::Node.should_receive(:load).with("bond").once.and_return(node)
     controller = dispatch_to(Nodes, :show, { :id => "bond" }) do |c|
       c.stub!(:display)
     end
     controller.status.should eql(200)
  end
  
  it "should raise a BadRequest if the id is not found" do
    Chef::Node.should_receive(:load).with("bond").once.and_raise(RuntimeError)
    lambda { 
      dispatch_to(Nodes, :show, { :id => "bond" }) 
    }.should raise_error(Merb::ControllerExceptions::BadRequest)
  end
end

describe Nodes, "create action" do
  it "should create a node from an inflated object" do
    mnode = mock("Node", :null_object => true)
    mnode.stub!(:name).and_return("bond")
    mnode.should_receive(:save).once.and_return(true)
    controller = dispatch_to(Nodes, :create) do |c|
      c.stub!(:params).and_return({ "inflated_object" => mnode })
      c.stub!(:session).and_return({
        :openid => 'http://localhost/openid/server/node/bond',
        :level => :node,
        :node_name => "bond",
      })
      c.stub!(:display)
    end
    controller.status.should eql(202)
  end
  
  it "should raise an exception if it cannot inflate an object" do
    lambda { 
      dispatch_to(Nodes, :create) do |c|
        c.stub!(:params).and_return({ })
      end
    }.should raise_error(Merb::Controller::BadRequest)
  end
end

describe Nodes, "update action" do
  it "should update a node from an inflated object" do
    mnode = mock("Node", :null_object => true)
    mnode.stub!(:name).and_return("one")
    Chef::FileStore.should_receive(:store).with("node", "one", mnode).once.and_return(true)
    controller = dispatch_to(Nodes, :update, { :id => "one" }) do |c|
      c.stub!(:session).and_return({
        :openid => 'http://localhost/openid/server/node/one',
        :level => :node,
        :node_name => "one",
      })
      c.stub!(:params).and_return({ "inflated_object" => mnode })
      c.stub!(:display)
    end
    controller.status.should eql(202)
  end
  
  it "should raise an exception if it cannot inflate an object" do
    lambda { dispatch_to(Nodes, :update) }.should raise_error(Merb::Controller::BadRequest)
  end
end

describe Nodes, "destroy action" do
  def do_destroy
    dispatch_to(Nodes, :destroy, { :id => "one" }) do |c|
      c.stub!(:display)
    end
  end
  
  it "should load the node it's about to destroy from the filestore" do
    mnode = stub("Node", :null_object => true)
    Chef::FileStore.should_receive(:load).with("node", "one").once.and_return(mnode)
    Chef::FileStore.stub!(:delete)
    do_destroy
  end
  
  it "should raise an exception if it cannot find the node to destroy" do
    Chef::FileStore.should_receive(:load).with("node", "one").once.and_raise(RuntimeError)
    lambda { do_destroy }.should raise_error(Merb::Controller::BadRequest)
  end
  
  it "should remove the node from the filestore" do
    mnode = stub("Node", :null_object => true)
    Chef::FileStore.stub!(:load).with("node", "one").and_return(mnode)
    Chef::FileStore.should_receive(:delete).with("node", "one")
    do_destroy
  end
  
  it "should remove the node from the search index" do
    mnode = stub("Node", :null_object => true)
    Chef::FileStore.stub!(:load).with("node", "one").and_return(mnode)
    Chef::FileStore.stub!(:delete)
    do_destroy
  end
  
  it "should return the node it just deleted" do
    mnode = stub("Node", :null_object => true)
    Chef::FileStore.stub!(:load).with("node", "one").and_return(mnode)
    Chef::FileStore.stub!(:delete)
    dispatch_to(Nodes, :destroy, { :id => "one" }) do |c|
       c.should_receive(:display).once.with(mnode)
    end
  end
  
  it "should return a status of 202" do
    mnode = stub("Node", :null_object => true)
    Chef::FileStore.stub!(:load).with("node", "one").and_return(mnode)
    Chef::FileStore.stub!(:delete)
    controller = do_destroy
    controller.status.should eql(202)
  end
end

describe Nodes, "compile action" do
  before(:each) do
    @compile = stub("Compile", :null_object => true)
    @node = stub("Node", :null_object => true)
    @node.stub!(:[]).and_return(true)
    @node.stub!(:[]=).and_return(true)
    @node.stub!(:recipes).and_return([])
    @compile.stub!(:load_definitions).and_return(true)
    @compile.stub!(:load_recipes).and_return(true)
    @compile.stub!(:collection).and_return([])
    @compile.stub!(:node, @node)
    @compile.stub!(:load_node).and_return(true)
    @stored_node = stub("Stored Node", :null_object => true)
  end
  
  def do_compile
    Chef::FileStore.stub!(:store).and_return(true)
    Chef::FileStore.stub!(:load).and_return(@stored_node)
    Chef::Compile.stub!(:new).and_return(@compile)
    dispatch_to(Nodes, :compile, { :id => "one" }) do |c|
      c.stub!(:display)
    end
  end
  
  it "should load the node from the node resource" do
    @compile.should_receive(:load_node).with("one").and_return(true)
    do_compile
  end
  
  it "should merge the data with the currently stored node" do
    node1 = Chef::Node.new
    node1.name "adam"
    node1.music "crowe"
    node1.recipes << "monkey"
    @compile.stub!(:node).and_return(node1)
    @stored_node = Chef::Node.new
    @stored_node.name "adam"
    @stored_node.music "crown"
    @stored_node.woot "woot"
    @stored_node.recipes << "monkeysoup"
    do_compile
    node1.name.should eql("adam")
    node1.music.should eql("crown")
    node1.woot.should eql("woot")
    node1.recipes.should eql([ "monkey", "monkeysoup" ])
  end
  
  it "should load definitions" do
    @compile.should_receive(:load_definitions)
    do_compile
  end
  
  it "should load recipes" do
    @compile.should_receive(:load_recipes)
    do_compile
  end
  
  it "should display the collection and node object" do
    Chef::FileStore.stub!(:load).and_return(@stored_node)
    Chef::Compile.stub!(:new).and_return(@compile)
    dispatch_to(Nodes, :compile, { :id => "one" }) do |c|
      c.should_receive(:display).with({ :collection => [], :node => nil })
    end
  end
  
  it "should return 200" do
    controller = do_compile
    controller.status.should eql(200)
  end
  
end