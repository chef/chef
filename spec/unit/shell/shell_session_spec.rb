# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

require "spec_helper"
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
    expect(Shell::ShellSession).to include(Singleton)
  end

end

describe Shell::ClientSession do
  before do
    Chef::Config[:shell_config] = { :override_runlist => [Chef::RunList::RunListItem.new("shell::override")] }
    @chef_rest = double("Chef::ServerAPI")
    @session = Shell::ClientSession.instance
    @node = Chef::Node.build("foo")
    @session.node = @node
    @client = double("Chef::Client.new",
                     :run_ohai => true,
                     :load_node => true,
                     :build_node => true,
                     :register => true,
                     :sync_cookbooks => {})
  end

  it "builds the node's run_context with the proper environment" do
    @session.instance_variable_set(:@client, @client)
    @expansion = Chef::RunList::RunListExpansion.new(@node.chef_environment, [])

    expect(@node.run_list).to receive(:expand).with(@node.chef_environment).and_return(@expansion)
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url]).and_return(@chef_rest)
    @session.rebuild_context
  end

  it "passes the shell CLI args to the client" do
    expect(Chef::Client).to receive(:new).with(nil, Chef::Config[:shell_config]).and_return(@client)
    @session.send(:rebuild_node)
  end

end

describe Shell::SoloSession do
  before do
    Chef::Config[:shell_config] = { :override_runlist => [Chef::RunList::RunListItem.new("shell::override")] }
    @chef_rest = double("Chef::ServerAPI")
    @session = Shell::SoloSession.instance
    @node = Chef::Node.build("foo")
    @session.node = @node
    @client = double("Chef::Client.new",
                     :run_ohai => true,
                     :load_node => true,
                     :build_node => true,
                     :register => true,
                     :sync_cookbooks => {})
  end

  it "builds the node's run_context with the proper environment" do
    @session.instance_variable_set(:@client, @client)
    @expansion = Chef::RunList::RunListExpansion.new(@node.chef_environment, [])

    expect(@node.run_list).to receive(:expand).with(@node.chef_environment).and_return(@expansion)
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url]).and_return(@chef_rest)
    @session.rebuild_context
  end

  it "passes the shell CLI args to the client" do
    expect(Chef::Client).to receive(:new).with(nil, Chef::Config[:shell_config]).and_return(@client)
    @session.send(:rebuild_node)
  end

end

describe Shell::StandAloneSession do
  before do
    Chef::Config[:shell_config] = { :override_runlist => [Chef::RunList::RunListItem.new("shell::override")] }
    @session = Shell::StandAloneSession.instance
    @node = @session.node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = @session.run_context = Chef::RunContext.new(@node, {}, @events)
    @recipe = @session.recipe = Chef::Recipe.new(nil, nil, @run_context)
    Shell::Extensions.extend_context_recipe(@recipe)
  end

  it "has a run_context" do
    expect(@session.run_context).to equal(@run_context)
  end

  it "returns a collection based on it's standalone recipe file" do
    expect(@session.resource_collection).to eq(@recipe.run_context.resource_collection)
  end

  it "gives nil for the definitions (for now)" do
    expect(@session.definitions).to be_nil
  end

  it "gives nil for the cookbook_loader" do
    expect(@session.cookbook_loader).to be_nil
  end

  it "runs chef with the standalone recipe" do
    allow(@session).to receive(:node_built?).and_return(true)
    allow(Chef::Log).to receive(:level)
    chef_runner = double("Chef::Runner.new", :converge => :converged)
    # pre-heat resource collection cache
    @session.resource_collection

    expect(Chef::Runner).to receive(:new).with(@session.recipe.run_context).and_return(chef_runner)
    expect(@recipe.run_chef).to eq(:converged)
  end

  it "passes the shell CLI args to the client" do
    @client = double("Chef::Client.new",
                     :run_ohai => true,
                     :load_node => true,
                     :build_node => true,
                     :register => true,
                     :sync_cookbooks => {})
    expect(Chef::Client).to receive(:new).with(nil, Chef::Config[:shell_config]).and_return(@client)
    @session.send(:rebuild_node)
  end

end

describe Shell::SoloLegacySession do
  before do
    Chef::Config[:shell_config] = { :override_runlist => [Chef::RunList::RunListItem.new("shell::override")] }
    Chef::Config[:shell_solo] = true
    @session = Shell::SoloLegacySession.instance
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
    allow(@session).to receive(:node_built?).and_return(true)
    kitteh = Chef::Resource::Cat.new("keyboard")
    @recipe.run_context.resource_collection << kitteh
    expect(@session.resource_collection).to include(kitteh)
  end

  it "returns definitions from its compilation object" do
    expect(@session.definitions).to eq(@run_context.definitions)
  end

  it "keeps json attribs and passes them to the node for consumption" do
    @session.node_attributes = { "besnard_lakes" => "are_the_dark_horse" }
    expect(@session.node["besnard_lakes"]).to eq("are_the_dark_horse")
    #pending "1) keep attribs in an ivar 2) pass them to the node 3) feed them to the node on reset"
  end

  it "generates its resource collection from the compiled cookbooks and the ad hoc recipe" do
    allow(@session).to receive(:node_built?).and_return(true)
    kitteh_cat = Chef::Resource::Cat.new("kitteh")
    @run_context.resource_collection << kitteh_cat
    keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @recipe.run_context.resource_collection << keyboard_cat
    #@session.rebuild_collection
    expect(@session.resource_collection).to include(kitteh_cat, keyboard_cat)
  end

  it "runs chef with a resource collection from the compiled cookbooks" do
    allow(@session).to receive(:node_built?).and_return(true)
    allow(Chef::Log).to receive(:level)
    chef_runner = double("Chef::Runner.new", :converge => :converged)
    expect(Chef::Runner).to receive(:new).with(an_instance_of(Chef::RunContext)).and_return(chef_runner)

    expect(@recipe.run_chef).to eq(:converged)
  end

  it "passes the shell CLI args to the client" do
    @client = double("Chef::Client.new",
                     :run_ohai => true,
                     :load_node => true,
                     :build_node => true,
                     :register => true,
                     :sync_cookbooks => {})
    expect(Chef::Client).to receive(:new).with(nil, Chef::Config[:shell_config]).and_return(@client)
    @session.send(:rebuild_node)
  end

end
