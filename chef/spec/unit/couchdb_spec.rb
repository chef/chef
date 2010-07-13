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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::CouchDB do
  before(:each) do
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.stub!(:run_request).and_return({"couchdb" => "Welcome", "version" =>"0.9.0"})
    @mock_rest.stub!(:url).and_return("http://localhost:5984")
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @couchdb = Chef::CouchDB.new
  end

  describe "new" do
    it "should create a new Chef::REST object from the default url" do
      old_url = Chef::Config[:couchdb_url]
      Chef::Config[:couchdb_url] = "http://monkey"
      Chef::REST.should_receive(:new).with("http://monkey", nil, nil)
      Chef::CouchDB.new
      Chef::Config[:couchdb_url] = old_url
    end

    it "should create a new Chef::REST object from a provided url" do
      Chef::REST.should_receive(:new).with("http://monkeypants", nil, nil)
      Chef::CouchDB.new("http://monkeypants")
    end 
  end

  describe "create_db" do
    before(:each) do
      @couchdb.stub!(:create_design_document).and_return(true)
    end
    
    it "should get a list of current databases" do
      @mock_rest.should_receive(:get_rest).and_return(["chef"])
      @couchdb.create_db
    end
    
    it "should create the chef database if it does not exist" do
      @mock_rest.stub!(:get_rest).and_return([])
      @mock_rest.should_receive(:put_rest).with("chef", {}).and_return(true)
      @couchdb.create_db
    end
    
    it "should not create the chef database if it does exist" do
      @mock_rest.stub!(:get_rest).and_return(["chef"])
      @mock_rest.should_not_receive(:put_rest)
      @couchdb.create_db
    end
    
    it "should return 'chef'" do
      @couchdb.create_db.should eql("chef")
    end
  end

  describe "create_design_document" do
    before(:each) do
      @mock_design = {
        "version" => 1,
        "_rev" => 1
      }
      @mock_data = {
        "version" => 1,
        "language" => "javascript",
        "views" => {
          "all" => {
            "map" => <<-EOJS
            function(doc) { 
              if (doc.chef_type == "node") {
                emit(doc.name, doc);
              }
            }
            EOJS
          },
        }
      }
      @mock_rest.stub!(:get_rest).and_return(@mock_design)
      @mock_rest.stub!(:put_rest).and_return(true)
      @couchdb.stub!(:create_db).and_return(true)
    end
    
    def do_create_design_document
      @couchdb.create_design_document("bob", @mock_data)
    end
    
    it "should create the database if it does not exist" do
      @couchdb.should_receive(:create_db).and_return(true)
      do_create_design_document
    end
    
    it "should fetch the existing design document" do
      @mock_rest.should_receive(:get_rest).with("chef/_design/bob")
      do_create_design_document
    end
    
    it "should populate the _rev in the new design if the versions dont match" do
      @mock_data["version"] = 2
      do_create_design_document
      @mock_data["_rev"].should eql(1)
    end
    
    it "should create the view if it requires updating" do
      @mock_data["version"] = 2
      @mock_rest.should_receive(:put_rest).with("chef/_design%2Fbob", @mock_data)
      do_create_design_document
    end
    
    it "should not create the view if it does not require updating" do
      @mock_data["version"] = 1
      @mock_rest.should_not_receive(:put_rest)
      do_create_design_document
    end
  end

  describe "store" do
    before(:each) do 
      @mock_results = {
        "rows" => [
          "id" => 'a0934635-e111-45d9-8223-cb58e1c9434c'
        ]
      }
      @couchdb.stub!(:get_view).with("id_map", "name_to_id", :key => [ "node", "bob" ]).and_return(@mock_results)
    end

    it "should put the object into couchdb with a pre-existing GUID" do
      item_to_store = {}
      item_to_store.should_receive(:add_to_index)
      @mock_rest.should_receive(:put_rest).with("chef/#{@mock_results["rows"][0]["id"]}", item_to_store).and_return(true)
      @couchdb.store("node", "bob", item_to_store)
    end

    it "should put the object into couchdb with a new GUID" do
      @mock_results = { "rows" => [] }
      item_to_store = {}
      item_to_store.should_receive(:add_to_index).with(:database => "chef", :id => "aaaaaaaa-xxxx-xxxx-xxxx-xxxxxxxxxxx", :type => "node")
      @couchdb.stub!(:get_view).with("id_map", "name_to_id", :key => [ "node", "bob" ]).and_return(@mock_results)
      UUIDTools::UUID.stub!(:random_create).and_return("aaaaaaaa-xxxx-xxxx-xxxx-xxxxxxxxxxx")
      @mock_rest.should_receive(:put_rest).with("chef/aaaaaaaa-xxxx-xxxx-xxxx-xxxxxxxxxxx", item_to_store).and_return(true)
      @couchdb.store("node", "bob", item_to_store)
    end

  end

  describe "load" do
    before(:each) do 
      @mock_node = Chef::Node.new()
      @mock_node.name("bob")
      @couchdb.stub!(:find_by_name).with("node", "bob").and_return(@mock_node)
    end

    it "should load the object from couchdb" do
      @couchdb.load("node", "bob").should eql(@mock_node)
    end
  end

  describe "delete" do
    before(:each) do
      @mock_current = {
        "version" => 1,
        "_rev" => 1
      }
      @mock_rest.stub!(:get_rest).and_return(@mock_current)
      @mock_rest.stub!(:delete_rest).and_return(true)
      @node = Chef::Node.new()
      @node.name("bob")
      @node.couchdb_rev = 15
      @couchdb.stub!(:find_by_name).with("node", "bob", true).and_return([ @node, "ax" ])
    end
    
    def do_delete(rev=nil)
      @couchdb.delete("node", "bob", rev)
    end
    
    it "should remove the object from couchdb with a specific revision" do
      @node.should_receive(:delete_from_index)
      @mock_rest.should_receive(:delete_rest).with("chef/ax?rev=1")
      do_delete(1)  
    end
    
    it "should remove the object from couchdb based on the couchdb_rev of the current obj" do
      @node.should_receive(:delete_from_index)
      @mock_rest.should_receive(:delete_rest).with("chef/ax?rev=15")
      do_delete
    end
  end

  describe "list" do
    before(:each) do
      Chef::Config.stub!(:[]).with(:couchdb_database).and_return("chef")
      @mock_response = mock("Chef::CouchDB::Response", :null_object => true)
    end
    
    describe "on couchdb 0.9+" do
      before do
        Chef::Config.stub!(:[]).with(:couchdb_version).and_return(0.9)
      end
      
      it "should get the view for all objects if inflate is true" do
        @mock_rest.should_receive(:get_rest).with("chef/_design/node/_view/all").and_return(@mock_response)
        @couchdb.list("node", true)
      end

      it "should get the view for just the object id's if inflate is false" do
        @mock_rest.should_receive(:get_rest).with("chef/_design/node/_view/all_id").and_return(@mock_response)
        @couchdb.list("node", false)
      end
    end
  end

  describe "has_key?" do
    it "should return true if the object exists" do
      @couchdb.stub!(:find_by_name).with("node", "bob").and_return(true)
      @couchdb.has_key?("node", "bob").should eql(true)
    end
    
    it "should return false if the object does not exist" do
      @couchdb.stub!(:find_by_name).and_raise(Chef::Exceptions::CouchDBNotFound)
      @couchdb.has_key?("node", "bob").should eql(false)
    end
  end

end




describe Chef::CouchDB, "get_view" do
  before do
    @mock_rest = mock("Chef::REST", :null_object => true, :url => "http://monkeypants")
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @couchdb = Chef::CouchDB.new("http://localhost")
  end

  it "should construct a call to the view for the proper design document" do
    @mock_rest.should_receive(:get_rest).with("chef/_design/nodes/_view/mastodon")
    @couchdb.get_view("nodes", "mastodon")
  end

  it "should allow arguments to the view" do
    @mock_rest.should_receive(:get_rest).with("chef/_design/nodes/_view/mastodon?startkey=%22dont%20stay%22")
    @couchdb.get_view("nodes", "mastodon", :startkey => "dont stay")
  end

end

describe Chef::CouchDB, "view_uri" do
  before do
    @mock_rest = mock("Chef::REST", :null_object => true, :url => "http://monkeypants")
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @couchdb = Chef::CouchDB.new("http://localhost")    
  end

  it "should output an appropriately formed view URI" do
    @couchdb.should_receive(:view_uri).with("nodes", "all").and_return("chef/_design/nodes/_view/all")
    @couchdb.view_uri("nodes", "all")
  end
end
