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

describe Chef::Knife::NodeDelete do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeDelete.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = [ "adam" ]
    @knife.stub!(:output).and_return(true)
    @knife.stub!(:confirm).and_return(true)
    @node = Chef::Node.new() 
    @node.stub!(:destroy).and_return(true)
    Chef::Node.stub!(:load).and_return(@node)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should confirm that you want to delete" do
      @knife.should_receive(:confirm)
      @knife.run
    end

    it "should load the node" do
      Chef::Node.should_receive(:load).with("adam").and_return(@node)
      @knife.run
    end

    it "should delete the node" do
      @node.should_receive(:destroy).and_return(@node)
      @knife.run
    end

    it "should not print the node" do
      @knife.should_not_receive(:output).with("poop")
      @knife.run
    end

    describe "with -p or --print-after" do
      it "should pretty print the node, formatted for display" do
        @knife.config[:print_after] = true
        @knife.should_receive(:format_for_display).with(@node).and_return("poop")
        @knife.should_receive(:output).with("poop")
        @knife.run
      end
    end
  end
end
