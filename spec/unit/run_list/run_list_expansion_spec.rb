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

describe Chef::RunList::RunListExpansion do
  before do
    @run_list = Chef::RunList.new
    @run_list << "recipe[lobster::mastercookbook@0.1.0]" << "role[rage]" << "recipe[fist@0.1]"
    @expansion = Chef::RunList::RunListExpansion.new("_default", @run_list.run_list_items)
  end

  describe "before expanding the run list" do
    it "has an array of run list items" do
      expect(@expansion.run_list_items).to eq(@run_list.run_list_items)
    end

    it "has default_attrs" do
      expect(@expansion.default_attrs).to eq(Mash.new)
    end

    it "has override attrs" do
      expect(@expansion.override_attrs).to eq(Mash.new)
    end

    it "it has an empty list of recipes" do
      expect(@expansion.recipes.size).to eq(0)
    end

    it "has not applied its roles" do
      expect(@expansion.applied_role?("rage")).to be_falsey
    end
  end

  describe "after applying a role with environment-specific run lists" do
    before do
      @rage_role = Chef::Role.new.tap do |r|
        r.name("rage")
        r.env_run_lists("_default" => [], "prod" => ["recipe[prod-only]"])
      end
      @expansion = Chef::RunList::RunListExpansion.new("prod", @run_list.run_list_items)
      expect(@expansion).to receive(:fetch_role).and_return(@rage_role)
      @expansion.expand
    end

    it "has the correct list of recipes for the given environment" do
      expect(@expansion.recipes).to eq(["lobster::mastercookbook", "prod-only", "fist"])
    end

  end

  describe "after applying a role" do
    before do
      allow(@expansion).to receive(:fetch_role).and_return(Chef::Role.new)
      @expansion.inflate_role("rage", "role[base]")
    end

    it "tracks the applied role" do
      expect(@expansion.applied_role?("rage")).to be_truthy
    end

    it "does not inflate the role again" do
      expect(@expansion.inflate_role("rage", "role[base]")).to be_falsey
    end
  end

  describe "after expanding a run list" do
    before do
      @first_role = Chef::Role.new
      @first_role.name("rage")
      @first_role.run_list("role[mollusk]")
      @first_role.default_attributes({ "foo" => "bar" })
      @first_role.override_attributes({ "baz" => "qux" })
      @second_role = Chef::Role.new
      @second_role.name("rage")
      @second_role.run_list("recipe[crabrevenge]")
      @second_role.default_attributes({ "foo" => "boo" })
      @second_role.override_attributes({ "baz" => "bux" })
      allow(@expansion).to receive(:fetch_role).and_return(@first_role, @second_role)
      @expansion.expand
      @json = '{"id":"_default","run_list":[{"type":"recipe","name":"lobster::mastercookbook","version":"0.1.0",'
              .concat(
'"skipped":false},{"type":"role","name":"rage","children":[{"type":"role","name":"mollusk","children":[],"missing":null,'
      .concat(
'"error":null,"skipped":null},{"type":"recipe","name":"crabrevenge","version":null,"skipped":false}],"missing":null,'
      .concat(
'"error":null,"skipped":null},{"type":"recipe","name":"fist","version":"0.1","skipped":false}]}')))

    end

    it "produces json tree upon tracing expansion" do
      json_run_list = @expansion.to_json
      expect(json_run_list).to eq(@json)
    end

    it "has the ordered list of recipes" do
      expect(@expansion.recipes).to eq(["lobster::mastercookbook", "crabrevenge", "fist"])
    end

    it "has the merged attributes from the roles with outer roles overriding inner" do
      expect(@expansion.default_attrs).to eq({ "foo" => "bar" })
      expect(@expansion.override_attrs).to eq({ "baz" => "qux" })
    end

    it "has the list of all roles applied" do
      # this is the correct order, but 1.8 hash order is not stable
      expect(@expansion.roles).to match_array(%w{rage mollusk})
    end

  end

  describe "after expanding a run list with a non existent role" do
    before do
      allow(@expansion).to receive(:fetch_role) { @expansion.role_not_found("crabrevenge", "role[base]") }
      @expansion.expand
    end

    it "is invalid" do
      expect(@expansion).to be_invalid
      expect(@expansion.errors?).to be_truthy # aliases
    end

    it "has a list of invalid role names" do
      expect(@expansion.errors).to include("crabrevenge")
    end

  end

end
