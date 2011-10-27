#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

class Chef
  class IndexableTestHarness
    include Chef::IndexQueue::Indexable
    attr_reader :couchdb_id
    def couchdb_id=(value)
      self.index_id = @couchdb_id = value
    end
    attr_reader :index_id
    def index_id=(value)
        @index_id = value
    end

    def to_hash
      {"ohai_world" => "I am IndexableTestHarness", "object_id" => object_id}
    end

  end
end

class IndexQueueSpecError < RuntimeError ; end

class FauxQueue

  attr_reader :published_message, :publish_options

  # Note: If publish is not called, this published_message will cause
  # JSON parsing to die with "can't convert Symbol into String"
  def initialize
    @published_message = :epic_fail!
    @publish_options = :epic_fail!
  end

  def publish(message, options=nil)
    @published_message = message
    @publish_options = options
  end
end

class IndexConsumerTestHarness
  include Chef::IndexQueue::Consumer

  attr_reader :last_indexed_object, :unexposed_attr

  expose :index_this

  def index_this(object_to_index)
    @last_indexed_object = object_to_index
  end

  def not_exposed(arg)
    @unexposed_attr = arg
  end
end

describe Chef::IndexQueue::Indexable do
  def a_uuid
    /[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}/
  end

  before do
    Chef::IndexableTestHarness.reset_index_metadata!
    @publisher      = Chef::IndexQueue::AmqpClient.instance
    @indexable_obj  = Chef::IndexableTestHarness.new
    @item_as_hash   = {"ohai_world" => "I am IndexableTestHarness", "object_id" => @indexable_obj.object_id}

    @now = Time.now
    Time.stub!(:now).and_return(@now)
  end

  it "downcases the class name for the index_object_type when it's not explicitly set" do
    @indexable_obj.index_object_type.should == "indexable_test_harness"
  end

  it "uses an explicitly set index_object_type" do
    Chef::IndexableTestHarness.index_object_type :a_weird_name
    @indexable_obj.index_object_type.should == "a_weird_name"
  end

  it "adds 'database', 'type', and 'id' (UUID) keys to the published object" do
    with_metadata = @indexable_obj.with_indexer_metadata(:database => "foo", :id=>UUIDTools::UUID.random_create.to_s)
    with_metadata.should have(5).keys
    with_metadata.keys.should include("type", "id", "item", "database", "enqueued_at")
    with_metadata["type"].should      == "indexable_test_harness"
    with_metadata["database"].should  == "foo"
    with_metadata["item"].should      == @item_as_hash
    with_metadata["id"].should match(a_uuid)
    with_metadata["enqueued_at"].should == @now.utc.to_i
  end

  it "uses the couchdb_id if available" do
    expected_uuid = "0000000-1111-2222-3333-444444444444"
    @indexable_obj.couchdb_id = expected_uuid
    metadata_id = @indexable_obj.with_indexer_metadata["id"]
    metadata_id.should == expected_uuid
  end

  describe "adds and removes items to and from the index and respects Chef::Config[:persistent_queue]" do
    before do
      @exchange = mock("Bunny::Exchange")
      @amqp_client = mock("Bunny::Client", :start => true, :exchange => @exchange)
      @publisher.stub!(:amqp_client).and_return(@amqp_client)
      @queue = FauxQueue.new
      @publisher.should_receive(:queue_for_object).with("0000000-1111-2222-3333-444444444444").and_yield(@queue)
    end

    it "adds items to the index" do
      @amqp_client.should_not_receive(:tx_select)
      @amqp_client.should_not_receive(:tx_commit)
      @amqp_client.should_not_receive(:tx_rollback)

      @indexable_obj.add_to_index(:database => "couchdb@localhost,etc.", :id=>"0000000-1111-2222-3333-444444444444")

      published_message = Chef::JSONCompat.from_json(@queue.published_message)
      published_message.should == {"action" => "add", "payload" => {"item" => @item_as_hash,
                                                                    "type" => "indexable_test_harness",
                                                                    "database" => "couchdb@localhost,etc.",
                                                                    "id" => "0000000-1111-2222-3333-444444444444",
                                                                    "enqueued_at" => @now.utc.to_i}}
      @queue.publish_options[:persistent].should == false
    end

    it "adds items to the index transactionactionally when Chef::Config[:persistent_queue] == true" do
      @amqp_client.should_receive(:tx_select)
      @amqp_client.should_receive(:tx_commit)
      @amqp_client.should_not_receive(:tx_rollback)

      # set and restore Chef::Config[:persistent_queue] to true
      orig_value = Chef::Config[:persistent_queue]
      Chef::Config[:persistent_queue] = true
      begin
        @indexable_obj.add_to_index(:database => "couchdb@localhost,etc.", :id=>"0000000-1111-2222-3333-444444444444")
      ensure
        Chef::Config[:persistent_queue] = orig_value
      end

      published_message = Chef::JSONCompat.from_json(@queue.published_message)
      published_message.should == {"action" => "add", "payload" => {"item" => @item_as_hash,
                                                                    "type" => "indexable_test_harness",
                                                                    "database" => "couchdb@localhost,etc.",
                                                                    "id" => "0000000-1111-2222-3333-444444444444",
                                                                    "enqueued_at" => @now.utc.to_i}}
      @queue.publish_options[:persistent].should == true
    end

    it "adds items to the index transactionally when Chef::Config[:persistent_queue] == true and rolls it back when there is a failure" do
      @amqp_client.should_receive(:tx_select)
      @amqp_client.should_receive(:tx_rollback)
      @amqp_client.should_not_receive(:tx_commit)

      # cause the publish to fail, and make sure the failure is our own
      # by using a specific class
      @queue.should_receive(:publish).and_raise(IndexQueueSpecError)

      # set and restore Chef::Config[:persistent_queue] to true
      orig_value = Chef::Config[:persistent_queue]
      Chef::Config[:persistent_queue] = true
      begin
        lambda{
          @indexable_obj.add_to_index(:database => "couchdb@localhost,etc.", :id=>"0000000-1111-2222-3333-444444444444")
        }.should raise_error(IndexQueueSpecError)
      ensure
        Chef::Config[:persistent_queue] = orig_value
      end
    end

    it "removes items from the index" do
      @amqp_client.should_not_receive(:tx_select)
      @amqp_client.should_not_receive(:tx_commit)
      @amqp_client.should_not_receive(:tx_rollback)

      @indexable_obj.delete_from_index(:database => "couchdb2@localhost", :id=>"0000000-1111-2222-3333-444444444444")
      published_message = Chef::JSONCompat.from_json(@queue.published_message)
      published_message.should == {"action" => "delete", "payload" => { "item" => @item_as_hash,
                                                                        "type" => "indexable_test_harness",
                                                                        "database" => "couchdb2@localhost",
                                                                        "id" => "0000000-1111-2222-3333-444444444444",
                                                                        "enqueued_at" => @now.utc.to_i}}
      @queue.publish_options[:persistent].should == false
    end

    it "removes items from the index transactionactionally when Chef::Config[:persistent_queue] == true" do
      @amqp_client.should_receive(:tx_select)
      @amqp_client.should_receive(:tx_commit)
      @amqp_client.should_not_receive(:tx_rollback)

      # set and restore Chef::Config[:persistent_queue] to true
      orig_value = Chef::Config[:persistent_queue]
      Chef::Config[:persistent_queue] = true
      begin
        @indexable_obj.delete_from_index(:database => "couchdb2@localhost", :id=>"0000000-1111-2222-3333-444444444444")
      ensure
        Chef::Config[:persistent_queue] = orig_value
      end

      published_message = Chef::JSONCompat.from_json(@queue.published_message)
      published_message.should == {"action" => "delete", "payload" => { "item" => @item_as_hash,
                                                                        "type" => "indexable_test_harness",
                                                                        "database" => "couchdb2@localhost",
                                                                        "id" => "0000000-1111-2222-3333-444444444444",
                                                                        "enqueued_at" => @now.utc.to_i}}
      @queue.publish_options[:persistent].should == true
    end

    it "remove items from the index transactionally when Chef::Config[:persistent_queue] == true and rolls it back when there is a failure" do
      @amqp_client.should_receive(:tx_select)
      @amqp_client.should_receive(:tx_rollback)
      @amqp_client.should_not_receive(:tx_commit)

      # cause the publish to fail, and make sure the failure is our own
      # by using a specific class
      @queue.should_receive(:publish).and_raise(IndexQueueSpecError)

      # set and restore Chef::Config[:persistent_queue] to true
      orig_value = Chef::Config[:persistent_queue]
      Chef::Config[:persistent_queue] = true
      begin
        lambda{
          @indexable_obj.delete_from_index(:database => "couchdb2@localhost", :id=>"0000000-1111-2222-3333-444444444444")      }.should raise_error(IndexQueueSpecError)
      ensure
        Chef::Config[:persistent_queue] = orig_value
      end
    end
  end

