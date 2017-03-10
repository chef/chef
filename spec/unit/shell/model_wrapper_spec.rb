#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

require "spec_helper"
require "ostruct"

describe Shell::ModelWrapper do
  before do
    @model = OpenStruct.new(:name => "Chef::Node")
    @wrapper = Shell::ModelWrapper.new(@model)
  end

  describe "when created with an explicit model_symbol" do
    before do
      @model = OpenStruct.new(:name => "Chef::ApiClient")
      @wrapper = Shell::ModelWrapper.new(@model, :client)
    end

    it "uses the explicit model symbol" do
      expect(@wrapper.model_symbol).to eq(:client)
    end
  end

  it "determines the model symbol from the class name" do
    expect(@wrapper.model_symbol).to eq(:node)
  end

  describe "when listing objects" do
    before do
      @node_1 = Chef::Node.new
      @node_1.name("sammich")
      @node_2 = Chef::Node.new
      @node_2.name("yummy")
      @server_response = { :node_1 => @node_1, :node_2 => @node_2 }
      @wrapper = Shell::ModelWrapper.new(Chef::Node)
      allow(Chef::Node).to receive(:list).and_return(@server_response)
    end

    it "lists fully inflated objects without the resource IDs" do
      expect(@wrapper.all.size).to eq(2)
      expect(@wrapper.all).to include(@node_1, @node_2)
    end

    it "maps the listed nodes when given a block" do
      expect(@wrapper.all { |n| n.name }.sort.reverse).to eq(%w{yummy sammich})
    end
  end

  describe "when searching for objects" do
    before do
      @node_1 = Chef::Node.new
      @node_1.name("sammich")
      @node_2 = Chef::Node.new
      @node_2.name("yummy")
      @server_response = { :node_1 => @node_1, :node_2 => @node_2 }
      @wrapper = Shell::ModelWrapper.new(Chef::Node)

      # Creating a Chef::Search::Query object tries to read the private key...
      @searcher = double("Chef::Search::Query #{__FILE__}:#{__LINE__}")
      allow(Chef::Search::Query).to receive(:new).and_return(@searcher)
    end

    it "falls back to listing the objects when the 'query' is :all" do
      allow(Chef::Node).to receive(:list).and_return(@server_response)
      expect(@wrapper.find(:all)).to include(@node_1, @node_2)
    end

    it "searches for objects using the given query string" do
      expect(@searcher).to receive(:search).with(:node, "name:app*").and_yield(@node_1).and_yield(@node_2)
      expect(@wrapper.find("name:app*")).to include(@node_1, @node_2)
    end

    it "creates a 'AND'-joined query string from a HASH" do
      # Hash order woes
      expect(@searcher).to receive(:search).with(:node, "name:app* AND name:app*").and_yield(@node_1).and_yield(@node_2)
      expect(@wrapper.find(:name => "app*", "name" => "app*")).to include(@node_1, @node_2)
    end

  end

end
