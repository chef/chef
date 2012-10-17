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
    @language.stub!(:node).and_return(@node)
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

    it "validates the name of the data bag you're trying to load an item from" do
      lambda {@language.data_bag_item(" %%^& ", "item_name")}.should raise_error(Chef::Exceptions::InvalidDataBagName)
    end

    it "validates the id of the data bag item you're trying to load" do
      lambda {@language.data_bag_item("bag_name", " 987 (*&()")}.should raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end

    it "validates that the id of the data bag item is not nil" do
      lambda {@language.data_bag_item("bag_name", nil)}.should raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end

  end

end

