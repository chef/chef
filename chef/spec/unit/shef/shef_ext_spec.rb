# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Shef::Extensions do
  describe "extending object for top level methods" do

    before do
      @shef_client = TestableShefSession.instance
      Shef.stub!(:session).and_return(@shef_client)
      @job_manager = TestJobManager.new
      @root_context = Object.new
      @root_context.instance_eval(&ObjectTestHarness)
      Shef::Extensions.extend_context_object(@root_context)
      @root_context.conf = mock("irbconf")
    end

    it "finds a subsession in irb for an object" do
      target_context_obj = Chef::Node.new

      irb_context = mock("context", :main => target_context_obj)
      irb_session = mock("irb session", :context => irb_context)
      @job_manager.jobs = [[:thread, irb_session]]
      @root_context.stub!(:jobs).and_return(@job_manager)
      @root_context.ensure_session_select_defined
      @root_context.jobs.select_shef_session(target_context_obj).should == irb_session
      @root_context.jobs.select_shef_session(:idontexist).should be_nil
    end

    it "finds, then switches to a session" do
      @job_manager.jobs = []
      @root_context.stub!(:ensure_session_select_defined)
      @root_context.stub!(:jobs).and_return(@job_manager)
      @job_manager.should_receive(:select_shef_session).and_return(:the_shef_session)
      @job_manager.should_receive(:switch).with(:the_shef_session)
      @root_context.find_or_create_session_for(:foo)
    end

    it "creates a new session if an existing one isn't found" do
      @job_manager.jobs = []
      @root_context.stub!(:jobs).and_return(@job_manager)
      @job_manager.stub!(:select_shef_session).and_return(nil)
      @root_context.should_receive(:irb).with(:foo)
      @root_context.find_or_create_session_for(:foo)
    end

    it "switches to recipe context" do
      @root_context.should respond_to(:recipe)
      @shef_client.recipe = :monkeyTime
      @root_context.should_receive(:find_or_create_session_for).with(:monkeyTime)
      @root_context.recipe
    end

    it "switches to attribute context" do
      @root_context.should respond_to(:attributes)
      @shef_client.node = "monkeyNodeTime"
      @root_context.should_receive(:find_or_create_session_for).with("monkeyNodeTime")
      @root_context.attributes
    end

    it "has a help command" do
      @root_context.should respond_to(:help)
    end

    it "turns irb tracing on and off" do
      @root_context.should respond_to(:trace)
      @root_context.conf.should_receive(:use_tracer=).with(true)
      @root_context.stub!(:tracing?)
      @root_context.tracing :on
    end

    it "says if tracing is on or off" do
      @root_context.conf.stub!(:use_tracer).and_return(true)
      @root_context.should_receive(:puts).with("tracing is on")
      @root_context.tracing?
    end

    it "prints node attributes" do
      node = mock("node", :attribute => {:foo => :bar})
      @shef_client.node = node
      @root_context.should_receive(:pp).with({:foo => :bar})
      @root_context.ohai
      @root_context.should_receive(:pp).with(:bar)
      @root_context.ohai(:foo)
    end

    it "resets the recipe and reloads ohai data" do
      @shef_client.should_receive(:reset!)
      @root_context.reset
    end

    it "turns irb echo on and off" do
      @root_context.conf.should_receive(:echo=).with(true)
      @root_context.echo :on
    end

    it "says if echo is on or off" do
      @root_context.conf.stub!(:echo).and_return(true)
      @root_context.should_receive(:puts).with("echo is on")
      @root_context.echo?
    end

    it "gives access to the stepable iterator" do
      Shef::StandAloneSession.instance.stub!(:reset!)
      Shef.session.stub!(:rebuild_context)
      run_context = Chef::RunContext.new(Chef::Node.new, {})
      run_context.resource_collection.instance_variable_set(:@iterator, :the_iterator)
      Shef.session.run_context = run_context
      @root_context.chef_run.should == :the_iterator
    end

    it "lists directory contents" do
      entries = %w{. .. someFile}
      Dir.should_receive(:entries).with("/tmp").and_return(entries)
      @root_context.ls "/tmp"
    end

  end

  describe "extending the recipe object" do

    before do
      @run_context = Chef::RunContext.new(Chef::Node.new, {})
      @recipe_object = Chef::Recipe.new(nil, nil, @run_context)
      Shef::Extensions.extend_context_recipe(@recipe_object)
    end

    it "gives a list of the resources" do
      resource = @recipe_object.file("foo")
      @recipe_object.should_receive(:pp).with(["file[foo]"])
      @recipe_object.resources
    end

  end
end
