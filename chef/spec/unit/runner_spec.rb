
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
    @run_context = Chef::RunContext.new(@node, Chef::CookbookCollection.new({}))
    @run_context.resource_collection << Chef::Resource::Cat.new("loulou1", @run_context)
    Chef::Platform.set(
      :resource => :cat,
      :provider => Chef::Provider::SnakeOil
    )
    @runner = Chef::Runner.new(@run_context)
  end
  
  before(:each) do
    @mock_node = mock("Node", :null_object => true)
    @mock_collection = mock("Resource Collection", :null_object => true)
    @mock_provider = mock("Provider", :null_object => true)
    @mock_resource = mock("Resource", :null_object => true)
    new_runner
  end
  
  it "should pass each resource in the collection to a provider" do
    @run_context.resource_collection.should_receive(:execute_each_resource).once
    @runner.converge
  end
  
  it "should use the provider specified by the resource (if it has one)" do
    provider = Chef::Provider::Easy.new(@run_context.resource_collection[0], @run_context)
    @run_context.resource_collection[0].should_receive(:provider).once.and_return(Chef::Provider::Easy)
    Chef::Provider::Easy.should_receive(:new).once.and_return(provider)
    @runner.converge
  end
  
  it "should use the platform provider if it has one" do
    Chef::Platform.should_receive(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    @runner.converge
  end
  
  it "should run the action for each resource" do
    Chef::Platform.should_receive(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    provider.should_receive(:action_sell).once.and_return(true)
    Chef::Provider::SnakeOil.should_receive(:new).once.and_return(provider)
    @runner.converge
  end

  # TODO: 5/21/2010 cw/tim: the following tests really only test
  # implementation, not behavior. They should probably be turned into
  # feature tests that demonstrate that the different branches are
  # followed based on the only_if condition.
  
  it "should not check a resource's only_if if it is not provided" do
    @run_context.resource_collection[0].should_receive(:only_if).and_return(nil)
    @runner.converge
  end
  
  it "should send a resources only_if to Chef::Mixin::Command.only_if" do
    @run_context.resource_collection[0].should_receive(:only_if).twice.and_return(true)
    Chef::Mixin::Command.should_receive(:only_if).with(true, {}).and_return(false)
    @runner.converge
  end
  
  it "should change to the directory specified in cwd for only_if" do
    @run_context.resource_collection[0].should_receive(:only_if).twice.and_return("/bin/true")
    @run_context.resource_collection[0].should_receive(:only_if_args).and_return({:cwd => "/tmp"})
    Chef::Mixin::Command.should_receive(:only_if).with("/bin/true", {:cwd => "/tmp"}).and_return(true)
    @runner.converge
  end
  
  it "should send a resources not_if to Chef::Mixin::Command.not_if" do
    @run_context.resource_collection[0].should_receive(:not_if).twice.and_return(true)
    Chef::Mixin::Command.should_receive(:not_if).with(true, {}).and_return(false)
    @runner.converge
  end
  
  it "should check a resources not_if, if it is provided" do
    @run_context.resource_collection[0].should_receive(:not_if).and_return(nil)
    @runner.converge
  end
  
  it "should change to the directory specified in cwd for not_if" do
    @run_context.resource_collection[0].should_receive(:not_if).twice.and_return("/bin/true")
    @run_context.resource_collection[0].should_receive(:not_if_args).and_return({:cwd => "/tmp"})
    Chef::Mixin::Command.should_receive(:not_if).with("/bin/true", {:cwd => "/tmp"}).and_return(true)
    @runner.converge
  end
  
  it "should raise exceptions as thrown by a provider" do
    Chef::Platform.stub!(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    Chef::Provider::SnakeOil.stub!(:new).once.and_return(provider)
    provider.stub!(:action_sell).once.and_raise(ArgumentError)
    lambda { @runner.converge }.should raise_error(ArgumentError)
  end
  
  it "should not raise exceptions thrown by providers if the resource has ignore_failure set to true" do
    Chef::Platform.stub!(:find_provider_for_node).once.and_return(Chef::Provider::SnakeOil)
    @run_context.resource_collection[0].stub!(:ignore_failure).and_return(true)
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    Chef::Provider::SnakeOil.stub!(:new).once.and_return(provider)
    provider.stub!(:action_sell).once.and_raise(ArgumentError)
    lambda { @runner.converge }.should_not raise_error(ArgumentError)
  end
  
  it "should execute immediate actions on changed resources" do
    Chef::Platform.should_receive(:find_provider_for_node).exactly(3).times.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    Chef::Provider::SnakeOil.should_receive(:new).exactly(3).times.and_return(provider)   
    @run_context.resource_collection << Chef::Resource::Cat.new("peanut", @run_context)
    @run_context.resource_collection[1].notifies :buy, @run_context.resource_collection[0], :immediately
    @run_context.resource_collection[1].updated = true
    provider.should_receive(:action_buy).once.and_return(true)
    @runner.converge
  end
  
  it "should follow a chain of actions" do
    Chef::Platform.should_receive(:find_provider_for_node).exactly(5).times.and_return(Chef::Provider::SnakeOil)
    @run_context.resource_collection << Chef::Resource::Cat.new("peanut", @run_context)
    @run_context.resource_collection[1].notifies :buy, @run_context.resource_collection[0], :immediately
    @run_context.resource_collection << Chef::Resource::Cat.new("snuffles", @run_context)
    @run_context.resource_collection[2].notifies :purr, @run_context.resource_collection[1], :immediately
    @run_context.resource_collection[2].updated = true
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    p1 = Chef::Provider::SnakeOil.new(@run_context.resource_collection[1], @run_context)
    p2 = Chef::Provider::SnakeOil.new( @run_context.resource_collection[2], @run_context)
    Chef::Provider::SnakeOil.should_receive(:new).exactly(5).times.and_return(provider, p1, p2, p1, provider)   
    provider.should_receive(:action_buy).once.and_return(true)
    @runner.converge
  end
  
  it "should execute delayed actions on changed resources" do
    Chef::Platform.should_receive(:find_provider_for_node).exactly(3).times.and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    Chef::Provider::SnakeOil.should_receive(:new).exactly(3).times.and_return(provider)   
    @run_context.resource_collection << Chef::Resource::Cat.new("peanut", @run_context)
    @run_context.resource_collection[1].notifies :buy, @run_context.resource_collection[0], :delayed
    @run_context.resource_collection[1].updated = true
    provider.should_receive(:action_buy).once.and_return(true)
    @runner.converge
  end
  
  it "should collapse delayed actions on changed resources and execute them in the order they were encountered" do
    Chef::Platform.stub!(:find_provider_for_node).and_return(Chef::Provider::SnakeOil)
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    Chef::Provider::SnakeOil.stub!(:new).and_return(provider)
    cat = Chef::Resource::Cat.new("peanut", @run_context)
    cat.notifies :buy, @run_context.resource_collection[0], :delayed
    cat.updated = true
    @run_context.resource_collection << cat
    @run_context.resource_collection << cat
    cat2 = Chef::Resource::Cat.new("snickers", @run_context)
    cat2.notifies :pur, @run_context.resource_collection[1], :delayed
    cat2.notifies :pur, @run_context.resource_collection[1], :delayed
    cat2.updated = true
    @run_context.resource_collection << cat2
    provider.should_receive(:action_buy).once.ordered
    provider.should_receive(:action_pur).once.ordered
    @runner.converge
  end

  it "should check a resource's only_if and not_if if notified by another resource" do
    provider = Chef::Provider::SnakeOil.new(@run_context.resource_collection[0], @run_context)
    @run_context.resource_collection[0].action = :nothing
    @run_context.resource_collection << Chef::Resource::Cat.new("carmel", @run_context)
    @run_context.resource_collection[1].notifies :buy, @run_context.resource_collection[0], :delayed
    @run_context.resource_collection[1].updated = true
    # hits only_if first time when the resource is run in order, second on notify
    @run_context.resource_collection[0].should_receive(:only_if).exactly(2).times.and_return(nil)
    @run_context.resource_collection[0].should_receive(:not_if).exactly(2).times.and_return(nil)
    @runner.converge
  end

end
