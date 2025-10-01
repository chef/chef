#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"

describe Chef::Knife::NodeBulkDelete do
  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::NodeBulkDelete.new
    @knife.name_args = ["."]
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    allow(@knife.ui).to receive(:confirm).and_return(true)
    @nodes = {}
    %w{adam brent jacob}.each do |node_name|
      @nodes[node_name] = "http://localhost:4000/nodes/#{node_name}"
    end
  end

  describe "when creating the list of nodes" do
    it "fetches the node list" do
      expected = @nodes.inject({}) do |inflatedish, (name, uri)|
        inflatedish[name] = Chef::Node.new.tap { |n| n.name(name) }
        inflatedish
      end
      expect(Chef::Node).to receive(:list).and_return(@nodes)
      # I hate not having == defined for anything :(
      actual = @knife.all_nodes
      expect(actual.keys).to match_array(expected.keys)
      expect(actual.values.map(&:name)).to match_array(%w{adam brent jacob})
    end
  end

  describe "run" do
    before do
      @inflatedish_list = @nodes.keys.inject({}) do |nodes_by_name, name|
        node = Chef::Node.new
        node.name(name)
        allow(node).to receive(:destroy).and_return(true)
        nodes_by_name[name] = node
        nodes_by_name
      end
      allow(@knife).to receive(:all_nodes).and_return(@inflatedish_list)
    end

    it "should print the nodes you are about to delete" do
      @knife.run
      expect(@stdout.string).to match(/#{@knife.ui.list(@nodes.keys.sort, :columns_down)}/)
    end

    it "should confirm you really want to delete them" do
      expect(@knife.ui).to receive(:confirm)
      @knife.run
    end

    it "should delete each node" do
      @inflatedish_list.each_value do |n|
        expect(n).to receive(:destroy)
      end
      @knife.run
    end

    it "should only delete nodes that match the regex" do
      @knife.name_args = ["adam"]
      expect(@inflatedish_list["adam"]).to receive(:destroy)
      expect(@inflatedish_list["brent"]).not_to receive(:destroy)
      expect(@inflatedish_list["jacob"]).not_to receive(:destroy)
      @knife.run
    end

    it "should exit if the regex is not provided" do
      @knife.name_args = []
      expect { @knife.run }.to raise_error(SystemExit)
    end

  end
end
