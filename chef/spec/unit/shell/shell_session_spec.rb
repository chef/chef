# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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
require "ostruct"


class TestableShellSession < Shell::ShellSession

  def rebuild_node
    nil
  end

  def rebuild_collection
    nil
  end

  def loading
    nil
  end

  def loading_complete
    nil
  end

end

describe Shell::ShellSession do

  it "is a singleton object" do
    Shell::ShellSession.should include(Singleton)
  end

end

describe Shell::StandAloneSession do
  before do
    @session = Shell::StandAloneSession.instance
    @node = @session.node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = @session.run_context = Chef::RunContext.new(@node, {}, @events)
    @recipe = @session.recipe = Chef::Recipe.new(nil, nil, @run_context)
    Shell::Extensions.extend_context_recipe(@recipe)
  end

  it "has a run_context" do
    @session.run_context.should equal(@run_context)
  end

  it "returns a collection based on it's standalone recipe file" do
    @session.resource_collection.should == @recipe.run_context.resource_collection
  end

  it "gives nil for the definitions (for now)" do
    @session.definitions.should be_nil
  end

  it "gives nil for the cookbook_loader" do
    @session.cookbook_loader.should be_nil
  end

  it "runs chef with the standalone recipe" do
    @session.stub!(:node_built?).and_return(true)
    Chef::Log.stub!(:level)
    chef_runner = mock("Chef::Runner.new", :converge => :converged)
    # pre-heat resource collection cache
    @session.resource_collection

    Chef::Runner.should_receive(:new).with(@session.recipe.run_context).and_return(chef_runner)
    @recipe.run_chef.should == :converged
  end

end

describe Shell::SoloSession do
  before do
    Chef::Config[:shell_solo] = true
    @session = Shell::SoloSession.instance
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = @session.run_context = Chef::RunContext.new(@node, {}, @events)
    @session.node = @node
    @recipe = @session.recipe = Chef::Recipe.new(nil, nil, @run_context)
    Shell::Extensions.extend_context_recipe(@recipe)
  end

  after do
    Chef::Config[:shell_solo] = nil
  end

  it "returns a collection based on it's compilation object and the extra recipe provided by chef-shell" do
    @session.stub!(:node_built?).and_return(true)
    kitteh = Chef::Resource::Cat.new("keyboard")
    @recipe.run_context.resource_collection << kitteh
    @session.resource_collection.should include(kitteh)
  end

  it "returns definitions from it's compilation object" do
    @session.definitions.should == @run_context.definitions
  end

  it "keeps json attribs and passes them to the node for consumption" do
    @session.node_attributes = {"besnard_lakes" => "are_the_dark_horse"}
    @session.node.besnard_lakes.should == "are_the_dark_horse"
    #pending "1) keep attribs in an ivar 2) pass them to the node 3) feed them to the node on reset"
  end

  it "generates it's resource collection from the compiled cookbooks and the ad hoc recipe" do
    @session.stub!(:node_built?).and_return(true)
    kitteh_cat = Chef::Resource::Cat.new("kitteh")
    @run_context.resource_collection << kitteh_cat
    keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @recipe.run_context.resource_collection << keyboard_cat
    #@session.rebuild_collection
    @session.resource_collection.should include(kitteh_cat, keyboard_cat)
  end

  it "runs chef with a resource collection from the compiled cookbooks" do
    @session.stub!(:node_built?).and_return(true)
    Chef::Log.stub!(:level)
    chef_runner = mock("Chef::Runner.new", :converge => :converged)
    Chef::Runner.should_receive(:new).with(an_instance_of(Chef::RunContext)).and_return(chef_runner)

    @recipe.run_chef.should == :converged
  end

end
