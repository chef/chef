#
# Author:: Jimmy McCrory (<jimmy.mccrory@gmail.com>)
# Copyright:: Copyright (c) 2014 Jimmy McCrory
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

describe Chef::Knife::NodeEnvironmentSet do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeEnvironmentSet.new
    @knife.name_args = [ "adam", "bar" ]
    @knife.stub(:output).and_return(true)
    @node = Chef::Node.new()
    @node.name("knifetest-node")
    @node.chef_environment << "foo"
    @node.stub(:save).and_return(true)
    Chef::Node.stub(:load).and_return(@node)
  end

  describe "run" do
    it "should load the node" do
      Chef::Node.should_receive(:load).with("adam")
      @knife.run
    end

    it "should update the environment" do
      @knife.run
      @node.chef_environment.should == 'bar'
    end

    it "should save the node" do
      @node.should_receive(:save)
      @knife.run
    end

    it "should print the environment" do
      @knife.should_receive(:output).and_return(true)
      @knife.run
    end

    describe "with no environment" do
      # Set up outputs for inspection later
      before(:each) do
        @stdout = StringIO.new
        @stderr = StringIO.new

        @knife.ui.stub(:stdout).and_return(@stdout)
        @knife.ui.stub(:stderr).and_return(@stderr)
      end

      it "should exit" do
        @knife.name_args = [ "adam" ]
        lambda { @knife.run }.should raise_error SystemExit
      end

      it "should show the user the usage and an error" do
        @knife.name_args = [ "adam" ]

        begin ; @knife.run ; rescue SystemExit ; end

        @stdout.string.should eq "USAGE: knife node environment set NODE ENVIRONMENT\n"
        @stderr.string.should eq "FATAL: You must specify a node name and an environment.\n"
      end
    end
  end
end
