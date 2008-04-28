#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Runner do
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
    @collection.should_receive(:each).once
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
  
  def new_runner
    @node = Chef::Node.new
    @node.name "latte"
    @node.operatingsystem "mac_os_x"
    @node.operatingsystemversion "10.5.1"
    @collection = Chef::ResourceCollection.new()
    @collection << Chef::Resource::Cat.new("loulou", @collection)
    Chef::Platform.set(
      :resource => :cat,
      :provider => Chef::Provider::SnakeOil
    )
    @runner = Chef::Runner.new(@node, @collection)
  end
end