end

describe Chef::IndexQueue::Consumer do
  before do
    @amqp_client  = Chef::IndexQueue::AmqpClient.instance
    @consumer     = IndexConsumerTestHarness.new
  end

  it "keeps a whitelist of exposed methods" do
    IndexConsumerTestHarness.exposed_methods.should == [:index_this]
    IndexConsumerTestHarness.whitelisted?(:index_this).should be_true
    IndexConsumerTestHarness.whitelisted?(:not_exposed).should be_false
  end

  it "doesn't route non-whitelisted methods" do
    payload_json      = {"payload" => {"a_placeholder" => "object"}, "action" => "not_exposed"}.to_json
    received_message  = {:payload => payload_json}
    lambda {@consumer.call_action_for_message(received_message)}.should raise_error(ArgumentError)
    @consumer.unexposed_attr.should be_nil
  end

  it "routes message payloads to the correct method" do
    payload_json      = {"payload" => {"a_placeholder" => "object"}, "action" => "index_this"}.to_json
    received_message  = {:payload => payload_json}
    @consumer.call_action_for_message(received_message)
    @consumer.last_indexed_object.should == {"a_placeholder" => "object"}

  end

  it "subscribes to the queue for the indexer" do
    payload_json  = {"payload" => {"a_placeholder" => "object"}, "action" => "index_this"}.to_json
    message       = {:payload => payload_json}
    queue = mock("Bunny::Queue")
    @amqp_client.stub!(:queue).and_return(queue)
    queue.should_receive(:subscribe).with(:timeout => false, :ack => true).and_yield(message)
    @consumer.run
    @consumer.last_indexed_object.should == {"a_placeholder" => "object"}
  end

