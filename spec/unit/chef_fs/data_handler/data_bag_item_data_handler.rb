#
# Author:: Sandra Tiffin (<sandi.tiffin@gmail.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "lib/chef/chef_fs/data_handler/data_bag_item_data_handler"

class TestDataBag < Mash
  attr_accessor :name

  def initialize(bag_name)
    @name = bag_name
  end
end

class TestDataBagItem < Mash
  attr_accessor :name, :parent

  def path_for_printing
    "/some/path"
  end

  def initialize(bag_name, item_name)
    @name = "#{item_name}.json"
    @parent = TestDataBag.new(bag_name)
  end
end

describe Chef::ChefFS::DataHandler::DataBagItemDataHandler do
  let(:handler) { described_class.new }

  describe "#verify_integrity" do
    context "json id does not match data bag item name" do
      let(:entry) { TestDataBagItem.new("luggage", "bag") }
      let(:object) do
        { "raw_data" => { "id" => "duffel" } }
      end
      it "rejects the data bag item name" do
        expect { |b| handler.verify_integrity(object, entry, &b) }.to yield_with_args
      end
    end

    context "using a reserved word for the data bag name" do
      %w{node role environment client}.each do |reserved_word|
        let(:entry) { TestDataBagItem.new(reserved_word, "bag") }
        let(:object) do
          { "raw_data" => { "id" => "bag" } }
        end
        it "rejects the data bag name '#{reserved_word}'" do
          expect { |b| handler.verify_integrity(object, entry, &b) }.to yield_with_args
        end
      end
    end

    context "using a reserved word as part of the data bag name" do
      %w{xnode rolex xenvironmentx xclientx}.each do |bag_name|
        let(:entry) { TestDataBagItem.new(bag_name.to_s, "bag") }
        let(:object) do
          { "raw_data" => { "id" => "bag" } }
        end
        it "allows the data bag name '#{bag_name}'" do
          expect(handler.verify_integrity(object, entry)).to be_nil
        end
      end
    end

  end
end
