# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010, 2011 Opscode, inc.
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

require File.expand_path("../../spec_helper", __FILE__)

require 'chef/solr_query'
require 'net/http'

#require 'rspec/mocks'

describe Chef::SolrQuery do
  before do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://example.com:8983"

    @http_response = mock(
      "Net::HTTP::Response",
      :kind_of? => Net::HTTPSuccess,
      :body => "{ :some => :hash }"
    )
    @http_request = mock(
      "Net::HTTP::Request",
      :body= => true
    )
    @http = mock("Net::HTTP", :request => @http_response)
    Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
    Net::HTTP::Post.stub!(:new).and_return(@http_request)
    Net::HTTP::Get.stub!(:new).and_return(@http_request)
    @doc = { "foo" => "bar" }
  end

  before(:each) do
    @solr = Chef::SolrQuery.new
  end

  it "sets filter query params" do
    @solr.filter_by(:database => 'chef')
    @solr.filter_query.should == "+X_CHEF_database_CHEF_X:chef"
  end

  it "filters by type when querying for a builtin type" do
    @solr.filter_by_type("node")
    @solr.filter_query.should == "+X_CHEF_type_CHEF_X:node"
  end

  it "filters by type for data bag items" do
    @solr.filter_by_type("users")
    @solr.filter_query.should == '+X_CHEF_type_CHEF_X:data_bag_item +data_bag:users'
  end

  it "stores the main query" do
    @solr.query = "role:prod AND tags:chef-server"
    @solr.query.should == "role:prod AND tags:chef-server"
  end

  describe "when generating query params for select" do
    before(:each) do
      @solr = Chef::SolrQuery.from_params(:type => 'node', :q => "hostname:latte")
      @params = @solr.to_hash
    end

    it "includes the query as q" do
      @params[:q].should == "content:hostname__=__latte"
    end

    it "sets the response format to json" do
      @params[:wt].should == "json"
    end

    it "uses indent=off to get a compact response" do
      @params[:indent].should == "off"
    end

    it "includes the filter query to restrict the result set" do
      @params[:fq].should == @solr.filter_query
    end

    it "defaults to returning 1000 rows" do
      @params[:rows].should == 1000
    end

    it "returns the number of rows requested" do
      @solr.params[:rows] = 500
      @solr.to_hash[:rows].should == 500
    end

    it "offsets the row selection if requested" do
      @solr.params[:start] = 500
      @solr.to_hash[:start].should == 500
    end

  end

  describe "when querying solr" do
    before do
      @couchdb = mock("CouchDB Test Double", :couchdb_database => "chunky_bacon")
      @couchdb.stub!(:kind_of?).with(Chef::CouchDB).and_return(true) #ugh.
      @solr = Chef::SolrQuery.from_params({:type => 'node', :q => "hostname:latte", :start => 10, :rows => 5}, @couchdb)
      @docs = [1,2,3,4,5].map { |doc_id| {'X_CHEF_id_CHEF_X' => doc_id} }
      @solr_response = {"response" => {"docs" => @docs, "start" => 10, "results" => 123}}
      Chef::SolrQuery::SolrHTTPRequest.should_receive(:select).with(@solr.to_hash).and_return(@solr_response)
    end

    it "it collects the document ids from the response" do
      @solr.object_ids.should == [1,2,3,4,5]
    end

    it "does a bulk get of the objects from CouchDB" do
      @couchdb.should_receive(:bulk_get).with([1,2,3,4,5]).and_return(%w{obj1 obj2 obj3 obj4 obj5})
      @solr.objects.should == %w{obj1 obj2 obj3 obj4 obj5}
    end

  end

  describe "when forcing a Solr commit" do
    it "sends valid commit xml to solr" do
      Chef::SolrQuery::SolrHTTPRequest.should_receive(:update).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<commit/>\n")
      @solr.commit
    end
  end

  describe "when deleting a database from Solr" do
    it "sends a valid delete query to solr and forces a commit" do
      Chef::SolrQuery::SolrHTTPRequest.should_receive(:update).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><query>X_CHEF_database_CHEF_X:chef</query></delete>\n")
      @solr.should_receive(:commit)
      @solr.delete_database("chef")
    end
  end

  describe "rebuilding the index" do
    before do
      Chef::Config[:couchdb_database] = "chunky_bacon"
    end

    it "deletes the index and commits" do
      @solr.should_receive(:delete_database).with("chunky_bacon")
      @solr.stub!(:reindex_all)
      Chef::DataBag.stub!(:cdb_list).and_return([])
      @solr.rebuild_index
    end

    it "reindexes Chef::ApiClient, Chef::Node, and Chef::Role objects, reporting the results as a hash" do
      @solr.should_receive(:delete_database).with("chunky_bacon")
      @solr.should_receive(:reindex_all).with(Chef::ApiClient).and_return(true)
      @solr.should_receive(:reindex_all).with(Chef::Environment).and_return(true)
      @solr.should_receive(:reindex_all).with(Chef::Node).and_return(true)
      @solr.should_receive(:reindex_all).with(Chef::Role).and_return(true)
      Chef::DataBag.stub!(:cdb_list).and_return([])

      result = @solr.rebuild_index
      result["Chef::ApiClient"].should == "success"
      result["Chef::Node"].should == "success"
      result["Chef::Role"].should == "success"
    end

    it "does not reindex Chef::OpenIDRegistration or Chef::WebUIUser objects" do
      # hi there. the reason we're specifying this behavior is because these objects
      # are not properly indexed in the first place and trying to reindex them
      # tickles a bug in our CamelCase to snake_case code. See CHEF-1009.
      @solr.should_receive(:delete_database).with("chunky_bacon")
      @solr.stub!(:reindex_all).with(Chef::ApiClient)
      @solr.stub!(:reindex_all).with(Chef::Node)
      @solr.stub!(:reindex_all).with(Chef::Role)
      @solr.should_not_receive(:reindex_all).with(Chef::OpenIDRegistration)
      @solr.should_not_receive(:reindex_all).with(Chef::WebUIUser)
      Chef::DataBag.stub!(:cdb_list).and_return([])

      @solr.rebuild_index
    end

    it "reindexes databags" do
      one_data_item = Chef::DataBagItem.new
      one_data_item.raw_data = {"maybe"=>"snakes actually are evil", "id" => "just_sayin"}
      two_data_item = Chef::DataBagItem.new
      two_data_item.raw_data = {"tone_depth"=>"rumble_fish", "id" => "eff_yes"}
      data_bag = Chef::DataBag.new
      data_bag.stub!(:list).and_return([one_data_item, two_data_item])

      @solr.should_receive(:delete_database).with("chunky_bacon")
      @solr.stub!(:reindex_all)
      Chef::DataBag.stub!(:cdb_list).and_return([data_bag])

      data_bag.should_receive(:add_to_index)
      one_data_item.should_receive(:add_to_index)
      two_data_item.should_receive(:add_to_index)

      @solr.rebuild_index["Chef::DataBag"].should == "success"
    end
  end
end
