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

require 'spec_helper'
require 'chef/data_bag_item'

describe Chef::DataBagItem do
  before(:each) do
    @data_bag_item = Chef::DataBagItem.new
  end

  describe "initialize" do
    it "should be a Chef::DataBagItem" do
      @data_bag_item.should be_a_kind_of(Chef::DataBagItem)
    end
  end

  describe "data_bag" do
    it "should let you set the data_bag to a string" do
      @data_bag_item.data_bag("clowns").should == "clowns"
    end

    it "should return the current data_bag type" do
      @data_bag_item.data_bag "clowns"
      @data_bag_item.data_bag.should == "clowns"
    end

    it "should not accept spaces" do
      lambda { @data_bag_item.data_bag "clown masters" }.should raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      lambda { @data_bag_item.data_bag Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "raw_data" do
    it "should let you set the raw_data with a hash" do
      lambda { @data_bag_item.raw_data = { "id" => "octahedron" } }.should_not raise_error
    end

    it "should let you set the raw_data from a mash" do
      lambda { @data_bag_item.raw_data = Mash.new({ "id" => "octahedron" }) }.should_not raise_error
    end

    it "should raise an exception if you set the raw data without a key" do
      lambda { @data_bag_item.raw_data = { "monkey" => "pants" } }.should raise_error(ArgumentError)
    end

    it "should raise an exception if you set the raw data to something other than a hash" do
      lambda { @data_bag_item.raw_data = "katie rules" }.should raise_error(ArgumentError)
    end

    it "should accept alphanum/-/_ for the id" do
      lambda { @data_bag_item.raw_data = { "id" => "h1-_" } }.should_not raise_error(ArgumentError)
    end

    it "should raise an exception if the id contains anything but alphanum/-/_" do
      lambda { @data_bag_item.raw_data = { "id" => "!@#" } }.should raise_error(ArgumentError)
    end

    it "should return the raw data" do
      @data_bag_item.raw_data = { "id" => "highway_of_emptiness" }
      @data_bag_item.raw_data.should == { "id" => "highway_of_emptiness" }
    end

    it "should be a Mash by default" do
      @data_bag_item.raw_data.should be_a_kind_of(Mash)
    end
  end

  describe "object_name" do
    before(:each) do
      @data_bag_item.data_bag("dreams")
      @data_bag_item.raw_data = { "id" => "the_beatdown" }
    end

    it "should return an object name based on the bag name and the raw_data id" do
      @data_bag_item.object_name.should == "data_bag_item_dreams_the_beatdown"
    end
  end

  describe "class method object_name" do
    it "should return an object name based based on the bag name and an id" do
      Chef::DataBagItem.object_name("zen", "master").should == "data_bag_item_zen_master"
    end
  end

  describe "when used like a Hash" do
    before(:each) do
      @data_bag_item.raw_data = { "id" => "journey", "trials" => "been through" }
    end

    it "responds to keys" do
      @data_bag_item.keys.should include("id")
      @data_bag_item.keys.should include("trials")
    end

    it "supports element reference with []" do
      @data_bag_item["id"].should == "journey"
    end

    it "implements all the methods of Hash" do
      methods = [:rehash, :to_hash, :[], :fetch, :[]=, :store, :default,
      :default=, :default_proc, :index, :size, :length,
      :empty?, :each_value, :each_key, :each_pair, :each, :keys, :values,
      :values_at, :delete, :delete_if, :reject!, :clear,
      :invert, :update, :replace, :merge!, :merge, :has_key?, :has_value?,
      :key?, :value?]
      methods.each do |m|
        @data_bag_item.should respond_to(m)
      end
    end

  end

  describe "to_hash" do
    before(:each) do 
      @data_bag_item.data_bag("still_lost")
      @data_bag_item.raw_data = { "id" => "whoa", "i_know" => "kung_fu" }
      @to_hash = @data_bag_item.to_hash
    end

    it "should return a hash" do
      @to_hash.should be_a_kind_of(Hash)
    end

    it "should have the raw_data keys as top level keys" do
      @to_hash["id"].should == "whoa"
      @to_hash["i_know"].should == "kung_fu"
    end

    it "should have the chef_type of data_bag_item" do
      @to_hash["chef_type"].should == "data_bag_item"
    end

    it "should have the data_bag set" do
      @to_hash["data_bag"].should == "still_lost"
    end
  end

  describe "when deserializing from JSON" do
    before(:each) do
      @data_bag_item.data_bag('mars_volta')
      @data_bag_item.raw_data = { "id" => "octahedron", "snooze" => { "finally" => :world_will }}
      @deserial = Chef::JSONCompat.from_json(@data_bag_item.to_json)
    end

    it "should deserialize to a Chef::DataBagItem object" do
      @deserial.should be_a_kind_of(Chef::DataBagItem)
    end

    it "should have a matching 'data_bag' value" do
      @deserial.data_bag.should == @data_bag_item.data_bag
    end

    it "should have a matching 'id' key" do
      @deserial["id"].should == "octahedron"
    end

    it "should have a matching 'snooze' key" do
      @deserial["snooze"].should == { "finally" => "world_will" }
    end
  end

  describe "when converting to a string" do
    it "converts to a string in the form data_bag_item[ID]" do
      @data_bag_item['id'] = "heart of darkness"
      @data_bag_item.to_s.should == 'data_bag_item[heart of darkness]'
    end

    it "inspects as data_bag_item[BAG, ID, RAW_DATA]" do
      raw_data = {"id" => "heart_of_darkness", "author" => "Conrad"}
      @data_bag_item.raw_data = raw_data
      @data_bag_item.data_bag("books")

      @data_bag_item.inspect.should == "data_bag_item[\"books\", \"heart_of_darkness\", #{raw_data.inspect}]"
    end
  end

  describe "save" do
    before do
      @rest = mock("Chef::REST")
      Chef::REST.stub!(:new).and_return(@rest)
      @data_bag_item['id'] = "heart of darkness" 
      raw_data = {"id" => "heart_of_darkness", "author" => "Conrad"}
      @data_bag_item.raw_data = raw_data
      @data_bag_item.data_bag("books")
    end
    it "should update the item when it already exists" do
      @rest.should_receive(:put_rest).with("data/books/heart_of_darkness", @data_bag_item)
      @data_bag_item.save
    end

    it "should create if the item is not found" do 
      exception = mock("404 error", :code => "404")
      @rest.should_receive(:put_rest).and_raise(Net::HTTPServerException.new("foo", exception))
      @rest.should_receive(:post_rest).with("data/books", @data_bag_item)
      @data_bag_item.save
    end
    describe "when whyrun mode is enabled" do
      before do
        Chef::Config[:why_run] = true
      end
      after do
        Chef::Config[:why_run] = false
      end
      it "should not save" do
        @rest.should_not_receive(:put_rest)
        @rest.should_not_receive(:post_rest)
        @data_bag_item.data_bag("books")
        @data_bag_item.save
      end
    end

    
  end

  describe "when loading" do
    before do
      @data_bag_item.raw_data = {"id" => "charlie", "shell" => "zsh", "ssh_keys" => %w{key1 key2}}
      @data_bag_item.data_bag("users")
    end

    describe "from an API call" do
      before do
        @http_client = mock("Chef::REST")
        Chef::REST.stub!(:new).and_return(@http_client)
      end

      it "converts raw data to a data bag item" do
        @http_client.should_receive(:get_rest).with("data/users/charlie").and_return(@data_bag_item.to_hash)
        item = Chef::DataBagItem.load(:users, "charlie")
        item.should be_a_kind_of(Chef::DataBagItem)
        item.should == @data_bag_item
      end

      it "does not convert when a DataBagItem is returned from the API call" do
        @http_client.should_receive(:get_rest).with("data/users/charlie").and_return(@data_bag_item)
        item = Chef::DataBagItem.load(:users, "charlie")
        item.should be_a_kind_of(Chef::DataBagItem)
        item.should equal(@data_bag_item)
      end
    end

    describe "in solo mode" do
      before do
        Chef::Config[:solo] = true
      end

      after do
        Chef::Config[:solo] = false
      end

      it "converts the raw data to a data bag item" do
        Chef::DataBag.should_receive(:load).with('users').and_return({'charlie' => @data_bag_item.to_hash})
        item = Chef::DataBagItem.load('users', 'charlie')
        item.should be_a_kind_of(Chef::DataBagItem)
        item.should == @data_bag_item
      end
    end

  end

end
