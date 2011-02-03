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

require 'chef/expander/vnode_supervisor'

describe Expander::VNodeSupervisor do
  before do
    @log_stream = StringIO.new
    @local_node = Expander::Node.new("1101d02d-1547-45ab-b2f6-f0153d0abb34", "fermi.local", 12342)
    @vnode_supervisor = Expander::VNodeSupervisor.new
    @vnode_supervisor.instance_variable_set(:@local_node, @local_node)
    @vnode_supervisor.log.init(@log_stream)
    @vnode = Expander::VNode.new("42", @vnode_supervisor)
  end

  after do
    b = Bunny.new(OPSCODE_EXPANDER_MQ_CONFIG)
    b.start
    b.exchange(@vnode_supervisor.local_node.broadcast_control_exchange_name, :type => :fanout).delete
    b.queue(@vnode_supervisor.local_node.broadcast_control_queue_name).purge
    b.stop
  end

  it "keeps a list of vnodes" do
    @vnode_supervisor.vnodes.should be_empty
    @vnode_supervisor.vnode_added(@vnode)
    @vnode_supervisor.vnodes.should == [42]
  end

  it "has a callback for vnode removal" do
    @vnode_supervisor.vnode_added(@vnode)
    @vnode_supervisor.vnodes.should == [42]
    @vnode_supervisor.vnode_removed(@vnode)
    @vnode_supervisor.vnodes.should be_empty
  end

  it "spawns a vnode" do
    AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
      @vnode_supervisor.spawn_vnode(42)
      MQ.topic('foo')
      EM.add_timer(0.1) do
        AMQP.hard_reset!
      end
    end
    @vnode_supervisor.vnodes.should == [42]
  end

  it "subscribes to the control queue" do
    AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
      @vnode_supervisor.start([])
      @vnode_supervisor.should_receive(:process_control_message).with("hello_robot_overlord")
      Expander::Node.local_node.broadcast_message("hello_robot_overlord")
      EM.add_timer(0.1) do
        AMQP.hard_reset!
      end
    end
  end

  it "periodically publishes its list of vnodes to the gossip queue" do
    pending("disabled until cluster healing is implemented")
  end

  describe "when responding to control messages" do
    it "passes vnode table updates to its vnode table" do
      vnode_table_update = Expander::Node.local_node.to_hash
      vnode_table_update[:vnodes] = (0...16).to_a
      vnode_table_update[:update] = :add
      update_message = Yajl::Encoder.encode({:action => :update_vnode_table, :data => vnode_table_update})
      @vnode_supervisor.process_control_message(update_message)
      @vnode_supervisor.vnode_table.vnodes_by_node[Expander::Node.local_node].should == (0...16).to_a
    end

    it "publishes the vnode table when it receives a :vnode_table_publish message" do
      pending "disabled until cluster healing is implemented"
      update_message = Yajl::Encoder.encode({:action => :vnode_table_publish})
      @vnode_supervisor.process_control_message(update_message)
    end

    describe "and it is the leader" do
      before do
        vnode_table_update = Expander::Node.local_node.to_hash
        vnode_table_update[:vnodes] = (0...16).to_a
        vnode_table_update[:update] = :add
        update_message = Yajl::Encoder.encode({:action => :update_vnode_table, :data => vnode_table_update})
        @vnode_supervisor.process_control_message(update_message)
      end

      it "distributes the vnode when it receives a recover_vnode message and it is the leader" do
        control_msg = {:action => :recover_vnode, :vnode_id => 23}

        @vnode_supervisor.local_node.should_receive(:shared_message)
        @vnode_supervisor.process_control_message(Yajl::Encoder.encode(control_msg))
      end

      it "waits before re-advertising a vnode as available" do
        pending("not yet implemented")
        vnode_table_update = Expander::Node.local_node.to_hash
        vnode_table_update[:vnodes] = (0...16).to_a
        vnode_table_update[:update] = :add
        update_message = Yajl::Encoder.encode({:action => :update_vnode_table, :data => vnode_table_update})
        @vnode_supervisor.process_control_message(update_message)

        control_msg = {:action => :recover_vnode, :vnode_id => 23}

        @vnode_supervisor.local_node.should_receive(:shared_message).once
        @vnode_supervisor.process_control_message(Yajl::Encoder.encode(control_msg))
        @vnode_supervisor.process_control_message(Yajl::Encoder.encode(control_msg))
      end
    end


    it "doesn't distribute a vnode when it is not the leader" do
      vnode_table_update = Expander::Node.local_node.to_hash
      vnode_table_update[:vnodes] = (16...32).to_a
      vnode_table_update[:update] = :add
      update_message = Yajl::Encoder.encode({:action => :update_vnode_table, :data => vnode_table_update})
      @vnode_supervisor.process_control_message(update_message)

      vnode_table_update = Expander::Node.new("1c53daf0-34a1-4e4f-8069-332665453b44", 'fermi.local', 2342).to_hash
      vnode_table_update[:vnodes] = (0...16).to_a
      vnode_table_update[:update] = :add
      update_message = Yajl::Encoder.encode({:action => :update_vnode_table, :data => vnode_table_update})
      @vnode_supervisor.process_control_message(update_message)

      control_msg = {:action => :recover_vnode, :vnode_id => 42}

      @vnode_supervisor.local_node.should_not_receive(:shared_message)
      @vnode_supervisor.process_control_message(Yajl::Encoder.encode(control_msg))
    end

  end

end
