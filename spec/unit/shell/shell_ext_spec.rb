# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2009-2016, Daniel DeLeo
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

describe Shell::Extensions do
  describe "extending object for top level methods" do

    before do
      @shell_client = TestableShellSession.instance
      allow(Shell).to receive(:session).and_return(@shell_client)
      @job_manager = TestJobManager.new
      @root_context = Object.new
      @root_context.instance_eval(&ObjectTestHarness)
      Shell::Extensions.extend_context_object(@root_context)
      @root_context.conf = double("irbconf")
    end

    it "finds a subsession in irb for an object" do
      target_context_obj = Chef::Node.new

      irb_context = double("context", :main => target_context_obj)
      irb_session = double("irb session", :context => irb_context)
      @job_manager.jobs = [[:thread, irb_session]]
      allow(@root_context).to receive(:jobs).and_return(@job_manager)
      @root_context.ensure_session_select_defined
      expect(@root_context.jobs.select_shell_session(target_context_obj)).to eq(irb_session)
      expect(@root_context.jobs.select_shell_session(:idontexist)).to be_nil
    end

    it "finds, then switches to a session" do
      @job_manager.jobs = []
      allow(@root_context).to receive(:ensure_session_select_defined)
      allow(@root_context).to receive(:jobs).and_return(@job_manager)
      expect(@job_manager).to receive(:select_shell_session).and_return(:the_shell_session)
      expect(@job_manager).to receive(:switch).with(:the_shell_session)
      @root_context.find_or_create_session_for(:foo)
    end

    it "creates a new session if an existing one isn't found" do
      @job_manager.jobs = []
      allow(@root_context).to receive(:jobs).and_return(@job_manager)
      allow(@job_manager).to receive(:select_shell_session).and_return(nil)
      expect(@root_context).to receive(:irb).with(:foo)
      @root_context.find_or_create_session_for(:foo)
    end

    it "switches to recipe context" do
      expect(@root_context).to respond_to(:recipe_mode)
      @shell_client.recipe = :monkeyTime
      expect(@root_context).to receive(:find_or_create_session_for).with(:monkeyTime)
      @root_context.recipe_mode
    end

    it "switches to attribute context" do
      expect(@root_context).to respond_to(:attributes_mode)
      @shell_client.node = "monkeyNodeTime"
      expect(@root_context).to receive(:find_or_create_session_for).with("monkeyNodeTime")
      @root_context.attributes_mode
    end

    it "has a help command" do
      expect(@root_context).to respond_to(:help)
    end

    it "turns irb tracing on and off" do
      expect(@root_context).to respond_to(:trace)
      expect(@root_context.conf).to receive(:use_tracer=).with(true)
      allow(@root_context).to receive(:tracing?)
      @root_context.tracing :on
    end

    it "says if tracing is on or off" do
      allow(@root_context.conf).to receive(:use_tracer).and_return(true)
      expect(@root_context).to receive(:puts).with("tracing is on")
      @root_context.tracing?
    end

    it "prints node attributes" do
      node = double("node", :attribute => { :foo => :bar })
      @shell_client.node = node
      expect(@root_context).to receive(:pp).with({ :foo => :bar })
      @root_context.ohai
      expect(@root_context).to receive(:pp).with(:bar)
      @root_context.ohai(:foo)
    end

    it "resets the recipe and reloads ohai data" do
      expect(@shell_client).to receive(:reset!)
      @root_context.reset
    end

    it "turns irb echo on and off" do
      expect(@root_context.conf).to receive(:echo=).with(true)
      @root_context.echo :on
    end

    it "says if echo is on or off" do
      allow(@root_context.conf).to receive(:echo).and_return(true)
      expect(@root_context).to receive(:puts).with("echo is on")
      @root_context.echo?
    end

    it "gives access to the stepable iterator" do
      allow(Shell::StandAloneSession.instance).to receive(:reset!)
      allow(Shell.session).to receive(:rebuild_context)
      events = Chef::EventDispatch::Dispatcher.new
      run_context = Chef::RunContext.new(Chef::Node.new, {}, events)
      run_context.resource_collection.instance_variable_get(:@resource_list).instance_variable_set(:@iterator, :the_iterator)
      Shell.session.run_context = run_context
      expect(@root_context.chef_run).to eq(:the_iterator)
    end

    it "lists directory contents" do
      entries = %w{. .. someFile}
      expect(Dir).to receive(:entries).with("/tmp").and_return(entries)
      @root_context.ls "/tmp"
    end

  end

  describe "extending the recipe object" do

    before do
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(Chef::Node.new, {}, @events)
      @recipe_object = Chef::Recipe.new(nil, nil, @run_context)
      Shell::Extensions.extend_context_recipe(@recipe_object)
    end

    it "gives a list of the resources" do
      resource = @recipe_object.file("foo")
      expect(@recipe_object).to receive(:pp).with(["file[foo]"])
      @recipe_object.resources
    end

  end
end
