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

require 'spec_helper'

describe Chef::Knife::NodeRunListAdd do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeRunListAdd.new
    @knife.config = {
      :after => nil
    }
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

    it "should add to the run list" do
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

    describe "with -a or --after specified" do
      it "should add to the run list after the specified entry" do
        @node.run_list << "role[acorns]"
        @node.run_list << "role[barn]"
        @knife.config[:after] = "role[acorns]"
        @knife.run
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[monkey]"
        @node.run_list[2].should == "role[barn]"
      end
    end

    describe "with more than one role or recipe" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey],role[duck]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[monkey]"
        @node.run_list[2].should == "role[duck]"
      end
    end

    describe "with more than one role or recipe with space between items" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey], role[duck]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[monkey]"
        @node.run_list[2].should == "role[duck]"
      end
    end

    describe "with more than one role or recipe as different arguments" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey]", "role[duck]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[monkey]"
        @node.run_list[2].should == "role[duck]"
      end
    end

    describe "with more than one role or recipe as different arguments and list separated by comas" do
      it "should add to the run list all the entries" do
        @knife.name_args = [ "adam", "role[monkey]", "role[duck],recipe[bird::fly]" ]
        @node.run_list << "role[acorns]"
        @knife.run
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[monkey]"
        @node.run_list[2].should == "role[duck]"
      end
    end

    describe "with one role or recipe but with an extraneous comma" do
      it "should add to the run list one item" do
        @knife.name_args = [ "adam", "role[monkey]," ]
        @node.run_list << "role[acorns]"
        @knife.run
        @node.run_list[0].should == "role[acorns]"
        @node.run_list[1].should == "role[monkey]"
      end
    end
  end
end



