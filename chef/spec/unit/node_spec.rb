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

describe Chef::Node do
  before(:each) do
    Chef::Config.node_path(File.join(File.dirname(__FILE__), "..", "data", "nodes"))
    @node = Chef::Node.new()
  end
 
  describe "new method" do
    it "should create a new Chef::Node" do
       @node.should be_a_kind_of(Chef::Node)
    end
  end

  describe "run_state" do
    it "should have a template_cache hash" do
      @node.run_state[:template_cache].should be_a_kind_of(Hash)
    end
    
    it "should have a seen_recipes hash" do
      @node.run_state[:seen_recipes].should be_a_kind_of(Hash)
    end
  end

  describe "name" do
    it "should allow you to set a name with name(something)" do
      lambda { @node.name("latte") }.should_not raise_error
    end
    
    it "should return the name with name()" do
      @node.name("latte")
      @node.name.should eql("latte")
    end
    
    it "should always have a string for name" do
      lambda { @node.name(Hash.new) }.should raise_error(ArgumentError)
    end
  end

  describe "attributes" do
    it "should have attributes" do
      @node.attribute.should be_a_kind_of(Hash)
    end
    
    it "should allow attributes to be accessed by name or symbol directly on node[]" do
      @node.attribute["locust"] = "something"
      @node[:locust].should eql("something")
      @node["locust"].should eql("something")
    end
    
    it "should return nil if it cannot find an attribute with node[]" do
      @node["secret"].should eql(nil)
    end
    
    it "should allow you to set an attribute via node[]=" do
      @node["secret"] = "shush"
      @node["secret"].should eql("shush")
    end
    
    it "should allow you to query whether an attribute exists with attribute?" do
      @node.attribute["locust"] = "something"
      @node.attribute?("locust").should eql(true)
      @node.attribute?("no dice").should eql(false)
    end

    it "should allow you to set an attribute via method_missing" do
      @node.sunshine "is bright"
      @node.attribute[:sunshine].should eql("is bright")
    end
    
    it "should allow you get get an attribute via method_missing" do
      @node.sunshine "is bright"
      @node.sunshine.should eql("is bright")
    end
    
    it "should raise an ArgumentError if you ask for an attribute that doesn't exist via method_missing" do
      lambda { @node.sunshine }.should raise_error(ArgumentError)
    end

    it "should allow you to iterate over attributes with each_attribute" do
      @node.sunshine "is bright"
      @node.canada "is a nice place"
      seen_attributes = Hash.new
      @node.each_attribute do |a,v|
        seen_attributes[a] = v
      end
      seen_attributes.should have_key("sunshine")
      seen_attributes.should have_key("canada")
      seen_attributes["sunshine"].should == "is bright"
      seen_attributes["canada"].should == "is a nice place"
    end
  end

  describe "recipes" do
    it "should have a RunList of recipes that should be applied" do
      @node.recipes.should be_a_kind_of(Chef::RunList)
    end
    
    it "should allow you to query whether or not it has a recipe applied with recipe?" do
      @node.recipes << "sunrise"
      @node.recipe?("sunrise").should eql(true)
      @node.recipe?("not at home").should eql(false)
    end

    it "should allow you to query whether or not a recipe has been applied, even if it was included" do
      @node.run_state[:seen_recipes]["snakes"] = true
      @node.recipe?("snakes").should eql(true)
    end

    it "should return false if a recipe has not been seen" do
      @node.recipe?("snakes").should eql(false)
    end
    
    it "should allow you to set recipes with arguments" do
      @node.recipes "one", "two"
      @node.recipe?("one").should eql(true)
      @node.recipe?("two").should eql(true)
    end
  end

  describe "roles" do
    it "should allow you to query whether or not it has a recipe applied with role?" do
      @node.run_list << "role[sunrise]"
      @node.role?("sunrise").should eql(true)
      @node.role?("not at home").should eql(false)
    end

    it "should allow you to set roles with arguments" do
      @node.run_list << "role[one]"
      @node.run_list << "role[two]"
      @node.role?("one").should eql(true)
      @node.role?("two").should eql(true)
    end
  end

  describe "run_list" do
    it "should have a Chef::RunList of recipes and roles that should be applied" do
      @node.run_list.should be_a_kind_of(Chef::RunList)
    end

    it "should allow you to query the run list with arguments" do
      @node.run_list "recipe[baz]"
      @node.run_list?("recipe[baz]").should eql(true)
    end

    it "should allow you to set the run list with arguments" do
      @node.run_list "recipe[baz]", "role[foo]"
      @node.run_list?("recipe[baz]").should eql(true)
      @node.run_list?("role[foo]").should eql(true)
    end
  end

  describe "from file" do
    it "should load a node from a ruby file" do
      @node.from_file(File.join(File.dirname(__FILE__), "..", "data", "nodes", "test.rb"))
      @node.name.should eql("test.example.com short")
      @node.sunshine.should eql("in")
      @node.something.should eql("else")
      @node.recipes.should == ["operations-master", "operations-monitoring"]
    end
    
    it "should raise an exception if the file cannot be found or read" do
      lambda { @node.from_file("/tmp/monkeydiving") }.should raise_error(IOError)
    end
  end

  describe "find_file" do
    it "should load a node from a file by fqdn" do
      @node.find_file("test.example.com")
      @node.name.should == "test.example.com"
    end
    
    it "should load a node from a file by hostname" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.example.com.rb")).and_return(false)
      @node.find_file("test.example.com")
      @node.name.should == "test.example.com short"
    end
    
    it "should load a node from the default file" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.example.com.rb")).and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.rb")).and_return(false)
      @node.find_file("test.example.com")
      @node.name.should == "test.example.com default"
    end
    
    it "should raise an ArgumentError if it cannot find any node file at all" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.example.com.rb")).and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.rb")).and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "default.rb")).and_return(false)
      lambda { @node.find_file("test.example.com") }.should raise_error(ArgumentError)
    end
  end

  describe "json" do
    it "should serialize itself as json" do
      @node.find_file("test.example.com")
      json = @node.to_json()
      json.should =~ /json_class/
      json.should =~ /name/
      json.should =~ /attributes/
      json.should =~ /run_list/
    end
    
    it "should deserialize itself from json" do
      @node.find_file("test.example.com")
      json = @node.to_json
      serialized_node = JSON.parse(json)
      serialized_node.should be_a_kind_of(Chef::Node)
      serialized_node.name.should eql(@node.name)
      @node.each_attribute do |k,v|
        serialized_node[k].should eql(v)
      end
      serialized_node.run_list.should == @node.run_list
    end
  end

  describe "to_index" do
    before(:each) do
      @node.foo("bar")
    end
    
    it "should return a hash with :index attributes" do
      @node.name("airplane")
      @node.to_index.should == { "foo" => "bar", "index_name" => "node", "id" => "node_airplane", "name" => "airplane" }
    end
  end

  describe "to_s" do
    it "should turn into a string like node[name]" do
      @node.name("airplane")
      @node.to_s.should eql("node[airplane]")
    end
  end

  describe "couchdb" do
    before(:each) do
      @mock_couch = mock("Chef::CouchDB")
    end

    describe "list" do  
      before(:each) do
        @mock_couch.stub!(:list).and_return(
          { "rows" => [ { "value" => "a", "key" => "avenue" } ] }
        )
        Chef::CouchDB.stub!(:new).and_return(@mock_couch) 
      end

      it "should retrieve a list of nodes from CouchDB" do
        Chef::Node.list.should eql(["avenue"])
      end

      it "should return just the ids if inflate is false" do
        Chef::Node.list(false).should eql(["avenue"])
      end

      it "should return the full objects if inflate is true" do
        Chef::Node.list(true).should eql(["a"])
      end
    end

    describe "load" do
      it "should load a node from couchdb by name" do
        @mock_couch.should_receive(:load).with("node", "coffee").and_return(true)
        Chef::CouchDB.stub!(:new).and_return(@mock_couch)
        Chef::Node.load("coffee")
      end
    end

    describe "destroy" do
      it "should delete this node from couchdb" do
        @mock_couch.should_receive(:delete).with("node", "bob", 1).and_return(true)
        Chef::CouchDB.stub!(:new).and_return(@mock_couch)
        node = Chef::Node.new
        node.name "bob"
        node.couchdb_rev = 1
        Chef::Queue.should_receive(:send_msg).with(:queue, :remove, node)
        node.destroy
      end
    end

    describe "save" do
      before(:each) do
        @mock_couch.stub!(:store).and_return({ "rev" => 33 })
        Chef::CouchDB.stub!(:new).and_return(@mock_couch)
        Chef::Queue.stub!(:send_msg).and_return(true)
        @node = Chef::Node.new
        @node.name "bob"
        @node.couchdb_rev = 1
      end

      it "should save the node to couchdb" do
        Chef::Queue.should_receive(:send_msg).with(:queue, :index, @node)
        @mock_couch.should_receive(:store).with("node", "bob", @node).and_return({ "rev" => 33 })
        @node.save
      end

      it "should store the new couchdb_rev" do
        @node.save
        @node.couchdb_rev.should eql(33)
      end
    end

    describe "create_design_document" do
      it "should create our design document" do
        @mock_couch.should_receive(:create_design_document).with("nodes", Chef::Node::DESIGN_DOCUMENT)
        Chef::CouchDB.stub!(:new).and_return(@mock_couch)
        Chef::Node.create_design_document
      end
    end

  end

end



