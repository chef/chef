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
  let(:rest) { double("Chef::REST") }
  let(:query) { Chef::Search::Query.new }

  shared_context "filtered search" do
    let(:query_string) { "search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000" }
    let(:server_url) { "https://api.opscode.com/organizations/opscode/nodes" }
    let(:args) { { filter_key => filter_hash } }
    let(:filter_hash) {
      {
        'env' => [ 'chef_environment' ],
        'ruby_plat' => [ 'languages', 'ruby', 'platform' ]
      }
    }
    let(:response) {
      {
        "rows" => [
          { "url" => "#{server_url}/my-name-is-node",
            "data" => {
              "env" => "elysium",
              "ruby_plat" => "nudibranch"
            }
          },
          { "url" => "#{server_url}/my-name-is-jonas",
            "data" => {
              "env" => "hades",
              "ruby_plat" => "i386-mingw32"
            }
          },
          { "url" => "#{server_url}/my-name-is-flipper",
            "data" => {
              "env" => "elysium",
              "ruby_plat" => "centos"
            }
          },
          { "url" => "#{server_url}/my-name-is-butters",
            "data" => {
              "env" => "moon",
              "ruby_plat" => "solaris2",
            }
          }
        ],
        "start" => 0,
        "total" => 4
      }
    }
  end

  before(:each) do
    Chef::REST.stub(:new).and_return(rest)
    rest.stub(:get_rest).and_return(response)
  end

  describe "search" do
    let(:response) { {
      "rows" => [
        { "name" => "my-name-is-node",
          "chef_environment" => "elysium",
          "platform" => "rhel",
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "nudibranch",
                "version" => "1.9.3",
                "target" => "ming-the-merciless"
              }
            }
          }
        },
        { "name" => "my-name-is-jonas",
          "chef_environment" => "hades",
          "platform" => "rhel",
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "i386-mingw32",
                "version" => "1.9.3",
                "target" => "bilbo"
              }
            }
          }
        },
        { "name" => "my-name-is-flipper",
          "chef_environment" => "elysium",
          "platform" => "rhel",
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "centos",
                "version" => "2.0.0",
                "target" => "uno"
              }
            }
          }
        },
        { "name" => "my-name-is-butters",
          "chef_environment" => "moon",
          "platform" => "rhel",
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "solaris2",
                "version" => "2.1.2",
                "target" => "random"
              }
            }
          }
        },
      ],
      "start" => 0,
      "total" => 4
    } }

    it "should accept a type as the first argument" do
      lambda { query.search("node") }.should_not raise_error
      lambda { query.search(:node) }.should_not raise_error
      lambda { query.search(Hash.new) }.should raise_error(Chef::Exceptions::InvalidSearchQuery, /(Hash)/)
    end

    it "should query for every object of a type by default" do
      rest.should_receive(:get_rest).with("search/node?q=*:*&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000").and_return(response)
      query.search(:node)
    end

    it "should allow a custom query" do
      rest.should_receive(:get_rest).with("search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000").and_return(response)
      query.search(:node, "platform:rhel")
    end

    it "should let you set a sort order" do
      rest.should_receive(:get_rest).with("search/node?q=platform:rhel&sort=id%20desc&start=0&rows=1000").and_return(response)
      query.search(:node, "platform:rhel", "id desc")
    end

    it "should let you set a starting object" do
      rest.should_receive(:get_rest).with("search/node?q=platform:rhel&sort=id%20desc&start=2&rows=1000").and_return(response)
      query.search(:node, "platform:rhel", "id desc", 2)
    end

    it "should let you set how many rows to return" do
      rest.should_receive(:get_rest).with("search/node?q=platform:rhel&sort=id%20desc&start=2&rows=40").and_return(response)
      query.search(:node, "platform:rhel", "id desc", 2, 40)
    end

    it "should throw an exception if you pass to many options" do
      lambda { query.search(:node, "platform:rhel", "id desc", 2, 40, "wrong") }
        .should raise_error(Chef::Exceptions::InvalidSearchQuery, "Too many arguments! (4 for <= 3)")
    end

    it "should return the raw rows, start, and total if no block is passed" do
      rows, start, total = query.search(:node)
      rows.should equal(response["rows"])
      start.should equal(response["start"])
      total.should equal(response["total"])
    end

    it "should call a block for each object in the response" do
      @call_me = double("blocky")
      response["rows"].each { |r| @call_me.should_receive(:do).with(r) }
      query.search(:node) { |r| @call_me.do(r) }
    end

    it "should page through the responses" do
      @call_me = double("blocky")
      response["rows"].each { |r| @call_me.should_receive(:do).with(r) }
      query.search(:node, "*:*", nil, 0, 1) { |r| @call_me.do(r) }
    end

    context "when :filter_result is provided as a result" do
      include_context "filtered search" do
        let(:filter_key) { :filter_result }

        before(:each) do
          rest.should_receive(:post_rest).with(query_string, args[filter_key]).and_return(response)
        end

        it "should return start" do
          start = query.search(:node, "platform:rhel", args)[1]
          start.should == response['start']
        end

        it "should return total" do
          total = query.search(:node, "platform:rhel", args)[2]
          total.should == response['total']
        end

        it "should return rows with the filter applied" do
          results = query.search(:node, "platform:rhel", args)[0]

          results.each_with_index do |result, idx|
            expected = response["rows"][idx]

            result.should have_key("url")
            result["url"].should == expected["url"]

            result.should have_key("data")
            filter_hash.keys.each do |filter_key|
              result["data"].should have_key(filter_key)
              result["data"][filter_key].should == expected["data"][filter_key]
            end
          end
        end

      end
    end
  end

  describe "#partial_search" do
    include_context "filtered search" do
      let(:filter_key) { :keys }

      it "should emit a deprecation warning" do
        # partial_search calls search, so we'll stub search to return empty
        query.stub(:search).and_return( [ [], 0, 0 ] )
        Chef::Log.should_receive(:warn).with("DEPRECATED: The 'partial_search' api is deprecated, please use the search api with 'filter_result'")
        query.partial_search(:node, "platform:rhel", args)
      end

      it "should return an array of filtered hashes" do
        rest.should_receive(:post_rest).with(query_string, args[filter_key]).and_return(response)
        results = query.partial_search(:node, "platform:rhel", args)

        results.each_with_index do |result, idx|
          expected = response["rows"][idx]

          filter_hash.keys.each do |filter_key|
            result.should have_key(filter_key)
            result[filter_key].should == expected["data"][filter_key]
          end
        end
      end
    end
  end
end
