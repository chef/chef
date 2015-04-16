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
    let(:query_string) { "search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=0" }
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
    let(:response_rows) {
      [
        { "env" => "elysium", "ruby_plat" => "nudibranch" },
        { "env" => "hades", "ruby_plat" => "i386-mingw32"},
        { "env" => "elysium", "ruby_plat" => "centos"},
        { "env" => "moon", "ruby_plat" => "solaris2"}
      ]
    }
  end

  before(:each) do
    allow(Chef::REST).to receive(:new).and_return(rest)
    allow(rest).to receive(:get_rest).and_return(response)
  end

  describe "search" do
    let(:query_string) { "search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=0" }
    let(:query_string_continue) { "search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=4" }

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

    let(:big_response) {
      r = response.dup
      r["total"] = 8
      r
    }

    let(:big_response_end) {
      r = response.dup
      r["start"] = 4
      r["total"] = 8
      r
    }

    it "accepts a type as the first argument" do
      expect { query.search("node") }.not_to raise_error
      expect { query.search(:node) }.not_to raise_error
      expect { query.search(Hash.new) }.to raise_error(Chef::Exceptions::InvalidSearchQuery, /(Hash)/)
    end

    it "queries for every object of a type by default" do
      expect(rest).to receive(:get_rest).with("search/node?q=*:*&sort=X_CHEF_id_CHEF_X%20asc&start=0").and_return(response)
      query.search(:node)
    end

    it "allows a custom query" do
      expect(rest).to receive(:get_rest).with("search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=0").and_return(response)
      query.search(:node, "platform:rhel")
    end

    it "lets you set a sort order" do
      expect(rest).to receive(:get_rest).with("search/node?q=platform:rhel&sort=id%20desc&start=0").and_return(response)
      query.search(:node, "platform:rhel", sort: "id desc")
    end

    it "lets you set a starting object" do
      expect(rest).to receive(:get_rest).with("search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=2").and_return(response)
      query.search(:node, "platform:rhel", start: 2)
    end

    it "lets you set how many rows to return" do
      expect(rest).to receive(:get_rest).with("search/node?q=platform:rhel&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=40").and_return(response)
      query.search(:node, "platform:rhel", rows: 40)
    end

    it "throws an exception if you pass an incorrect option" do
      expect { query.search(:node, "platform:rhel", total: 10) }
        .to raise_error(ArgumentError, /unknown keyword: total/)
    end

    it "returns the raw rows, start, and total if no block is passed" do
      rows, start, total = query.search(:node)
      expect(rows).to equal(response["rows"])
      expect(start).to equal(response["start"])
      expect(total).to equal(response["total"])
    end

    it "calls a block for each object in the response" do
      @call_me = double("blocky")
      response["rows"].each { |r| expect(@call_me).to receive(:do).with(r) }
      query.search(:node) { |r| @call_me.do(r) }
    end

    it "pages through the responses" do
      @call_me = double("blocky")
      response["rows"].each { |r| expect(@call_me).to receive(:do).with(r) }
      query.search(:node, "*:*", sort: nil, start: 0, rows: 1) { |r| @call_me.do(r) }
    end

    it "sends multiple API requests when the server indicates there is more data" do
      expect(rest).to receive(:get_rest).with(query_string).and_return(big_response)
      expect(rest).to receive(:get_rest).with(query_string_continue).and_return(big_response_end)
      query.search(:node, "platform:rhel") do |r|
        nil
      end
    end

    context "when :filter_result is provided as a result" do
      include_context "filtered search" do
        let(:filter_key) { :filter_result }

        before(:each) do
          expect(rest).to receive(:post_rest).with(query_string, args[filter_key]).and_return(response)
        end

        it "returns start" do
          start = query.search(:node, "platform:rhel", args)[1]
          expect(start).to eq(response['start'])
        end

        it "returns total" do
          total = query.search(:node, "platform:rhel", args)[2]
          expect(total).to eq(response['total'])
        end

        it "returns rows with the filter applied" do
          filtered_rows = query.search(:node, "platform:rhel", args)[0]
          expect(filtered_rows).to match_array(response_rows)
        end

      end
    end
  end

  describe "#partial_search" do
    include_context "filtered search" do
      let(:filter_key) { :keys }

      it "emits a deprecation warning" do
        # partial_search calls search, so we'll stub search to return empty
        allow(query).to receive(:search).and_return( [ [], 0, 0 ] )
        expect(Chef::Log).to receive(:warn).with(/DEPRECATED: The 'partial_search' API is deprecated/)
        query.partial_search(:node, "platform:rhel", args)
      end

      it "returns an array of filtered hashes" do
        expect(rest).to receive(:post_rest).with(query_string, args[filter_key]).and_return(response)
        results = query.partial_search(:node, "platform:rhel", args)
        expect(results[0]).to match_array(response_rows)
      end
    end
  end
end
