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

describe Chef::CouchDB, "new" do
  before do
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.stub!(:run_request).and_return({"couchdb" => "Welcome", "version" =>"0.9.0"})
    @mock_rest.stub!(:url).and_return("http://localhost:5984")
    Chef::REST.stub!(:new).and_return(@mock_rest)
  end
  
  it "should create a new Chef::REST object from the default url" do
    Chef::Config[:couchdb_url] = "http://monkey"
    Chef::REST.should_receive(:new).with("http://monkey")
    Chef::CouchDB.new
  end

  it "should create a new Chef::REST object from a provided url" do
    Chef::REST.should_receive(:new).with("http://monkeypants")
    Chef::CouchDB.new("http://monkeypants")
  end  
end

describe Chef::CouchDB, "create_db" do
  before(:each) do
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.stub!(:get_rest).and_return([ "chef" ])
    @mock_rest.stub!(:put_rest).and_return(true)
    Chef::REST.stub!(:new).and_return(@mock_rest)
  end
  
  def do_create_db
    couch = Chef::CouchDB.new
    couch.create_db
  end
  
  it "should get a list of current databases" do
    @mock_rest.should_receive(:get_rest).and_return(["chef"])
    do_create_db
  end
  
  it "should create the chef database if it does not exist" do
    @mock_rest.stub!(:get_rest).and_return([])
    @mock_rest.should_receive(:put_rest).with("chef", {}).and_return(true)
    do_create_db
  end
  
  it "should not create the chef database if it does exist" do
    @mock_rest.stub!(:get_rest).and_return(["chef"])
    @mock_rest.should_not_receive(:put_rest)
    do_create_db
  end
  
  it "should return 'chef'" do
    do_create_db.should eql("chef")
  end
end

describe Chef::CouchDB, "create_design_document" do
  before(:each) do
    @mock_rest = mock("Chef::REST", :null_object => true)
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
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @couchdb = Chef::CouchDB.new
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
    @mock_rest.should_receive(:get_rest).with("chef/_design%2Fbob")
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

describe Chef::CouchDB, "store" do
  it "should put the object into couchdb" do
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.should_receive(:put_rest).with("chef/node_bob", {}).and_return(true)
    Chef::REST.stub!(:new).and_return(@mock_rest)
    Chef::CouchDB.new.store("node", "bob", {})
  end
end

describe Chef::CouchDB, "load" do
  it "should load the object from couchdb" do
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.should_receive(:get_rest).with("chef/node_bob").and_return(true)
    Chef::REST.stub!(:new).and_return(@mock_rest)
    Chef::CouchDB.new.load("node", "bob").should eql(true)
  end
end

describe Chef::CouchDB, "delete" do
  before(:each) do
    @mock_current = {
      "version" => 1,
      "_rev" => 1
    }
    @mock_rest = mock("Chef::REST", :null_object => true)
    @mock_rest.stub!(:get_rest).and_return(@mock_current)
    @mock_rest.stub!(:delete_rest).and_return(true)
    Chef::REST.stub!(:new).and_return(@mock_rest)
  end
  
  def do_delete(rev=nil)
    Chef::REST.stub!(:new).and_return(@mock_rest)
    Chef::CouchDB.new.delete("node", "bob", rev)
  end
  
  it "should remove the object from couchdb with a specific revision" do
    @mock_rest.should_receive(:delete_rest).with("chef/node_bob?rev=1")
    do_delete(1)  
  end
  
  it "should remove the object from couchdb based on the couchdb_rev of the current obj" do
    mock_real = mock("Inflated Object")
    mock_real.stub!(:respond_to?).and_return(true)
    mock_real.stub!(:couchdb_rev).and_return(2)
    @mock_rest.should_receive(:get_rest).with("chef/node_bob").and_return(mock_real)
    @mock_rest.should_receive(:delete_rest).with("chef/node_bob?rev=2")
    do_delete
  end
  
  it "should remove the object from couchdb based on the current objects rev" do
    @mock_rest.should_receive(:delete_rest).with("chef/node_bob?rev=1")
    do_delete
  end
