#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'chef/expander/vnode_table'
require 'chef/expander/vnode_supervisor'

describe Expander::VNodeTable do
  before do
    @vnode_supervisor = Expander::VNodeSupervisor.new
    @vnode_table = Expander::VNodeTable.new(@vnode_supervisor)

    @log_stream = StringIO.new
    @vnode_table.log.init(@log_stream)
  end

  describe "when first created" do
    it "has no nodes" do
      @vnode_table.nodes.should be_empty
    end
  end

  describe "when one node's vnode info has been added" do
    before do
      @guid = "93226974-6d0b-4ca6-8d42-124dd55e0076"
      @hostname_f = "fermi.localhost"
      @pid = 12345
      @vnodes = (0..511).to_a
      @update = {:guid => @guid, :hostname_f => @hostname_f, :pid => @pid, :vnodes => @vnodes, :update => 'update'}
      @vnode_table.update_table(@update)
    end

    it "has one vnode" do
      @vnode_table.should have(1).nodes
      @vnode_table.nodes.first.should == Expander::Node.from_hash(@update)
    end

    it "removes the node from the table when it exits the cluster" do
      update = @update
      update[:update] = 'remove'
      @vnode_table.update_table(update)
      @vnode_table.should have(0).nodes
    end

  end

  describe "when several nodes are in the table" do
    before do
      @node_1 = Expander::Node.new("93226974-6d0b-4ca6-8d42-124dd55e0076", "fermi.local", 12345)
      @node_1_hash = @node_1.to_hash
      @node_1_hash[:vnodes] = (0..511).to_a
      @node_1_hash[:update] = "update"
      @node_2 = Expander::Node.new("ad265988-f650-4a31-a97b-5dbf4db8e1b0", "fermi.local", 23425)
      @node_2_hash = @node_2.to_hash
      @node_2_hash[:vnodes] = (512..767).to_a
      @node_2_hash[:update] = "update"
      @vnode_table.update_table(@node_1_hash)
      @vnode_table.update_table(@node_2_hash)
    end

    it "determines the node with the lowest numbered vnode is the leader node" do
      @vnode_table.leader_node.should == @node_1
    end

    it "determines the local node is the leader when the local node matches the leader node" do
      Expander::Node.stub!(:local_node).and_return(@node_1)
      @vnode_table.local_node_is_leader?.should be_true
    end

    it "determines the local node is not the leader when the local node doesn't match the leader node" do
      Expander::Node.stub!(:local_node).and_return(@node_2)
      @vnode_table.local_node_is_leader?.should be_false
    end
  end

  describe "when only one node has claimed any vnodes" do
    before do
      @node_1 = Expander::Node.new("93226974-6d0b-4ca6-8d42-124dd55e0076", "fermi.local", 12345)
      @node_1_hash = @node_1.to_hash
      @node_1_hash[:vnodes] = (0..511).to_a
      @node_1_hash[:update] = "update"
      @node_2 = Expander::Node.new("ad265988-f650-4a31-a97b-5dbf4db8e1b0", "fermi.local", 23425)
      @node_2_hash = @node_2.to_hash
      @node_2_hash[:vnodes] = []
      @node_2_hash[:update] = "update"
      @vnode_table.update_table(@node_1_hash)
      @vnode_table.update_table(@node_2_hash)
    end

    it "still reliably determines who the leader is" do
      pending
    end

  end

end
