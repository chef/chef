#
# Author:: Mike Fiedler (<miketheman@gmail.com>)
# Copyright:: Copyright (c) 2013 Mike Fiedler
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

describe Chef::Knife::NodeRunListSet do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeRunListSet.new
    @knife.config = {}
    @knife.name_args = [ "adam", "role[monkey]" ]
    @knife.stub!(:output).and_return(true)
    @node = Chef::Node.new()
    @node.stub!(:save).and_return(true)
    Chef::Node.stub!(:load).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      Chef::Node.should_receive(:load).with("adam")
      @knife.run
    end

    it "should set the run list" do
      @knife.run
      @node.run_list[0].should == 'role[monkey]'
    end

    it "should save the node" do
      @node.should_receive(:save)
      @knife.run
    end

    it "should print the run list" do
      @knife.should_receive(:output).and_return(true)
      @knife.run
    end

    describe "with more than one role or recipe" do
      it "should set the run list to all the entries" do
        @knife.name_args = [ "adam", "role[monkey],role[duck]" ]
        @knife.run
        @node.run_list[0].should == "role[monkey]"
        @node.run_list[1].should == "role[duck]"
      end
    end

    describe "with more than one role or recipe with space between items" do
      it "should set the run list to all the entries" do
        @knife.name_args = [ "adam", "role[monkey], role[duck]" ]
        @knife.run
        @node.run_list[0].should == "role[monkey]"
        @node.run_list[1].should == "role[duck]"
      end
    end

    describe "with more than one role or recipe as different arguments" do
      it "should set the run list to all the entries" do
        @knife.name_args = [ "adam", "role[monkey]", "role[duck]" ]
        @knife.run
        @node.run_list[0].should == "role[monkey]"
        @node.run_list[1].should == "role[duck]"
      end
    end

    describe "with more than one role or recipe as different arguments and list separated by comas" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey]", "role[duck],recipe[bird::fly]" ]
        @knife.run
        @node.run_list[0].should == "role[monkey]"
        @node.run_list[1].should == "role[duck]"
      end
    end

    describe "with one role or recipe but with an extraneous comma" do
      it "should add to the run list one item" do
        @knife.name_args = [ "adam", "role[monkey]," ]
        @knife.run
        @node.run_list[0].should == "role[monkey]"
      end
    end

    describe "with an existing run list" do
      it "should overwrite any existing run list items" do
        @node.run_list << "role[acorns]"
        @node.run_list << "role[zebras]"
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[zebras]"
        @node.run_list.run_list_items.size.should == 2

        @knife.name_args = [ "adam", "role[monkey]", "role[duck]" ]
        @knife.run
        @node.run_list[0].should == "role[monkey]"
        @node.run_list[1].should == "role[duck]"
        @node.run_list.run_list_items.size.should == 2
      end
    end

    describe "with no role or recipe" do
      # Set up outputs for inspection later
      before(:each) do
        @stdout = StringIO.new
        @stderr = StringIO.new

        @knife.ui.stub!(:stdout).and_return(@stdout)
        @knife.ui.stub!(:stderr).and_return(@stderr)
      end

      it "should exit" do
        @knife.name_args = [ "adam" ]
        lambda { @knife.run }.should raise_error SystemExit
      end

      it "should show the user" do
        @knife.name_args = [ "adam" ]

        begin ; @knife.run ; rescue SystemExit ; end

        @stdout.string.should eq "USAGE: knife node run_list set NODE ENTRIES (options)\n"
        @stderr.string.should eq "FATAL: You must supply both a node name and a run list.\n"
      end
    end

  end
end
