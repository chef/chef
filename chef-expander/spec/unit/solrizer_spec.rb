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

require 'stringio'
require 'chef/expander/solrizer'
require 'yajl'
require 'rexml/document'

describe Expander::Solrizer do
  SEP = "__=__"

  describe "when created with invalid JSON" do
    before do
      @log_stream = StringIO.new
      Expander::Solrizer::LOGGER.init(@log_stream)
      @solrizer = Expander::Solrizer.new('{!"action":"delete"}') { :no_op }
    end

    it "logs error info" do
      @log_stream.string.should =~ /invalid JSON/
    end

    it "skips invalid request" do
      @solrizer.action.should == "skip"
    end
  end

  describe "when created with an add request" do
    before do
      @now = Time.now.utc.to_i
      @indexer_payload = {:item => {:foo => {:bar => :baz}},
                          :type => :node,
                          :database => :testdb,
                          :id => "2342",
                          :enqueued_at => @now}

      @update_object = {:action => "add", :payload => @indexer_payload}
      @update_json = Yajl::Encoder.encode(@update_object)
      @solrizer = Expander::Solrizer.new(@update_json) { :no_op }

      @log_stream = StringIO.new
      @solrizer.log.init(@log_stream)
      @expected_fields = %w(X_CHEF_id_CHEF_X X_CHEF_database_CHEF_X X_CHEF_type_CHEF_X)
    end

    it "extracts the indexing-specific payload from the update message" do
      @solrizer.indexer_payload.should == { 'item' => {'foo' => {'bar' => "baz"}},
                                            'type' => 'node',
                                            'database' => 'testdb', 'id' => "2342",
                                            "enqueued_at"=>@now}
    end

    it "extracts the action from the update message" do
      @solrizer.action.should == "add"
    end

    it "extracts the item to update from the update message" do
      @solrizer.chef_object.should == {"foo" => {"bar" => "baz"}}
    end

    it "extracts the database name from the update message" do
      @solrizer.database.should == "testdb"
    end

    it "extracts the object id from the update message" do
      @solrizer.obj_id.should == "2342"
    end

    it "extracts the object type from the update message" do
      @solrizer.obj_type.should == "node"
    end

    it "extracts the time the object was enqueued from the message" do
      @solrizer.enqueued_at.should == @now
    end

    it "is eql to another Solrizer object that has the same object type, id, database, action, and enqueued_at time" do
      eql_solrizer = Expander::Solrizer.new(@update_json)
      @solrizer.should eql eql_solrizer
    end

    it "is not eql to another Solrizer if the enqueued_at time is different" do
      update_hash = @update_object.dup
      update_hash[:payload] = update_hash[:payload].merge({:enqueued_at => (Time.now.utc.to_i + 10000)})
      update_json = Yajl::Encoder.encode(update_hash)
      uneql_solrizer = Expander::Solrizer.new(update_json)
      @solrizer.should_not eql(uneql_solrizer)
    end

    it "is not eql to another Solrizer if the object id is different" do
      update_hash = @update_object.dup
      update_hash[:payload] = update_hash[:payload].merge({:id => 12345})
      update_json = Yajl::Encoder.encode(update_hash)
      uneql_solrizer = Expander::Solrizer.new(update_json)
      @solrizer.should_not eql(uneql_solrizer)
    end

    it "is not eql to another Solrizer if the database is different" do
      update_hash = @update_object.dup
      update_hash[:payload] = update_hash[:payload].merge({:database => "nononono"})
      update_json = Yajl::Encoder.encode(update_hash)
      uneql_solrizer = Expander::Solrizer.new(update_json)
      @solrizer.should_not eql(uneql_solrizer)
    end

    it "is not eql to another Solrizer if the action is different" do
      update_hash = @update_object.dup
      update_hash[:action] = :delete
      update_json = Yajl::Encoder.encode(update_hash)
      uneql_solrizer = Expander::Solrizer.new(update_json)
      @solrizer.should_not eql(uneql_solrizer)
    end

    describe "when flattening to XML" do
      before do
        @expected_object = {"foo"                    => ["bar"],
                            "foo_bar"                => ["baz"],
                            "bar"                    => ["baz"],
                            "X_CHEF_id_CHEF_X"       => ["2342"],
                            "X_CHEF_database_CHEF_X" => ["testdb"],
                            "X_CHEF_type_CHEF_X"     => ["node"]}
        @expected_fields = %w(X_CHEF_id_CHEF_X X_CHEF_database_CHEF_X X_CHEF_type_CHEF_X)
      end

      it "generates the flattened and expanded representation of the object" do
        @solrizer.flattened_object.should == @expected_object
      end

      it "has the expected fields in the document" do
        doc = REXML::Document.new(@solrizer.pointyize_add)
        flds = doc.elements.to_a("add/doc/field").map {|f| f.attributes["name"] }
        @expected_fields.each do |field|
          flds.should include(field)
        end
      end

      it "the content field contains key value pairs delimited with the right separator" do
        doc = REXML::Document.new(@solrizer.pointyize_add)
        doc.elements.each("add/doc/field[@name='content']") do |content|
          raw = content.text
          @expected_object.each do |k, v|
            s = "#{k}#{SEP}#{v.first}"
            raw.index(s).should_not be_nil
          end
        end
      end
    end

    describe "when flattening data to XML that needs XML escaping" do
      before do
        @indexer_payload[:type] = :role
        @indexer_payload[:item] = { "a&w" => "<rootbeer/>" }
        update_object = {:action => "add", :payload => @indexer_payload}
        update_json = Yajl::Encoder.encode(update_object)
        @solrizer = Expander::Solrizer.new(update_json) { :no_op }
        @solrizer.log.init(@log_stream)
      end

      it "the content field contains escaped keys and values" do
        raw = @solrizer.pointyize_add
        raw.should match("a&amp;w#{SEP}&lt;rootbeer/&gt;")
      end
    end

    describe "when flattening data bag XML" do
      before do
        @indexer_payload[:type] = :data_bag_item
        @indexer_payload[:item] = {:k1 => "v1", "data_bag" => "stuff"}
        update_object = {:action => "add", :payload => @indexer_payload}
        update_json = Yajl::Encoder.encode(update_object)
        @solrizer = Expander::Solrizer.new(update_json) { :no_op }
        @solrizer.log.init(@log_stream)
        @expected_fields << "data_bag"
      end

      it "contains a data_bag field with the right name" do
        doc = REXML::Document.new(@solrizer.pointyize_add)
        flds = doc.elements.to_a("add/doc/field[@name='data_bag']")
        flds.size.should == 1
        flds.first.text.should == "stuff"
      end

      it "has the expected fields in the document" do
        doc = REXML::Document.new(@solrizer.pointyize_add)
        flds = doc.elements.to_a("add/doc/field").map {|f| f.attributes["name"] }
        @expected_fields.each do |field|
          flds.should include(field)
        end
      end
      describe "and data bag name needs escaping" do
        before do
          @indexer_payload[:item] = {:k1 => "v1", "data_bag" => "a&w>"}
          update_object = {:action => "add", :payload => @indexer_payload}
          update_json = Yajl::Encoder.encode(update_object)
          @solrizer = Expander::Solrizer.new(update_json) { :no_op }
          @solrizer.log.init(@log_stream)
        end

        it "contains a data_bag field with an escaped name" do
          raw = @solrizer.pointyize_add
          raw.should match("data_bag#{SEP}a&amp;w&gt;")
        end
      end
    end

    describe "when no HTTP request is in progress" do

      it "does not report that an HTTP request is in progress" do
        Expander::Solrizer.http_requests_active?.should be_false
      end

    end

    describe "when an HTTP request is in progress" do
      before do
        Expander::Solrizer.clear_http_requests
        @solrizer.http_request_started
      end

      it "registers the in-progress HTTP request" do
        Expander::Solrizer.http_requests_active?.should be_true
      end

      it "removes itself from the list of active http requests when the request completes" do
        @solrizer.completed
        Expander::Solrizer.http_requests_active?.should be_false
      end

    end


  end

  describe "when created with a delete request" do
    before do
      @indexer_payload = {:id => "2342"}
      @update_object = {:action => "add", :payload => @indexer_payload}
      @update_json = Yajl::Encoder.encode(@update_object)
      @solrizer = Expander::Solrizer.new(@update_json)
    end

    it "extracts the indexer payload" do
      @solrizer.indexer_payload.should == {"id" => "2342"}
    end

    it "extracts the object id" do
      @solrizer.obj_id.should == "2342"
    end

    it "converts the delete request to XML" do
      expected = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><id>2342</id></delete>\n"
      @solrizer.pointyize_delete.should == expected
    end

  end

  describe "solr_url" do
    before do
      @indexer_payload = {:id => "2342"}
      @update_object = {:action => "add", :payload => @indexer_payload}
      @update_json = Yajl::Encoder.encode(@update_object)
      @solrizer = Expander::Solrizer.new(@update_json)
    end

    it "appends /update to the default solr_url" do
      @solrizer.solr_url.should == "http://localhost:8983/solr/update"
    end

    it "appends /update to a configured solr_url" do
      Expander.config.solr_url = "https://vhost/abcdef/solr/collection"
      @solrizer.solr_url.should == "https://vhost/abcdef/solr/collection/update"
    end
  end
end
