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
      {:ohai_world => "I am IndexableTestHarness", :object_id => object_id}
    end

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
    @item_as_hash   = {:ohai_world => "I am IndexableTestHarness", :object_id => @indexable_obj.object_id}
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
    with_metadata.should have(4).keys
    with_metadata.keys.should include("type", "id", "item", "database")
    with_metadata["type"].should      == "indexable_test_harness"
    with_metadata["database"].should  == "foo"
    with_metadata["item"].should      == @item_as_hash
    with_metadata["id"].should match(a_uuid)
  end
  
  it "uses the couchdb_id if available" do
    expected_uuid = "0000000-1111-2222-3333-444444444444"
    @indexable_obj.couchdb_id = expected_uuid
    metadata_id = @indexable_obj.with_indexer_metadata["id"]
    metadata_id.should == expected_uuid
  end
  
  it "sends ``add'' actions" do
    @publisher.should_receive(:send_action).with(:add, {"item" => @item_as_hash,
                                                        "type" => "indexable_test_harness",
                                                        "database" => "couchdb@localhost,etc.", 
                                                        "id" => an_instance_of(String)})
    @indexable_obj.add_to_index(:database => "couchdb@localhost,etc.", :id=>UUIDTools::UUID.random_create.to_s)
  end
  
  it "sends ``delete'' actions" do
    @publisher.should_receive(:send_action).with(:delete, { "item" => @item_as_hash,
                                                            "type" => "indexable_test_harness",
                                                            "database" => "couchdb2@localhost",
                                                            "id" => an_instance_of(String)})
    @indexable_obj.delete_from_index(:database => "couchdb2@localhost", :id=>UUIDTools::UUID.random_create.to_s)
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
      @amqp_client.stub!(:qos)
      @data = {"some_data" => "in_a_hash"}
    end
  
    it "publishes an action to the exchange" do
      @exchange.should_receive(:publish).with({"action" => "hot_chef_on_queue", "payload" => @data}.to_json)
      @publisher.send_action(:hot_chef_on_queue, @data)
    end
  
    it "resets the client upon a Bunny::ServerDownError when publishing" do
      @exchange.should_receive(:publish).twice.and_raise(Bunny::ServerDownError)
      @publisher.should_receive(:disconnected!).at_least(3).times
      lambda {@publisher.send_action(:hot_chef_on_queue, @data)}.should raise_error(Bunny::ServerDownError)
    end
    
    it "resets the client upon a Bunny::ConnectionError when publishing" do
      @exchange.should_receive(:publish).twice.and_raise(Bunny::ConnectionError)
      @publisher.should_receive(:disconnected!).at_least(3).times
      lambda {@publisher.send_action(:hot_chef_on_queue, @data)}.should raise_error(Bunny::ConnectionError)
    end
    
    it "resets the client upon a Errno::ECONNRESET when publishing" do
      @exchange.should_receive(:publish).twice.and_raise(Errno::ECONNRESET)
      @publisher.should_receive(:disconnected!).at_least(3).times
      lambda {@publisher.send_action(:hot_chef_on_queue, @data)}.should raise_error(Errno::ECONNRESET)
    end
    
  end
  
  it "creates a queue bound to its exchange with a temporary UUID" do
    @amqp_client.stub!(:qos)
    
    a_queue_name = /chef\-index-consumer\-[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}/
    
    @queue = mock("Bunny::Queue")
    @amqp_client.should_receive(:queue).with(a_queue_name, :durable => false).and_return(@queue)
    @queue.should_receive(:bind).with(@exchange)
    @publisher.queue.should == @queue
  end
  
  it "creates a durable queue bound to the exchange when a UUID is configured" do
    expected_queue_id   = "aaaaaaaa-bbbb-cccc-dddd-eeee-ffffffffffffffff"
    expected_queue_name = "chef-index-consumer-#{expected_queue_id}"
    Chef::Config[:amqp_consumer_id] = expected_queue_id
    @amqp_client.stub!(:qos)
    
    @queue = mock("Bunny::Queue")
    @amqp_client.should_receive(:queue).with(expected_queue_name, :durable => true).and_return(@queue)
    @queue.should_receive(:bind).with(@exchange)
    @publisher.queue.should == @queue
  end
  
  it "stops bunny and clears subscriptions" do
    bunny_client  = mock("Bunny::Client")
    queue         = mock("Bunny::Queue", :subscription => true)
    @publisher.instance_variable_set(:@amqp_client, bunny_client)
    @publisher.instance_variable_set(:@queue, queue)
    bunny_client.should_receive(:stop)
    queue.should_receive(:unsubscribe)
    @publisher.stop
  end
  
end
