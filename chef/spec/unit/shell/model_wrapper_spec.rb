#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'ostruct'

describe Shell::ModelWrapper do
  before do
    @model = OpenStruct.new(:name=>"Chef::Node")
    @wrapper = Shell::ModelWrapper.new(@model)
  end

  describe "when created with an explicit model_symbol" do
    before do
      @model = OpenStruct.new(:name=>"Chef::ApiClient")
      @wrapper = Shell::ModelWrapper.new(@model, :client)
    end

    it "uses the explicit model symbol" do
      @wrapper.model_symbol.should == :client
    end
  end

  it "determines the model symbol from the class name" do
    @wrapper.model_symbol.should == :node
  end

  describe "when listing objects" do
    before do
      @node_1 = Chef::Node.new
      @node_1.name("sammich")
      @node_2 = Chef::Node.new
      @node_2.name("yummy")
      @server_response = {:node_1 => @node_1, :node_2 => @node_2}
      @wrapper = Shell::ModelWrapper.new(Chef::Node)
      Chef::Node.stub(:list).and_return(@server_response)
    end

    it "lists fully inflated objects without the resource IDs" do
      @wrapper.all.should have(2).nodes
      @wrapper.all.should include(@node_1, @node_2)
    end

    it "maps the listed nodes when given a block" do
      @wrapper.all {|n| n.name }.sort.reverse.should == %w{yummy sammich}
    end
  end

  describe "when searching for objects" do
    before do
      @node_1 = Chef::Node.new
      @node_1.name("sammich")
      @node_2 = Chef::Node.new
      @node_2.name("yummy")
      @server_response = {:node_1 => @node_1, :node_2 => @node_2}
      @wrapper = Shell::ModelWrapper.new(Chef::Node)

      # Creating a Chef::Search::Query object tries to read the private key...
      @searcher = mock("Chef::Search::Query #{__FILE__}:#{__LINE__}")
      Chef::Search::Query.stub!(:new).and_return(@searcher)
    end

    it "falls back to listing the objects when the 'query' is :all" do
      Chef::Node.stub(:list).and_return(@server_response)
      @wrapper.find(:all).should include(@node_1, @node_2)
    end

    it "searches for objects using the given query string" do
      @searcher.should_receive(:search).with(:node, 'name:app*').and_yield(@node_1).and_yield(@node_2)
      @wrapper.find("name:app*").should include(@node_1, @node_2)
    end

    it "creates a 'AND'-joined query string from a HASH" do
      # Hash order woes
      @searcher.should_receive(:search).with(:node, 'name:app* AND name:app*').and_yield(@node_1).and_yield(@node_2)
      @wrapper.find(:name=>"app*",'name'=>"app*").should include(@node_1, @node_2)
    end

  end


end
