#
# Author:: Seth Falcon (<seth@opscode.com>)
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
require 'chef/dsl/data_query'

class DataQueryDSLTester
  include Chef::DSL::DataQuery
end

describe Chef::DSL::DataQuery do
  before(:each) do
    @language = DataQueryDSLTester.new
    @node = Hash.new
    @language.stub(:node).and_return(@node)
  end

  shared_examples_for "a data bag item" do
    it "validates the name of the data bag you're trying to load an item from" do
      lambda { invalid_data_bag_name }.should raise_error(Chef::Exceptions::InvalidDataBagName)
    end

    it "validates the id of the data bag item you're trying to load" do
      lambda { invalid_data_bag_item_id }.should raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end

    it "validates that the id of the data bag item is not nil" do
      lambda { nil_data_bag_item_id }.should raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end
  end

  describe "when loading data bags and items" do
    it "lists the items in a data bag" do
      Chef::DataBag.should_receive(:load).with("bag_name").and_return("item_1" => "http://url_for/item_1", "item_2" => "http://url_for/item_2")
      @language.data_bag("bag_name").sort.should == %w[item_1 item_2]
    end

    it "validates the name of the data bag you're trying to load" do
      lambda {@language.data_bag("!# %^&& ")}.should raise_error(Chef::Exceptions::InvalidDataBagName)
    end

    it "fetches a data bag item" do
      @item = Chef::DataBagItem.new
      @item.data_bag("bag_name")
      @item.raw_data = {"id" => "item_name", "FUU" => "FUU"}
      Chef::DataBagItem.should_receive(:load).with("bag_name", "item_name").and_return(@item)
      @language.data_bag_item("bag_name", "item_name").should == @item
    end

    include_examples "a data bag item" do
      let(:invalid_data_bag_name) { @language.data_bag_item(" %%^& ", "item_name") }
      let(:invalid_data_bag_item_id) { @language.data_bag_item("bag_name", " 987 (*&()") }
      let(:nil_data_bag_item_id) { @language.data_bag_item("bag_name", nil) }
    end

  end

  describe "when loading an encrypted data bag item" do

    let(:encrypted_data_bag_item) { Chef::EncryptedDataBagItem.new(encoded_data, secret) }

    let(:plaintext_data) {{
        "id" => "item_name",
        "greeting" => "hello",
        "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true }}
    }}

    let(:secret) { "abc123SECRET" }

    let(:encoded_data) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(plaintext_data, secret) }

    include_examples "a data bag item" do
      let(:invalid_data_bag_name) { @language.encrypted_data_bag_item(" %%^& ", "item_name", secret) }
      let(:invalid_data_bag_item_id) { @language.encrypted_data_bag_item("bag_name", " 987 (*&()", secret) }
      let(:nil_data_bag_item_id) { @language.encrypted_data_bag_item("bag_name", nil, secret) }
    end

    it "fetches an encrypted data bag item" do
      Chef::EncryptedDataBagItem.should_receive(:load).with("bag_name", "item_name", secret).and_return(encrypted_data_bag_item)
      @language.encrypted_data_bag_item("bag_name", "item_name", secret).should == encrypted_data_bag_item
    end

    context "without a secret" do
      it "fetches an encrypted data bag item" do
        Chef::EncryptedDataBagItem.should_receive(:load).with("bag_name", "item_name", nil).and_return(encrypted_data_bag_item)
        @language.encrypted_data_bag_item("bag_name", "item_name").should == encrypted_data_bag_item
      end
    end
  end

end
