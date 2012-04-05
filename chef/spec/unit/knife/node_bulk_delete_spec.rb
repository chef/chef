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

describe Chef::Knife::NodeBulkDelete do
  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::NodeBulkDelete.new
    @knife.name_args = ["."]
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @knife.ui.stub!(:confirm).and_return(true)
    @nodes = Hash.new
    %w{adam brent jacob}.each do |node_name|
      @nodes[node_name] = "http://localhost:4000/nodes/#{node_name}"
    end
  end

  describe "when creating the list of nodes" do
    it "fetches the node list" do
      expected = @nodes.inject({}) do |inflatedish, (name, uri)|
        inflatedish[name] = Chef::Node.new.tap {|n| n.name(name)}
        inflatedish
      end
      Chef::Node.should_receive(:list).and_return(@nodes)
      # I hate not having == defined for anything :(
      actual = @knife.all_nodes
      actual.keys.should =~ expected.keys
      actual.values.map {|n| n.name }.should =~ %w[adam brent jacob]
    end
  end

  describe "run" do
    before do
      @inflatedish_list = @nodes.keys.inject({}) do |nodes_by_name, name|
        node = Chef::Node.new()
        node.name(name)
        node.stub!(:destroy).and_return(true)
        nodes_by_name[name] = node
        nodes_by_name
      end
      @knife.stub!(:all_nodes).and_return(@inflatedish_list)
    end

    it "should print the nodes you are about to delete" do
      @knife.run
      @stdout.string.should match(/#{@knife.ui.list(@nodes.keys.sort, :columns_down)}/)
    end

    it "should confirm you really want to delete them" do
      @knife.ui.should_receive(:confirm)
      @knife.run
    end

    it "should delete each node" do
      @inflatedish_list.each_value do |n|
        n.should_receive(:destroy)
      end
      @knife.run
    end

    it "should only delete nodes that match the regex" do
      @knife.name_args = ['adam']
      @inflatedish_list['adam'].should_receive(:destroy)
      @inflatedish_list['brent'].should_not_receive(:destroy)
      @inflatedish_list['jacob'].should_not_receive(:destroy)
      @knife.run
    end

    it "should exit if the regex is not provided" do
      @knife.name_args = []
      lambda { @knife.run }.should raise_error(SystemExit)
    end

  end
end



