#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009,2010 Opscode, Inc.
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
require 'chef/search/query'

describe Chef::Search::Query do 
  before(:each) do
    @rest = mock("Chef::REST")
    Chef::REST.stub!(:new).and_return(@rest)
    @query = Chef::Search::Query.new
  end

  describe "search" do
    before(:each) do
      @response = {
        "rows" => [
          { "id" => "for you" },
          { "id" => "hip hop" },
          { "id" => "thought was down by law for you" },
          { "id" => "kept it hard core for you" },
        ],
        "start" => 0,
        "total" => 4
      }
      @rest.stub!(:get_rest).and_return(@response)
    end

    it "should accept a type as the first argument" do
      lambda { @query.search("foo") }.should_not raise_error(ArgumentError)
      lambda { @query.search(:foo) }.should_not raise_error(ArgumentError)
      lambda { @query.search(Hash.new) }.should raise_error(ArgumentError)
    end

    it "should query for every object of a type by default" do
      @rest.should_receive(:get_rest).with("search/foo?q=*:*&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000").and_return(@response)
      @query = Chef::Search::Query.new
      @query.search(:foo)
    end

    it "should allow a custom query" do
      @rest.should_receive(:get_rest).with("search/foo?q=gorilla:dundee&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000").and_return(@response)
      @query = Chef::Search::Query.new
      @query.search(:foo, "gorilla:dundee")
    end

    it "should let you set a sort order" do
      @rest.should_receive(:get_rest).with("search/foo?q=gorilla:dundee&sort=id%20desc&start=0&rows=1000").and_return(@response)
      @query = Chef::Search::Query.new
      @query.search(:foo, "gorilla:dundee", "id desc")
    end

    it "should let you set a starting object" do
      @rest.should_receive(:get_rest).with("search/foo?q=gorilla:dundee&sort=id%20desc&start=2&rows=1000").and_return(@response)
      @query = Chef::Search::Query.new
      @query.search(:foo, "gorilla:dundee", "id desc", 2)
    end

    it "should let you set how many rows to return" do
      @rest.should_receive(:get_rest).with("search/foo?q=gorilla:dundee&sort=id%20desc&start=2&rows=40").and_return(@response)
      @query = Chef::Search::Query.new
      @query.search(:foo, "gorilla:dundee", "id desc", 2, 40)
    end

    it "should return the raw rows, start, and total if no block is passed" do
      rows, start, total = @query.search(:foo)
      rows.should equal(@response["rows"])
      start.should equal(@response["start"])
      total.should equal(@response["total"])
    end

    it "should call a block for each object in the response" do
      @call_me = mock("blocky")
      @response["rows"].each { |r| @call_me.should_receive(:do).with(r) }
      @query.search(:foo) { |r| @call_me.do(r) }
    end

    it "should page through the responses" do
      @call_me = mock("blocky")
      @response["rows"].each { |r| @call_me.should_receive(:do).with(r) }
      @query.search(:foo, "*:*", nil, 0, 1) { |r| @call_me.do(r) }
    end
  end
end
