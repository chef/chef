
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

describe Chef::Runner do
  def new_runner
    @node = Chef::Node.new
    @node.name "latte"
    @node.platform "mac_os_x"
    @node.platform_version "10.5.1"
    @collection = Chef::ResourceCollection.new()
    @collection << Chef::Resource::Cat.new("loulou1", @collection)
    Chef::Platform.set(
      :resource => :cat,
      :provider => Chef::Provider::SnakeOil
    )
    @runner = Chef::Runner.new(@node, @collection)
  end
  
  before(:each) do
    @mock_node = mock("Node", :null_object => true)
    @mock_collection = mock("Resource Collection", :null_object => true)
    @mock_provider = mock("Provider", :null_object => true)
    @mock_resource = mock("Resource", :null_object => true)
    new_runner
  end
  
  it "should require a Node and a ResourceCollection" do
    @mock_node.should_receive(:kind_of?).once.and_return(true)
    @mock_collection.should_receive(:kind_of?).once.and_return(true)
    runner = Chef::Runner.new(@mock_node, @mock_collection)
    runner.should be_a_kind_of(Chef::Runner)
  end
  
  it "should raise an exception if you pass the wrong kind of object to new" do
    @mock_node.stub!(:kind_of?).and_return(false)
    @mock_collecton.stub!(:kind_of?).and_return(false)
    lambda { Chef::Runner.new(@mock_node, @mock_collection) }.should raise_error(ArgumentError)    
  end
  
  it "should pass each resource in the collection to a provider" do
    @collection.should_receive(:execute_each_resource).once
    @runner.converge
  end
  
  it "should use the provider specified by the resource (if it has one)" do
    provider = Chef::Provider::Easy.new(@node, @collection[0])
    @collection[0].should_receive(:provider).once.and_return(Chef::Provider::Easy)
    Chef::Provider::Easy.should_receive(:new).once.and_return(provider)
    @runner.converge
  end
  
  it "should use the platform provider if it has one" do
    Chef::Platform.should_receive(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    @runner.converge
  end
  
  it "should run the action for each resource" do
    Chef::Platform.should_receive(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    provider.should_receive(:action_sell).once.and_return(true)
    Chef::Provider::SnakeOil.should_receive(:new).once.and_return(provider)
    @runner.converge
  end
  
  it "should not check a resources only_if if it is not provided" do
    @collection[0].should_receive(:only_if).and_return(nil)
    @runner.converge
  end
  
  it "should send a resources only_if to Chef::Mixin::Command.only_if" do
    @collection[0].should_receive(:only_if).twice.and_return(true)
    Chef::Mixin::Command.should_receive(:only_if).with(true).and_return(false)
    @runner.converge
  end
  
  it "should send a resources not_if to Chef::Mixin::Command.not_if" do
    @collection[0].should_receive(:not_if).twice.and_return(true)
    Chef::Mixin::Command.should_receive(:not_if).with(true).and_return(false)
    @runner.converge
  end
  
  it "should check a resources not_if, if it is provided" do
    @collection[0].should_receive(:not_if).and_return(nil)
    @runner.converge
  end
  
  it "should raise exceptions as thrown by a provider" do
    Chef::Platform.stub!(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    Chef::Provider::SnakeOil.stub!(:new).once.and_return(provider)
    provider.stub!(:action_sell).once.and_raise(ArgumentError)
    lambda { @runner.converge }.should raise_error(ArgumentError)
  end
  
  it "should not raise exceptions thrown by providers if the resource has ignore_failure set to true" do
    Chef::Platform.stub!(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    @collection[0].stub!(:ignore_failure).and_return(true)
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    Chef::Provider::SnakeOil.stub!(:new).once.and_return(provider)
    provider.stub!(:action_sell).once.and_raise(ArgumentError)
    lambda { @runner.converge }.should_not raise_error(ArgumentError)
  end
  
  it "should execute immediate actions on changed resources" do
    Chef::Platform.should_receive(:find_provider_for_node).exactly(3).times.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    Chef::Provider::SnakeOil.should_receive(:new).exactly(3).times.and_return(provider)   
    @collection << Chef::Resource::Cat.new("peanut", @collection)
    @collection[1].notifies :buy, @collection[0], :immediately
    @collection[1].updated = true
    provider.should_receive(:action_buy).once.and_return(true)
    @runner.converge
  end
  
  it "should follow a chain of actions" do
    Chef::Platform.should_receive(:find_provider_for_node).exactly(5).times.and_return(Chef::Provider::SnakeOil)
    @collection << Chef::Resource::Cat.new("peanut", @collection)
    @collection[1].notifies :buy, @collection[0], :immediately
    @collection << Chef::Resource::Cat.new("snuffles", @collection)
    @collection[2].notifies :purr, @collection[1], :immediately
    @collection[2].updated = true
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    p1 = Chef::Provider::SnakeOil.new(@node, @collection[1])
    p2 = Chef::Provider::SnakeOil.new(@node, @collection[2])
    Chef::Provider::SnakeOil.should_receive(:new).exactly(5).times.and_return(provider, p1, p2, p1, provider)   
    provider.should_receive(:action_buy).once.and_return(true)
    @runner.converge
  end
  
  it "should execute delayed actions on changed resources" do
    Chef::Platform.should_receive(:find_provider_for_node).exactly(3).times.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    Chef::Provider::SnakeOil.should_receive(:new).exactly(3).times.and_return(provider)   
    @collection << Chef::Resource::Cat.new("peanut", @collection)
    @collection[1].notifies :buy, @collection[0], :delayed
    @collection[1].updated = true
    provider.should_receive(:action_buy).once.and_return(true)
    @runner.converge
  end
  
  it "should collapse delayed actions on changed resources and execute them in the order they were encountered" do
    Chef::Platform.stub!(:find_provider_for_node).and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@node, @collection[0])
    Chef::Provider::SnakeOil.stub!(:new).and_return(provider)
    cat = Chef::Resource::Cat.new("peanut", @collection)
    cat.notifies :buy, @collection[0], :delayed
    cat.updated = true
    @collection << cat
    @collection << cat
    cat2 = Chef::Resource::Cat.new("snickers", @collection)
    cat2.notifies :pur, @collection[1], :delayed
    cat2.notifies :pur, @collection[1], :delayed
    cat2.updated = true
    @collection << cat2
    provider.should_receive(:action_buy).once.ordered
    provider.should_receive(:action_pur).once.ordered
    @runner.converge
  end
  

end
