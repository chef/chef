#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2009-2017, Chef Software Inc.
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
require "chef/search/query"

describe Chef::Search::Query do
  let(:rest) { double("Chef::ServerAPI") }
  let(:query) { Chef::Search::Query.new }

  shared_context "filtered search" do
    let(:query_string) { "search/node?q=platform:rhel&start=0" }
    let(:server_url) { "https://api.opscode.com/organizations/opscode/nodes" }
    let(:args) { { filter_key => filter_hash } }
    let(:filter_hash) do
      {
        "env" => [ "chef_environment" ],
        "ruby_plat" => %w{languages ruby platform},
      }
    end
    let(:response) do
      {
        "rows" => [
          { "url" => "#{server_url}/my-name-is-node",
            "data" => {
              "env" => "elysium",
              "ruby_plat" => "nudibranch",
            },
          },
          { "url" => "#{server_url}/my-name-is-jonas",
            "data" => {
              "env" => "hades",
              "ruby_plat" => "i386-mingw32",
            },
          },
          { "url" => "#{server_url}/my-name-is-flipper",
            "data" => {
              "env" => "elysium",
              "ruby_plat" => "centos",
            },
          },
          { "url" => "#{server_url}/my-name-is-butters",
            "data" => {
              "env" => "moon",
              "ruby_plat" => "solaris2",
            },
          },
        ],
        "start" => 0,
        "total" => 4,
      }
    end
    let(:response_rows) do
      [
        { "env" => "elysium", "ruby_plat" => "nudibranch" },
        { "env" => "hades", "ruby_plat" => "i386-mingw32" },
        { "env" => "elysium", "ruby_plat" => "centos" },
        { "env" => "moon", "ruby_plat" => "solaris2" },
      ]
    end
  end

  before(:each) do
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow(rest).to receive(:get).and_return(response)
  end

  describe "search" do
    let(:query_string) { "search/node?q=platform:rhel&start=0" }
    let(:query_string_continue) { "search/node?q=platform:rhel&start=4" }
    let(:query_string_with_rows) { "search/node?q=platform:rhel&start=0&rows=4" }
    let(:query_string_continue_with_rows) { "search/node?q=platform:rhel&start=4&rows=4" }

    let(:response) do
      {
      "rows" => [
        { "name" => "my-name-is-node",
          "chef_environment" => "elysium",
          "platform" => "rhel",
          "run_list" => [],
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "nudibranch",
                "version" => "1.9.3",
                "target" => "ming-the-merciless",
              },
            },
          },
        },
        { "name" => "my-name-is-jonas",
          "chef_environment" => "hades",
          "platform" => "rhel",
          "run_list" => [],
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "i386-mingw32",
                "version" => "1.9.3",
                "target" => "bilbo",
              },
            },
          },
        },
        { "name" => "my-name-is-flipper",
          "chef_environment" => "elysium",
          "platform" => "rhel",
          "run_list" => [],
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "centos",
                "version" => "2.0.0",
                "target" => "uno",
              },
            },
          },
        },
        { "name" => "my-name-is-butters",
          "chef_environment" => "moon",
          "platform" => "rhel",
          "run_list" => [],
          "automatic" => {
            "languages" => {
              "ruby" => {
                "platform" => "solaris2",
                "version" => "2.1.2",
                "target" => "random",
              },
            },
          },
        },
      ],
      "start" => 0,
      "total" => 4,
    } end

    let(:big_response) do
      r = response.dup
      r["total"] = 8
      r
    end

    let(:big_response_empty) do
      {
        "start" => 0,
        "total" => 8,
        "rows" => [],
      }
    end

    let(:big_response_end) do
      r = response.dup
      r["start"] = 4
      r["total"] = 8
      r
    end

    it "accepts a type as the first argument" do
      expect { query.search("node") }.not_to raise_error
      expect { query.search(:node) }.not_to raise_error
      expect { query.search(Hash.new) }.to raise_error(Chef::Exceptions::InvalidSearchQuery, /(Hash)/)
    end

    it "queries for every object of a type by default" do
      expect(rest).to receive(:get).with("search/node?q=*:*&start=0").and_return(response)
      query.search(:node)
    end

    it "allows a custom query" do
      expect(rest).to receive(:get).with("search/node?q=platform:rhel&start=0").and_return(response)
      query.search(:node, "platform:rhel")
    end

    it "lets you set a starting object" do
      expect(rest).to receive(:get).with("search/node?q=platform:rhel&start=2").and_return(response)
      query.search(:node, "platform:rhel", start: 2)
    end

    it "lets you set how many rows to return" do
      expect(rest).to receive(:get).with("search/node?q=platform:rhel&start=0&rows=40").and_return(response)
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
      response["rows"].each { |r| expect(@call_me).to receive(:do).with(Chef::Node.from_hash(r)) }
      query.search(:node) { |r| @call_me.do(r) }
    end

    it "pages through the responses" do
      @call_me = double("blocky")
      response["rows"].each { |r| expect(@call_me).to receive(:do).with(Chef::Node.from_hash(r)) }
      query.search(:node, "*:*", start: 0, rows: 4) { |r| @call_me.do(r) }
    end

    it "sends multiple API requests when the server indicates there is more data" do
      expect(rest).to receive(:get).with(query_string).and_return(big_response)
      expect(rest).to receive(:get).with(query_string_continue).and_return(big_response_end)
      query.search(:node, "platform:rhel") do |r|
        nil
      end
    end

    it "paginates correctly in the face of filtered nodes" do
      expect(rest).to receive(:get).with(query_string_with_rows).and_return(big_response_empty)
      expect(rest).to receive(:get).with(query_string_continue_with_rows).and_return(big_response_end)
      query.search(:node, "platform:rhel", rows: 4) do |r|
        nil
      end
    end

    it "fuzzifies node searches when fuzz is set" do
      expect(rest).to receive(:get).with(
        "search/node?q=tags:*free.messi*%20OR%20roles:*free.messi*%20OR%20fqdn:*free.messi*%20OR%20addresses:*free.messi*%20OR%20policy_name:*free.messi*%20OR%20policy_group:*free.messi*&start=0"
      ).and_return(response)
      query.search(:node, "free.messi", fuzz: true)
    end

    it "does not fuzzify node searches when fuzz is not set" do
      expect(rest).to receive(:get).with(
        "search/node?q=free.messi&start=0"
      ).and_return(response)
      query.search(:node, "free.messi")
    end

    it "does not fuzzify client searches" do
      expect(rest).to receive(:get).with(
        "search/client?q=messi&start=0"
      ).and_return(response)
      query.search(:client, "messi", fuzz: true)
    end

    context "when :filter_result is provided as a result" do
      include_context "filtered search" do
        let(:filter_key) { :filter_result }

        before(:each) do
          expect(rest).to receive(:post).with(query_string, args[filter_key]).and_return(response)
        end

        it "returns start" do
          start = query.search(:node, "platform:rhel", args)[1]
          expect(start).to eq(response["start"])
        end

        it "returns total" do
          total = query.search(:node, "platform:rhel", args)[2]
          expect(total).to eq(response["total"])
        end

        it "returns rows with the filter applied" do
          filtered_rows = query.search(:node, "platform:rhel", args)[0]
          expect(filtered_rows).to match_array(response_rows)
        end

      end
    end
  end

end
