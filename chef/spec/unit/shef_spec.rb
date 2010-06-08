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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "ostruct"

class ObjectTestHarness
  attr_accessor :conf
  
  desc "rspecin'"
  def rspec_method
  end
end

class TestJobManager
  attr_accessor :jobs
end

class TestableShefSession < Shef::ShefSession
  
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

describe Shef::ShefSession do
  
  it "is a singleton object" do
    Shef::ShefSession.should include(Singleton)
  end
  
end


describe Shef do
  
  before do
    Shef.irb_conf = {}
    Shef::ShefSession.instance.rspec_reset
    Shef::ShefSession.instance.stub!(:reset!)
  end
  
  describe "reporting its status" do
    
    it "alway says it is running" do
      Shef.should be_running
    end
    
  end
  
  describe "configuring IRB" do
    it "configures irb history" do
      Shef.configure_irb
      Shef.irb_conf[:HISTORY_FILE].should == "~/.shef_history"
      Shef.irb_conf[:SAVE_HISTORY].should == 1000
    end

    it "has a prompt like ``chef > '' in the default context" do
      Shef.configure_irb

      conf = OpenStruct.new
      conf.main = ObjectTestHarness.new
      Shef.irb_conf[:IRB_RC].call(conf)
      conf.prompt_c.should      == "chef > "
      conf.return_format.should == " => %s \n"
      conf.prompt_i.should      == "chef > "
      conf.prompt_n.should      == "chef ?> "
      conf.prompt_s.should      == "chef%l> "

    end

    it "has a prompt like ``chef:recipe > '' in recipe context" do
      Shef.configure_irb

      conf = OpenStruct.new
      conf.main = Chef::Recipe.new(nil,nil,Chef::RunContext.new(Chef::Node.new, {}))
      Shef.irb_conf[:IRB_RC].call(conf)
      conf.prompt_c.should      == "chef:recipe > "
      conf.prompt_i.should      == "chef:recipe > "
      conf.prompt_n.should      == "chef:recipe ?> "
      conf.prompt_s.should      == "chef:recipe%l> "
    end

    it "has a prompt like ``chef:attributes > '' in attributes/node context" do
      Shef.configure_irb

      conf = OpenStruct.new
      conf.main = Chef::Node.new
      Shef.irb_conf[:IRB_RC].call(conf)
      conf.prompt_c.should      == "chef:attributes > "
      conf.prompt_i.should      == "chef:attributes > "
      conf.prompt_n.should      == "chef:attributes ?> "
      conf.prompt_s.should      == "chef:attributes%l> "
    end

  end
  
  describe "convenience macros for creating the chef object" do
    
    before do
      @chef_object = ObjectTestHarness.new
    end
    
    it "creates help text for methods with descriptions" do
      ObjectTestHarness.help_descriptions.should == [["rspec_method", "rspecin'"]]
    end
    
    it "adds help text when a new method is described then defined" do
      describe_define =<<-EVAL
        desc "foo2the Bar"
        def baz
        end
      EVAL
      ObjectTestHarness.class_eval describe_define
      ObjectTestHarness.help_descriptions.should == [["rspec_method", "rspecin'"],["baz", "foo2the Bar"]]
    end
    
    it "adds help text for subcommands" do
      describe_define =<<-EVAL
        subcommands :baz_obj_command => "something you can do with baz.baz_obj_command"
        def baz
        end
      EVAL
      ObjectTestHarness.class_eval describe_define
      expected_help_text_fragments = [["rspec_method", "rspecin'"],["baz", "foo2the Bar"]]
      expected_help_text_fragments << ["baz.baz_obj_command", "something you can do with baz.baz_obj_command"]
      ObjectTestHarness.help_descriptions.should == expected_help_text_fragments
    end
    
    it "doesn't add previous subcommand help to commands defined afterward" do
      describe_define =<<-EVAL
        desc "swingFromTree"
        def monkey_time
        end
      EVAL
      ObjectTestHarness.class_eval describe_define
      ObjectTestHarness.help_descriptions.should_not include(["monkey_time.baz_obj_command", "something you can do with baz.baz_obj_command"])
    end
    
    it "creates a help banner with the command descriptions" do
      @chef_object.help_banner.should match(/^\|\ Command[\s]+\|\ Description[\s]*$/)
      @chef_object.help_banner.should match(/^\|\ rspec_method[\s]+\|\ rspecin\'[\s]*$/)
    end
  end
  
  describe "extending object for top level methods" do
    
    before do
      @shef_client = TestableShefSession.instance
      Shef.stub!(:session).and_return(@shef_client)
      @job_manager = TestJobManager.new
      @root_context = ObjectTestHarness.new
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
      # note: irb whines like a 5yo with a broken toy if you define a help
      # method on Object. have to override it in a sneaky way.
      @root_context.stub!(:puts)
      @root_context.shef_help
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
      collection = mock("collection", :iterator => :ohai2u)
      Shef.session.stub!(:collection).and_return(collection)
      @root_context.chef_run.should == :ohai2u
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
    end
    
    it "gives a list of the resources" do
      resource = @recipe_object.file("foo")
      @recipe_object.should_receive(:pp).with(["file[foo]"])
      @recipe_object.resources
    end
    
  end
  
  describe Shef::StandAloneSession do
    before do
      @session = Shef::StandAloneSession.instance
      @node = @session.node = Chef::Node.new
      @run_context = @session.run_context = Chef::RunContext.new(@node, {})
      @recipe = @session.recipe = Chef::Recipe.new(nil, nil, @run_context)
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
      @root_context.run_chef.should == :converged
    end
    
  end
  
  describe Shef::SoloSession do
    before do
      Chef::Config[:shef_solo] = true
      @session = Shef::SoloSession.instance
      @node = Chef::Node.new
      @run_context = @session.run_context = Chef::RunContext.new(@node, {})
      @session.node = @node
      #@compile = @session.compile = Chef::Compile.new(@node)
      # prevent dynamic re-compilation from raining on the parade
      #Chef::Compile.stub!(:new).and_return(@compile)
      @recipe = @session.recipe = Chef::Recipe.new(nil, nil, @run_context)
    end
    
    after do
      Chef::Config[:shef_solo] = nil
    end
    
    it "returns a collection based on it's compilation object and the extra recipe provided by shef" do
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

      @root_context.run_chef.should == :converged
    end
    
  end
  
end