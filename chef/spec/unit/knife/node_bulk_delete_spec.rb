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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::NodeBulkDelete do
  before(:each) do
    @knife = Chef::Knife::NodeBulkDelete.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = ["."] 
    @knife.stub!(:output).and_return(true)
    @knife.stub!(:confirm).and_return(true)
    @nodes = Hash.new
    %w{adam brent jacob}.each do |node_name|
      node = Chef::Node.new() 
      node.name(node_name)
      node.stub!(:destroy).and_return(true)
      @nodes[node_name] = node
    end
    Chef::Node.stub!(:list).and_return(@nodes)
  end

  describe "run" do

    it "should get the list of inflated nodes" do
      Chef::Node.should_receive(:list).and_return(@nodes)
      @knife.run
    end

    it "should print the nodes you are about to delete" do
      @knife.should_receive(:output).with(@knife.format_list_for_display(@nodes))
      @knife.run
    end

    it "should confirm you really want to delete them" do
      @knife.should_receive(:confirm)
      @knife.run
    end

    it "should delete each node" do
      @nodes.each_value do |n|
        n.should_receive(:destroy)
      end
      @knife.run
    end

    it "should only delete nodes that match the regex" do
      @knife.name_args = ['adam']
      @nodes['adam'].should_receive(:destroy)
      @nodes['brent'].should_not_receive(:destroy)
      @nodes['jacob'].should_not_receive(:destroy)
      @knife.run
    end

    it "should exit if the regex is not provided" do
      @knife.name_args = []
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe "with -p or --print-after" do
      it "should pretty print the node, formatted for display" do
        @knife.config[:print_after] = true
        @nodes.each_value do |n|
          @knife.should_receive(:output).with(@knife.format_for_display(n))
        end
        @knife.run
      end
    end
  end
end