end

describe Chef::CouchDB, "list" do
  before(:each) do
    @mock_rest = mock("Chef::REST", :null_object => true, :url => "http://monkeypants")
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @couch = Chef::CouchDB.new("http://monkeypants")
    Chef::Config.stub!(:[]).with(:couchdb_database).and_return("chef")
  end
  
  describe "on couchdb 0.8" do
    before do
      Chef::Config.stub!(:[]).with(:couchdb_version).and_return(0.8)
    end
    
    it "should get the view for all objects if inflate is true" do
      @mock_rest.should_receive(:get_rest).with("chef/_view/node/all").and_return(true)
      @couch.list("node", true)
    end

    it "should get the view for just the object id's if inflate is false" do
      @mock_rest.should_receive(:get_rest).with("chef/_view/node/all_id").and_return(true)
      @couch.list("node", false)
    end
  end

  describe "on couchdb 0.9" do
    before do
      Chef::Config.stub!(:[]).with(:couchdb_version).and_return(0.9)
    end
    
    it "should get the view for all objects if inflate is true" do
      @mock_rest.should_receive(:get_rest).with("chef/_design/node/_view/all").and_return(true)
      @couch.list("node", true)
    end

    it "should get the view for just the object id's if inflate is false" do
      @mock_rest.should_receive(:get_rest).with("chef/_design/node/_view/all_id").and_return(true)
      @couch.list("node", false)
    end
  end
end

describe Chef::CouchDB, "has_key?" do
  before(:each) do
    @mock_rest = mock("Chef::REST", :null_object => true)
    Chef::REST.stub!(:new).and_return(@mock_rest)
  end
  
  it "should return true if the object exists" do
    @mock_rest.should_receive(:get_rest).and_return(true)
    Chef::CouchDB.new.has_key?("node", "bob").should eql(true)
  end
  
  it "should return false if the object does not exist" do
    @mock_rest.should_receive(:get_rest).and_raise(ArgumentError)
    Chef::CouchDB.new.has_key?("node", "bob").should eql(false)
  end
end

describe Chef::CouchDB, "get_view" do
  before do
    @mock_rest = mock("Chef::REST", :null_object => true, :url => "http://monkeypants")
    Chef::REST.stub!(:new).and_return(@mock_rest)
    @couchdb = Chef::CouchDB.new("http://localhost")
    @old_version = Chef::Config[:couchdb_version]
    Chef::Config[:couchdb_version] = 0.9
  end

  after do
    Chef::Config[:couchdb_version] = @old_version
  end

  it "should construct a call to the view for the proper design document" do
    @mock_rest.should_recieve(:get_rest).with("chef/_design/nodes/_view/mastodon")
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
  
  describe "when the couchdb version is unknown" do
    it "should set the couchdb version appropriately" do
      ov = Chef::Config[:couchdb_version]
      Chef::Config[:couchdb_version] = nil      
      @mock_rest.should_receive(:run_request).with(
        :GET, 
        URI.parse("http://monkeypants/"), 
        false, 
        10, 
        false
      ).and_return({ "version" => "0.9" })
      @couchdb.view_uri("nodes", "all")
      Chef::Config[:couchdb_version] = ov
    end
  end
  
  describe "on couchdb 0.8" do
    before do
      Chef::Config.stub!(:[]).with(:couchdb_version).and_return(0.8)
    end
    
    it "should output an appropriately formed view URI" do
      @couchdb.should_receive(:view_uri).with("nodes", "all").and_return("chef/_view/nodes/all")
      @couchdb.view_uri("nodes", "all")
    end
  end

  describe "on couchdb 0.9" do
    before do
      Chef::Config.stub!(:[]).with(:couchdb_version).and_return(0.9)
    end

    it "should output an appropriately formed view URI" do
      @couchdb.should_receive(:view_uri).with("nodes", "all").and_return("chef/_design/nodes/_view/all")
      @couchdb.view_uri("nodes", "all")
    end
  end
end
