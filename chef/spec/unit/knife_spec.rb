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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Knife do
  before(:each) do
    @knife = Chef::Knife.new
    @knife.stub!(:puts)
    @knife.stub!(:print)
    Chef::Knife.stub!(:puts)
  end

  describe "class method" do
    describe "load_commands" do
      it "should require all the sub commands" do
        sub_classes = Chef::Knife.load_commands
        sub_classes.should have_key("node_show")
        sub_classes["node_show"].should == "NodeShow"
      end
    end

    describe "list_commands" do
      before(:each) do
        @orig_argv ||= ARGV
        redefine_argv([])
      end

      after(:each) do
        redefine_argv(@orig_argv)
      end

      it "should load commands" do
        Chef::Knife.should_receive(:load_commands)
        Chef::Knife.list_commands
      end
    end

    describe "build_sub_class" do
      before(:each) do
        Chef::Knife.load_commands
      end

      it "should build a sub class" do
        Chef::Knife.build_sub_class("node_show").should be_a_kind_of(Chef::Knife::NodeShow)
      end

      it "should not merge options if none are passed" do
        Chef::Knife::NodeShow.options.should_not_receive(:merge!)
        Chef::Knife.build_sub_class("node_show")
      end

      it "should merge options if some are passed" do
        Chef::Knife::NodeShow.options.should_receive(:merge!).with(Chef::Application::Knife.options)
        Chef::Knife.build_sub_class("node_show", Chef::Application::Knife.options)
      end
    end

    describe "find_command" do
      before(:each) do
        @args = [ "node", "show", "computron" ]
        @sub_class = Chef::Knife::NodeShow.new
        @sub_class.stub!(:parse_options).and_return([@args[-1]])
        @sub_class.stub!(:configure_chef).and_return(true)
        Chef::Knife.stub!(:build_sub_class).and_return(@sub_class)
      end

      it "should find the most appropriate class" do
        Chef::Knife.should_receive(:build_sub_class).with("node_show", {}).and_return(@sub_class)
        Chef::Knife.find_command(@args).should be_a_kind_of(Chef::Knife::NodeShow)
      end

      it "should parse the configuration arguments" do
        @sub_class.should_receive(:parse_options).with(@args)
        Chef::Knife.find_command(@args)
      end

      it "should set the name args" do
        @sub_class.should_receive(:name_args=).with([@args[-1]])
        Chef::Knife.find_command(@args)
      end

      it "should exit 10 if the sub command is not found" do
        Chef::Knife.stub!(:list_commands).and_return(true)
        Chef::Log.should_receive(:fatal)
        lambda { 
          Chef::Knife.find_command([ "monkey", "man" ]) 
        }.should raise_error(SystemExit) { |e| e.status.should == 10 }
      end
    end
  end

  describe "initialize" do
    it "should create a new Chef::Knife" do
      @knife.should be_a_kind_of(Chef::Knife)
    end
  end

  describe "format_list_for_display" do
    it "should print the full hash if --with-uri is true" do
      @knife.config[:with_uri] = true
      @knife.format_list_for_display({ :marcy => :playground }).should == { :marcy => :playground }
    end

    it "should print only the keys if --with-uri is false" do
      @knife.config[:with_uri] = false
      @knife.format_list_for_display({ :marcy => :playground }).should == [ :marcy ] 
    end
  end

  describe "format_for_display" do
    it "should return the raw data" do
      input = { :gi => :go }
      @knife.format_for_display(input).should == input
    end

    describe "with a data bag item" do
      it "should use the raw data" do
        dbi = mock(Chef::DataBagItem, :kind_of? => true)
        dbi.should_receive(:raw_data).and_return({ "monkey" => "soup" })
        @knife.format_for_display(dbi).should == { "monkey" => "soup" }
      end
    end

    describe "with --attribute passed" do
      it "should return the deeply nested attribute" do
        input = { "gi" => { "go" => "ge" } }
        @knife.config[:attribute] = "gi.go"
        @knife.format_for_display(input).should == { "gi.go" => "ge" } 
      end
    end

    describe "with --run-list passed" do
      it "should return the run list" do
        input = Chef::Node.new 
        input.run_list("role[monkey]", "role[churchmouse]")
        @knife.config[:run_list] = true
        response = @knife.format_for_display(input)
        response["run_list"][0].should == "role[monkey]"
        response["run_list"][1].should == "role[churchmouse]"
      end
    end
  end

  describe "confirm" do
    before(:each) do
      @question = "monkeys rule"
      Kernel.stub!(:print).and_return(true)
      STDIN.stub!(:readline).and_return("y")
    end

    it "should return true if you answer Y" do
      STDIN.stub!(:readline).and_return("Y")
      @knife.confirm(@question).should == true
    end

    it "should return true if you answer y" do
      STDIN.stub!(:readline).and_return("y")
      @knife.confirm(@question).should == true
    end

    it "should exit 3 if you answer N" do
      STDIN.stub!(:readline).and_return("N")
      lambda { 
        @knife.confirm(@question)
      }.should raise_error(SystemExit) { |e| e.status.should == 3 } 
    end

    it "should exit 3 if you answer n" do
      STDIN.stub!(:readline).and_return("n")
      lambda { 
        @knife.confirm(@question)
      }.should raise_error(SystemExit) { |e| e.status.should == 3 } 
    end

    describe "with --y or --yes passed" do
      it "should return true" do
        @knife.config[:yes] = true
        @knife.confirm(@question).should == true
      end
    end

  end

end

