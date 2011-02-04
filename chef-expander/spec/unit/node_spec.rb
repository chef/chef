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

require 'ostruct'
require 'chef/expander/node'

describe Expander::Node do

  it "can be created from a hash" do
    node_info = { :foo => :blargh,
                  :guid => "93226974-6d0b-4ca6-8d42-124dd55e0076",
                  :hostname_f => "fermi.local", :pid => 12345}
    unmodified_hash = node_info.dup
    node_from_hash = Expander::Node.from_hash(node_info)
    node_info.should == unmodified_hash
    node_from_hash.guid.should == "93226974-6d0b-4ca6-8d42-124dd55e0076"
    node_from_hash.hostname_f.should == "fermi.local"
    node_from_hash.pid.should == 12345
  end

  describe "when first created" do
    before do
      @guid = "93226974-6d0b-4ca6-8d42-124dd55e0076"
      @hostname_f = "fermi.local"
      @pid = 12345
      @node = Expander::Node.new(@guid, @hostname_f, @pid)
    end

    it "has the guid it was created with" do
      @node.guid.should == @guid
    end

    it "has the hostname it was created with" do
      @node.hostname_f.should == @hostname_f
    end

    it "has the pid it was created with" do
      @node.pid.should == @pid
    end

    it "names its shared control queue using a constant/consistent name" do
      @node.shared_control_queue_name.should == "chef-search-control--shared"
    end

    it "names its exclusive control queue after its hostname, pid, and guid" do
      @node.exclusive_control_queue_name.should == "fermi.local--12345--93226974-6d0b-4ca6-8d42-124dd55e0076--exclusive-control"
    end

    it "names its broadcast control queue after its hostname, pid, and guid" do
      @node.broadcast_control_queue_name.should == "fermi.local--12345--93226974-6d0b-4ca6-8d42-124dd55e0076--broadcast"
    end

    it "names the broadcast control exchange using a consistent name" do
      @node.broadcast_control_exchange_name.should == 'chef-search-control--broadcast'
    end

    it "generates its hash from a string concatenting the hostname, pid and guid" do
      concat_string = "fermi.local--12345--93226974-6d0b-4ca6-8d42-124dd55e0076"
      @node.hash.should == concat_string.hash
    end

    it "is eql to another Node if it has the same guid, hostname, and pid" do
      other = Expander::Node.new(@guid.dup, @hostname_f.dup, @pid)
      @node.should eql(other)
    end

    it "is == to another object if it has the same guid, hostname, and pid" do
      other = Class.new(Expander::Node).new(@guid.dup, @hostname_f.dup, @pid)
      other.should == @node
    end

    it "converts to a hash" do
      @node.to_hash.should == {:guid => @guid, :hostname_f => @hostname_f, :pid => @pid}
    end

  end

  describe "when describing the node it's running on" do
    before do
      hostname_f = OpenStruct.new(:stdout => "fermi.local\n")
      Expander::Node.stub!(:shell_out!).and_return(hostname_f)
      @node = Expander::Node.local_node
    end

    it "uses the current machine's hostname -f for the hostname" do
      @node.hostname_f.should == %x(hostname -f).strip
    end

    it "uses the current process id for the pid" do
      @node.pid.should == Process.pid
    end

    it "generates a guid for the guid" do
      @node.guid.should match /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
    end
  end

  describe "when sending and receiving messages" do

    before do
      @guid = "93226974-6d0b-4ca6-8d42-124dd55e0076"
      @hostname_f = "fermi.local"
      @pid = rand(10000)
      @node = Expander::Node.new(@guid, @hostname_f, @pid)
      @log_stream = StringIO.new
      @node.log.init(@log_stream)
    end

    after do
      b = Bunny.new(OPSCODE_EXPANDER_MQ_CONFIG)
      b.start
      b.exchange(@node.broadcast_control_exchange_name, :type => :fanout).delete
      b.stop
    end

    it "receives messages on the broadcast exchange" do
      messages = []

      AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
        @node.start do |message|
          messages << message
        end

        @node.broadcast_message("hello everybody")

        EM.add_timer(0.1) {AMQP.hard_reset!}
      end

      messages.should == ["hello everybody"]
    end

    it "receives messages on its exclusive queue" do
      messages = []

      AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
        @node.start do |message|
          messages << message
        end

        @node.direct_message("hello node")

        EM.add_timer(0.1) {AMQP.hard_reset!}
      end

      messages.should == ["hello node"]
    end

    it "receives messages on the shared queue" do
      messages = []

      AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
        @node.start do |message|
          messages << message
        end

        @node.shared_message("hello one of N")

        EM.add_timer(0.1) {AMQP.hard_reset!}
      end

      messages.should == ["hello one of N"]
    end

  end

end