end


describe Chef::IndexQueue::AmqpClient do
  before do
    Chef::Config[:amqp_host]        = '4.3.2.1'
    Chef::Config[:amqp_port]        = '1337'
    Chef::Config[:amqp_user]        = 'teh_rspecz'
    Chef::Config[:amqp_pass]        = 'access_granted2rspec'
    Chef::Config[:amqp_vhost]       = '/chef-specz'
    Chef::Config[:amqp_consumer_id] = nil

    @publisher    = Chef::IndexQueue::AmqpClient.instance
    @exchange     = mock("Bunny::Exchange")

    @amqp_client  = mock("Bunny::Client", :start => true, :exchange => @exchange)
    def @amqp_client.connected?; false; end # stubbing predicate methods not working?
    Bunny.stub!(:new).and_return(@amqp_client)

    @publisher.reset!
  end

  after do
    @publisher.disconnected!
  end

  it "is a singleton" do
    lambda {Chef::IndexQueue::Indexable::AmqpClient.new}.should raise_error
  end

  it "creates an amqp client object on demand, starts a connection, and caches it" do
    @amqp_client.should_receive(:start).once
    @amqp_client.should_receive(:qos).with(:prefetch_count => 1)
    ::Bunny.should_receive(:new).once.and_return(@amqp_client)
    @publisher.amqp_client.should == @amqp_client
    @publisher.amqp_client
  end

  it "configures the amqp client with credentials from the config file" do
    @publisher.reset!
    Bunny.should_receive(:new).with(:spec => '08', :host => '4.3.2.1', :port => '1337', :user => "teh_rspecz",
                                    :pass => "access_granted2rspec", :vhost => '/chef-specz').and_return(@amqp_client)
    @amqp_client.should_receive(:qos).with(:prefetch_count => 1)
    @publisher.amqp_client.should == @amqp_client
  end

  it "creates an amqp exchange on demand and caches it" do
    @amqp_client.stub!(:qos)
    @publisher.exchange.should == @exchange
    @amqp_client.should_not_receive(:exchange)
    @publisher.exchange.should == @exchange
  end

  describe "publishing" do

    before do
      @queue_1 = FauxQueue.new
      @queue_2 = FauxQueue.new

      @amqp_client.stub!(:qos)
      #@amqp_client.stub!(:queue).and_return(@queue)
      @data = {"some_data" => "in_a_hash"}
    end

    it "resets the client upon a Bunny::ServerDownError when publishing" do
      Bunny.stub!(:new).and_return(@amqp_client)
      @amqp_client.should_receive(:queue).with("vnode-68", {:passive=>false, :durable=>true, :exclusive=>false, :auto_delete=>false}).twice.and_return(@queue_1, @queue_2)

      @queue_1.should_receive(:publish).with(@data).and_raise(Bunny::ServerDownError)
      @queue_2.should_receive(:publish).with(@data).and_raise(Bunny::ServerDownError)

      @publisher.should_receive(:disconnected!).at_least(3).times
      lambda {@publisher.queue_for_object("00000000-1111-2222-3333-444444444444") {|q| q.publish(@data)}}.should raise_error(Bunny::ServerDownError)
    end

    it "resets the client upon a Bunny::ConnectionError when publishing" do
      Bunny.stub!(:new).and_return(@amqp_client)
      @amqp_client.should_receive(:queue).with("vnode-68", {:passive=>false, :durable=>true, :exclusive=>false, :auto_delete=>false}).twice.and_return(@queue_1, @queue_2)

      @queue_1.should_receive(:publish).with(@data).and_raise(Bunny::ConnectionError)
      @queue_2.should_receive(:publish).with(@data).and_raise(Bunny::ConnectionError)

      @publisher.should_receive(:disconnected!).at_least(3).times
      lambda {@publisher.queue_for_object("00000000-1111-2222-3333-444444444444") {|q| q.publish(@data)}}.should raise_error(Bunny::ConnectionError)
    end

    it "resets the client upon a Errno::ECONNRESET when publishing" do
      Bunny.stub!(:new).and_return(@amqp_client)
      @amqp_client.should_receive(:queue).with("vnode-68", {:passive=>false, :durable=>true, :exclusive=>false, :auto_delete=>false}).twice.and_return(@queue_1, @queue_2)

      @queue_1.should_receive(:publish).with(@data).and_raise(Errno::ECONNRESET)
      @queue_2.should_receive(:publish).with(@data).and_raise(Errno::ECONNRESET)

      @publisher.should_receive(:disconnected!).at_least(3).times
      lambda {@publisher.queue_for_object("00000000-1111-2222-3333-444444444444") {|q| q.publish(@data)}}.should raise_error(Errno::ECONNRESET)
    end

  end

  it "stops bunny and clears subscriptions" do
    bunny_client  = mock("Bunny::Client")
    @publisher.instance_variable_set(:@amqp_client, bunny_client)
    bunny_client.should_receive(:stop)
    @publisher.stop
  end

end
